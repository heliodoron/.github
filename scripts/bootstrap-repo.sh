#!/usr/bin/env bash
# bootstrap-repo.sh: create a Heliodoron repository from the template and
# apply the standard settings, then read every setting back.
#
# Usage:
#   bootstrap-repo.sh <slug> <public|private> <description> <topics-csv>
#
# Exit codes:
#   0  repository created, settings applied and read back
#   1  wrong arguments or a missing tool
#   2  the repository already exists
#   3  a GitHub API call failed or a read-back did not match
#
# Not covered: restricting issue creation to collaborators has no known REST
# field (checked in the sandbox on 2026-09-19). It is set in the web UI; this
# script prints a reminder and does not pretend to have set it.
set -euo pipefail

org="heliodoron"
template="heliodoron/template"
homepage="https://heliodoron.com"
clone_root="$HOME/orgs/heliodoron"

if [[ "$#" -ne 4 ]]; then
  echo "usage: bootstrap-repo.sh <slug> <public|private> <description> <topics-csv>" >&2
  exit 1
fi
slug="$1"; visibility="$2"; description="$3"; topics_csv="$4"

if [[ "$visibility" != "public" && "$visibility" != "private" ]]; then
  echo "visibility must be public or private, got: $visibility" >&2
  exit 1
fi
for tool in gh jq git; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 1; }
done
if gh api "repos/$org/$slug" >/dev/null 2>&1; then
  echo "repository already exists: $org/$slug" >&2
  exit 2
fi

echo "== create $org/$slug from $template ($visibility)"
gh repo create "$org/$slug" --template "$template" "--$visibility" --description "$description" || exit 3

echo "== merge settings, features, website, pull requests from collaborators only"
gh api -X PATCH "repos/$org/$slug" \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY \
  -F delete_branch_on_merge=true \
  -F has_wiki=false -F has_projects=false -F has_discussions=false \
  -f pull_request_creation_policy=collaborators_only \
  -f homepage="$homepage" >/dev/null || exit 3

echo "== Dependabot alerts and security updates"
# The organization default for new repositories did not reach a new private
# repository in the sandbox, so both are set here.
gh api -X PUT "repos/$org/$slug/vulnerability-alerts" >/dev/null || exit 3
gh api -X PUT "repos/$org/$slug/automated-security-fixes" >/dev/null || exit 3

echo "== topics"
jq -n --arg csv "$topics_csv" '{names: ($csv | split(",") | map(gsub("^\\s+|\\s+$"; "")))}' \
  | gh api -X PUT "repos/$org/$slug/topics" --input - >/dev/null || exit 3

if [[ "$visibility" == "public" ]]; then
  echo "== ruleset on main"
  # Status names are confirmed in the sandbox before first use.
  jq -n '{
    name: "main", target: "branch", enforcement: "active",
    conditions: {ref_name: {include: ["~DEFAULT_BRANCH"], exclude: []}},
    rules: [
      {type: "deletion"},
      {type: "non_fast_forward"},
      {type: "required_linear_history"},
      {type: "pull_request", parameters: {
        required_approving_review_count: 0,
        dismiss_stale_reviews_on_push: false,
        require_code_owner_review: false,
        require_last_push_approval: false,
        required_review_thread_resolution: false,
        allowed_merge_methods: ["squash"]}},
      {type: "required_status_checks", parameters: {
        strict_required_status_checks_policy: false,
        required_status_checks: [{context: "checks / checks"}, {context: "ci"}]}}
    ]}' | gh api -X POST "repos/$org/$slug/rulesets" --input - >/dev/null || exit 3

  echo "== secret scanning and push protection"
  # Not switched on by itself for a new public repository in this organization.
  jq -n '{security_and_analysis: {secret_scanning: {status: "enabled"}, secret_scanning_push_protection: {status: "enabled"}}}' \
    | gh api -X PATCH "repos/$org/$slug" --input - >/dev/null || exit 3

  echo "== private vulnerability reporting"
  gh api -X PUT "repos/$org/$slug/private-vulnerability-reporting" >/dev/null || exit 3

  echo "== CodeQL default setup"
  gh api -X PATCH "repos/$org/$slug/code-scanning/default-setup" -f state=configured >/dev/null || exit 3
fi

echo "== read back"
got="$(gh api "repos/$org/$slug" --jq '[.allow_squash_merge, .allow_merge_commit, .allow_rebase_merge, .squash_merge_commit_title, .squash_merge_commit_message, .delete_branch_on_merge, .has_wiki, .has_projects, .has_discussions, .pull_request_creation_policy, .homepage] | map(tostring) | join(" ")')" || exit 3
want="true false false PR_TITLE PR_BODY true false false false collaborators_only $homepage"
if [[ "$got" != "$want" ]]; then
  echo "settings read-back mismatch" >&2
  echo "  want: $want" >&2
  echo "  got:  $got" >&2
  exit 3
fi
gh api "repos/$org/$slug/topics" --jq '"topics: " + (.names | join(", "))' || exit 3
gh api "repos/$org/$slug/automated-security-fixes" --jq '"dependabot security updates: \(.enabled)"' || exit 3
if [[ "$visibility" == "public" ]]; then
  gh api "repos/$org/$slug" --jq '"secret scanning: \(.security_and_analysis.secret_scanning.status), push protection: \(.security_and_analysis.secret_scanning_push_protection.status)"' || exit 3
  gh api "repos/$org/$slug/rulesets" --jq '.[] | "ruleset: \(.name) \(.enforcement)"' || exit 3
  gh api "repos/$org/$slug/private-vulnerability-reporting" --jq '"private vulnerability reporting: \(.enabled)"' || exit 3
  gh api "repos/$org/$slug/code-scanning/default-setup" --jq '"codeql default setup: \(.state)"' || exit 3
fi

echo "== clone and turn the hooks on"
mkdir -p "$clone_root"
gh repo clone "$org/$slug" "$clone_root/$slug" || exit 3
git -C "$clone_root/$slug" config core.hooksPath .githooks

echo "== still to do by hand (web UI, Settings, General, Features, Issues)"
echo "   restrict issue creation to collaborators"
echo "done: $org/$slug"
