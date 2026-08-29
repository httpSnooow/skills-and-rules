"""
EXPLAIN ANALYZE output parser and performance diagnosis tool.

Usage:
    python scripts/explain-analyzer.py < explain_output.txt
    psql -c "EXPLAIN (ANALYZE, BUFFERS) <query>" | python scripts/explain-analyzer.py

Exit codes:
    0 — no critical issues found
    1 — critical issues detected (Seq Scan on large table, high cost)
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field


COST_WARNING_THRESHOLD = 5_000
COST_CRITICAL_THRESHOLD = 50_000
SEQ_SCAN_ROW_WARNING = 10_000


@dataclass
class Diagnosis:
    warnings: list[str] = field(default_factory=list)
    criticals: list[str] = field(default_factory=list)
    suggestions: list[str] = field(default_factory=list)


def parse_plan_nodes(lines: list[str]) -> list[dict]:
    nodes = []
    node_pattern = re.compile(
        r"(?P<indent>\s*)->\s*(?P<node_type>[\w ]+?)\s+on\s+(?P<table>\w+)"
        r".*?cost=(?P<cost_start>[\d.]+)\.\.(?P<cost_end>[\d.]+)"
        r"\s+rows=(?P<est_rows>\d+)"
        r"(?:.*?actual time=(?P<actual_start>[\d.]+)\.\.(?P<actual_end>[\d.]+)"
        r"\s+rows=(?P<actual_rows>\d+))?",
        re.IGNORECASE,
    )
    top_pattern = re.compile(
        r"(?P<node_type>[\w ]+?)\s+on\s+(?P<table>\w+)"
        r".*?cost=(?P<cost_start>[\d.]+)\.\.(?P<cost_end>[\d.]+)"
        r"\s+rows=(?P<est_rows>\d+)"
        r"(?:.*?actual time=(?P<actual_start>[\d.]+)\.\.(?P<actual_end>[\d.]+)"
        r"\s+rows=(?P<actual_rows>\d+))?",
        re.IGNORECASE,
    )

    for line in lines:
        match = node_pattern.search(line) or top_pattern.search(line)
        if not match:
            continue
        nodes.append({
            "node_type": match.group("node_type").strip(),
            "table": match.group("table").strip(),
            "cost_end": float(match.group("cost_end")),
            "est_rows": int(match.group("est_rows")),
            "actual_rows": int(match.group("actual_rows")) if match.group("actual_rows") else None,
            "actual_end_ms": float(match.group("actual_end")) if match.group("actual_end") else None,
        })
    return nodes


def parse_execution_time(lines: list[str]) -> float | None:
    for line in lines:
        match = re.search(r"Execution Time:\s*([\d.]+)\s*ms", line, re.IGNORECASE)
        if match:
            return float(match.group(1))
    return None


def parse_planning_time(lines: list[str]) -> float | None:
    for line in lines:
        match = re.search(r"Planning Time:\s*([\d.]+)\s*ms", line, re.IGNORECASE)
        if match:
            return float(match.group(1))
    return None


def detect_rows_removed(lines: list[str]) -> list[tuple[str, int]]:
    results = []
    current_table = None
    table_pattern = re.compile(r"(?:Seq Scan|Index Scan|Bitmap Heap Scan)\s+on\s+(\w+)", re.IGNORECASE)
    removed_pattern = re.compile(r"Rows Removed by Filter:\s*(\d+)", re.IGNORECASE)

    for line in lines:
        table_match = table_pattern.search(line)
        if table_match:
            current_table = table_match.group(1)
        removed_match = removed_pattern.search(line)
        if removed_match and current_table:
            results.append((current_table, int(removed_match.group(1))))

    return results


def analyze(lines: list[str]) -> Diagnosis:
    diag = Diagnosis()
    nodes = parse_plan_nodes(lines)
    execution_ms = parse_execution_time(lines)
    planning_ms = parse_planning_time(lines)
    rows_removed = detect_rows_removed(lines)

    if execution_ms is not None:
        if execution_ms > 1_000:
            diag.criticals.append(
                f"Execution time {execution_ms:.1f}ms exceeds 1s — unacceptable for a synchronous web request."
            )
        elif execution_ms > 200:
            diag.warnings.append(
                f"Execution time {execution_ms:.1f}ms is above the 200ms target for web APIs."
            )

    if planning_ms is not None and planning_ms > 50:
        diag.warnings.append(
            f"Planning time {planning_ms:.1f}ms is high. Consider prepared statements to cache the query plan."
        )
        diag.suggestions.append(
            "Use prepared statements (parameterized queries via $1/$2 placeholders) to reuse query plans."
        )

    for node in nodes:
        node_type = node["node_type"].lower()
        table = node["table"]
        cost_end = node["cost_end"]
        est_rows = node["est_rows"]
        actual_rows = node["actual_rows"]

        if "seq scan" in node_type:
            if est_rows >= SEQ_SCAN_ROW_WARNING:
                diag.criticals.append(
                    f"Seq Scan on `{table}` with ~{est_rows:,} estimated rows. "
                    f"Missing index on the WHERE/JOIN column(s)."
                )
                diag.suggestions.append(
                    f"Add an index on the column(s) used in WHERE/JOIN for `{table}`:\n"
                    f"  CREATE INDEX CONCURRENTLY idx_{table}_<column> ON {table}(<column>);\n"
                    f"  Run EXPLAIN ANALYZE again to confirm index is used."
                )
            else:
                diag.warnings.append(
                    f"Seq Scan on `{table}` ({est_rows:,} rows) — acceptable at this volume, "
                    f"but watch as the table grows."
                )

        if cost_end >= COST_CRITICAL_THRESHOLD:
            diag.criticals.append(
                f"Node cost {cost_end:,.0f} on `{table}` is critically high. "
                f"Review indexes, JOINs, and data volume."
            )
        elif cost_end >= COST_WARNING_THRESHOLD:
            diag.warnings.append(
                f"Node cost {cost_end:,.0f} on `{table}` warrants attention."
            )

        if actual_rows is not None and est_rows > 0:
            ratio = actual_rows / est_rows
            if ratio > 10 or ratio < 0.1:
                diag.warnings.append(
                    f"Statistics mismatch on `{table}`: planner estimated {est_rows:,} rows, "
                    f"actual was {actual_rows:,}. Run `ANALYZE {table};` to update statistics."
                )
                diag.suggestions.append(f"ANALYZE {table};")

        if "nested loop" in node_type and est_rows > 10_000:
            diag.warnings.append(
                f"Nested Loop on `{table}` with {est_rows:,} rows may degrade to O(n²). "
                f"Consider a Hash Join or an index on the inner join column."
            )

    for table, removed in rows_removed:
        if removed > 50_000:
            diag.criticals.append(
                f"`{table}`: {removed:,} rows removed by filter. "
                f"A partial index on the filter condition would dramatically reduce this."
            )
            diag.suggestions.append(
                f"Consider a partial index: CREATE INDEX CONCURRENTLY ON {table}(<filter_col>) WHERE <condition>;"
            )
        elif removed > 5_000:
            diag.warnings.append(
                f"`{table}`: {removed:,} rows removed by filter — index or partial index may help."
            )

    return diag


def format_output(diag: Diagnosis) -> str:
    lines = []

    if not diag.criticals and not diag.warnings:
        lines.append("✅  No critical performance issues detected.")
        if diag.suggestions:
            lines.append("\nSuggestions:")
            for s in diag.suggestions:
                lines.append(f"  • {s}")
        return "\n".join(lines)

    if diag.criticals:
        lines.append("🔴  CRITICAL issues:\n")
        for issue in diag.criticals:
            lines.append(f"  • {issue}")

    if diag.warnings:
        lines.append("\n🟡  Warnings:\n")
        for issue in diag.warnings:
            lines.append(f"  • {issue}")

    if diag.suggestions:
        lines.append("\n💡  Suggestions:\n")
        for s in diag.suggestions:
            lines.append(f"  • {s}")

    return "\n".join(lines)


def main() -> int:
    content = sys.stdin.read()
    if not content.strip():
        print("Error: no EXPLAIN ANALYZE output provided via stdin.", file=sys.stderr)
        print("Usage: python scripts/explain-analyzer.py < explain_output.txt", file=sys.stderr)
        return 2

    lines = content.splitlines()
    diag = analyze(lines)
    print(format_output(diag))

    return 1 if diag.criticals else 0


if __name__ == "__main__":
    sys.exit(main())
