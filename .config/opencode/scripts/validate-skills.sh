#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
count=0
for skill in "$root"/skills/*/SKILL.md; do
  [[ -f "$skill" ]] || continue
  grep -q '^---$' "$skill" || { echo "Missing frontmatter: $skill" >&2; exit 1; }
  grep -q '^name: ' "$skill" || { echo "Missing name: $skill" >&2; exit 1; }
  grep -q '^description: ' "$skill" || { echo "Missing description: $skill" >&2; exit 1; }
  ((count+=1))
done
[[ "$count" -gt 0 ]] || { echo 'No skills found' >&2; exit 1; }
echo "Validated $count skill metadata files (structural check only)"
