#!/usr/bin/env bash
set -euo pipefail
# Requires: bash, awk, sed, tr. No python3.
# Works on Linux/macOS and Git Bash / WSL.

ROOT="${PWD}"
FEATURES_DIR="${ROOT}/.ai/features"
ACTIVE_RELS=()
CONTEXT_LINES=("Active local AI features (read and obey Scope/Oracles before coding):")

json_escape() {
  printf '%s' "$1" | awk '
    BEGIN { ORS="" }
    {
      gsub(/\\/, "\\\\")
      gsub(/"/, "\\\"")
      gsub(/\t/, "\\t")
      gsub(/\r/, "")
      print
    }
  '
}

if [[ -d "${FEATURES_DIR}" ]]; then
  shopt -s nullglob
  for f in "${FEATURES_DIR}"/*.md; do
    base="$(basename "$f")"
    [[ "${base}" == "_template.md" ]] && continue
    if ! awk '
      /^#{1,2}[[:space:]]*Status[[:space:]]*$/ {
        getline
        gsub(/[[:space:]]/, "")
        if (tolower($0) == "active") exit 0
        exit 1
      }
      END { exit 1 }
    ' "$f"; then
      continue
    fi
    name="${base%.md}"
    nline="$(awk '/^#{1,2}[[:space:]]*Name[[:space:]]*$/{getline; gsub(/^[[:space:]]+|[[:space:]]+$/,""); print; exit}' "$f")"
    iline="$(awk '/^#{1,2}[[:space:]]*Intent[[:space:]]*$/{getline; gsub(/^[[:space:]]+|[[:space:]]+$/,""); print; exit}' "$f")"
    [[ -n "${nline}" ]] && name="${nline}"
    rel=".ai/features/${base}"
    ACTIVE_RELS+=("${rel}")
    line="- ${rel}: ${name}"
    [[ -n "${iline}" ]] && line="${line} - ${iline}"
    CONTEXT_LINES+=("${line}")
  done
fi

if [[ ${#ACTIVE_RELS[@]} -eq 0 ]]; then
  printf '%s' '{"env":{"ACTIVE_AI_FEATURES":""},"additional_context":""}'
  exit 0
fi

joined="$(IFS=';'; echo "${ACTIVE_RELS[*]}")"
ctx=""
for line in "${CONTEXT_LINES[@]}"; do
  if [[ -z "${ctx}" ]]; then
    ctx="${line}"
  else
    ctx="${ctx}\n${line}"
  fi
done

ctx_esc="$(json_escape "$(printf '%b' "${ctx}")")"
feat_esc="$(json_escape "${joined}")"
printf '{"env":{"ACTIVE_AI_FEATURES":"%s"},"additional_context":"%s"}' "${feat_esc}" "${ctx_esc}"
exit 0
