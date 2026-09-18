#!/usr/bin/env bash
# clean-copy-gate.sh: the local gate that runs before every pull request in a
# repository rebuilt from private sources. It reports findings; a human reads
# them. It never runs in public CI because the deny list is private.
#
# Usage:
#   clean-copy-gate.sh <repo-dir> <deny-list.json> <rename-map.txt>
#
#   deny-list.json  {"exact": [...], "any_case": [...]} names that must never appear
#   rename-map.txt  one old product name per line that must no longer appear
#
# Exit codes:
#   0  no findings
#   1  wrong arguments or a missing tool or file
#   2  findings (listed above the final line)
set -euo pipefail

if [[ "$#" -ne 3 ]]; then
  echo "usage: clean-copy-gate.sh <repo-dir> <deny-list.json> <rename-map.txt>" >&2
  exit 1
fi
repo="$1"; deny="$2"; renames="$3"
for tool in git jq gitleaks; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 1; }
done
[[ -d "$repo/.git" ]] || { echo "not a git repository: $repo" >&2; exit 1; }
[[ -f "$deny" ]] || { echo "deny list not found: $deny" >&2; exit 1; }
[[ -f "$renames" ]] || { echo "rename map not found: $renames" >&2; exit 1; }

cd "$repo"
findings=0

# Searches tracked files with git grep. Exit codes: 0 match, 1 none, more is an error.
scan() {
  local label="$1"; shift
  local rc=0
  git grep -nI "$@" || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    echo "^^ $label" >&2
    findings=1
  elif [[ "$rc" -ne 1 ]]; then
    echo "scan failed ($label) with exit code $rc" >&2
    exit 1
  fi
}

echo "== secrets (gitleaks, working tree)"
if ! gitleaks dir --no-banner --redact .; then
  echo "^^ gitleaks findings" >&2
  findings=1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
jq -r '.exact[]' "$deny" > "$tmp/exact"
jq -r '.any_case[]' "$deny" > "$tmp/any_case"
grep -v '^[[:space:]]*$' "$renames" > "$tmp/renames" || true   # an empty rename map is valid

echo "== deny list, exact case, whole word"
[[ -s "$tmp/exact" ]] && scan "deny list (exact case)" -w -F -f "$tmp/exact"

echo "== deny list, any case, whole word"
[[ -s "$tmp/any_case" ]] && scan "deny list (any case)" -w -i -F -f "$tmp/any_case"

echo "== old product names"
[[ -s "$tmp/renames" ]] && scan "old product name" -i -F -f "$tmp/renames"

echo "== cloud identifiers"
scan "AWS account id in an ARN or registry host" -E -e 'arn:aws[a-z-]*:[^:]*:[^:]*:[0-9]{12}' -e '[0-9]{12}\.dkr\.ecr\.'
scan "Azure subscription id" -i -E -e '/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' -e 'subscription[_ -]?id["'"'"' :=]+[0-9a-f]{8}-[0-9a-f]{4}'
scan "GCP project or service account" -E -e 'projects/[a-z][a-z0-9-]{4,28}[a-z0-9]' -e '[a-z0-9-]+@[a-z0-9-]+\.iam\.gserviceaccount\.com'

echo "== local paths"
# shellcheck disable=SC1003 # the backslashes are a regex for a literal Windows users path, not a quote escape
scan "local home path" -E -e '/home/[a-z][a-z0-9_-]+/' -e '/Users/[A-Za-z][A-Za-z0-9_-]+/' -e 'C:\\Users\\'

echo "== email addresses other than the org contact and GitHub noreply"
scan "email address" -P -e '[A-Za-z0-9._%+-]+@(?!heliodoron\.com\b|users\.noreply\.github\.com\b|github\.com\b|example\.(com|org)\b)[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

echo "== files that are never copied"
while IFS= read -r -d '' f; do
  case "${f##*/}" in
    CLAUDE.md|AGENTS.md|TRACKER.md|NEXT_STEPS.md)
      echo "never copied: $f" >&2; findings=1 ;;
  esac
done < <(git ls-files -z)

if [[ "$findings" -ne 0 ]]; then
  echo "clean-copy gate: findings above, review each before opening the pull request" >&2
  exit 2
fi
echo "clean-copy gate: no findings"
