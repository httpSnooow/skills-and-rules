#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if [[ ! -d "${ROOT}/.ai" && -d "$(pwd)/.ai" ]]; then
  ROOT="$(pwd)"
fi
cd "${ROOT}"

failed=0

require() {
  if [[ ! -e "$1" ]]; then
    echo "MISSING: $1"
    failed=1
  else
    echo "OK: $1"
  fi
}

require '.cursorignore'
require '.ai/context.md'
require '.ai/agents.md'
require '.ai/README.md'
require '.ai/features/_template.md'
require '.ai/features/README.md'
require '.ai/features/_done/README.md'
require '.ai/playbooks/feature-cycle.md'
require '.cursor/rules/00-architecture.mdc'

layer_count="$(find .ai/layers -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${layer_count}" -lt 1 ]]; then
  echo 'MISSING: .ai/layers/*.md'
  failed=1
else
  echo "OK: ${layer_count} layer file(s)"
fi

mdc_count="$(find .cursor/rules -maxdepth 1 -type f -name '*.mdc' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${mdc_count}" -lt 2 ]]; then
  echo 'MISSING: expected always-apply + at least one layer mdc'
  failed=1
else
  echo "OK: ${mdc_count} mdc file(s)"
fi

if ! grep -qE 'alwaysApply:[[:space:]]*true' .cursor/rules/00-architecture.mdc 2>/dev/null; then
  echo 'BAD: 00-architecture.mdc must have alwaysApply: true'
  failed=1
else
  echo 'OK: alwaysApply architecture rule'
fi

ci_ok=1
if [[ ! -f .cursorignore ]]; then
  echo 'MISSING: .cursorignore content'
  failed=1
  ci_ok=0
else
  grep -qE '\.env' .cursorignore || { echo 'WEAK cursorignore: missing .env'; failed=1; ci_ok=0; }
  grep -qE 'node_modules' .cursorignore || { echo 'WEAK cursorignore: missing node_modules'; failed=1; ci_ok=0; }
  grep -qE '\.pem|\.key' .cursorignore || { echo 'WEAK cursorignore: missing .pem/.key'; failed=1; ci_ok=0; }
  [[ "${ci_ok}" -eq 1 ]] && echo 'OK: cursorignore minimum patterns'
fi

assert_clean_repo() {
  local repo="$1"
  [[ -d "${repo}/.git" ]] || { echo "SKIP git: ${repo} (no .git)"; return; }
  local hits
  hits="$(cd "${repo}" && git status --short | grep -E '\.ai(/|\\)|\.cursor(/|\\)(rules|hooks)|\.cursorignore' || true)"
  if [[ -n "${hits}" ]]; then
    echo "LEAK in ${repo}:"
    echo "${hits}"
    failed=1
  else
    echo "OK git isolation: ${repo}"
  fi
}

[[ -d .git ]] && assert_clean_repo .
for d in */; do
  [[ -d "${d}.git" ]] && assert_clean_repo "${d%/}"
done

has_hook=0
[[ -f .cursor/hooks/inject-active-features.sh || -f .cursor/hooks/inject-active-features.ps1 ]] && has_hook=1
if [[ "${has_hook}" -eq 1 ]]; then
  if [[ ! -f .cursor/hooks.json ]]; then
    echo 'MISSING: .cursor/hooks.json (inject script present)'
    failed=1
  else
    echo 'OK: hooks.json present with inject script'
  fi
fi

if [[ -f .cursor/hooks/inject-active-features.sh ]]; then
  echo '--- hook smoke (sh) ---'
  out="$(bash .cursor/hooks/inject-active-features.sh)"
  if printf '%s' "${out}" | grep -q '"ACTIVE_AI_FEATURES"' && printf '%s' "${out}" | grep -q '"additional_context"'; then
    echo 'OK: hook returns JSON-like payload'
  else
    echo "BAD hook JSON: ${out}"
    failed=1
  fi
elif [[ -f .cursor/hooks/inject-active-features.ps1 ]]; then
  echo 'SKIP hook JSON smoke on Unix for .ps1'
else
  echo 'SKIP hook (not installed)'
fi

if [[ "${failed}" -ne 0 ]]; then
  echo 'VERIFY FAILED'
  exit 1
fi
echo 'VERIFY PASSED'
exit 0
