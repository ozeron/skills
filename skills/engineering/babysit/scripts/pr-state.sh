#!/usr/bin/env bash
# One JSON snapshot of what stands between a PR and merge, plus the next blocker.
#
# Usage: pr-state.sh [PR] [--rebaseline]
#
# Output:
#   { pr, url, head, branch, base, state, mode: own|review,
#     mergeable, mergeState,
#     checks: {failing: [{name, link}], pending: [name], passed: n},
#     botsPending: [name], threads: n,
#     scope: {start, now, growth, files, newFiles},
#     next: merged|closed|conflicts|ci|threads|update|wait|done }
#
# `next` is the first blocker in babysit order. `scope` compares the diff size
# (additions + deletions) with the first snapshot of this PR; the baseline lives
# in $BABYSIT_STATE_DIR and resets with --rebaseline. When the checkout is on the
# PR branch, sizes come from the local diff so unpushed commits count.
#
# BABYSIT_BOTS: regex of check names that are review bots.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PR=""; REBASELINE=0
for arg in "$@"; do
  case "$arg" in
    --rebaseline) REBASELINE=1 ;;
    *) PR="$arg" ;;
  esac
done

pr_json="$(gh pr view ${PR:+"$PR"} --json number,url,state,author,headRefName,baseRefName,headRefOid,mergeable,mergeStateStatus,additions,deletions,files)"
PR="$(jq -r .number <<<"$pr_json")"
me="$(gh api user | jq -r .login)"

checks_json="$(gh pr checks "$PR" --json name,bucket,link 2>/dev/null || true)"
jq -e 'type == "array"' <<<"$checks_json" >/dev/null 2>&1 || checks_json="[]"

threads="$("$HERE/fetch-threads.sh" "$PR" | jq length)"

branch="$(jq -r .headRefName <<<"$pr_json")"
base="$(jq -r .baseRefName <<<"$pr_json")"
if [[ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)" == "$branch" ]] \
  && numstat="$(git diff --numstat "origin/$base...HEAD" 2>/dev/null)"; then
  size="$(jq -Rn --arg s "$numstat" '
    [$s | split("\n")[] | select(length > 0) | split("\t")]
    | {lines: (map((.[0] | tonumber? // 0) + (.[1] | tonumber? // 0)) | add // 0),
       files: map(.[2])}')"
else
  size="$(jq '{lines: (.additions + .deletions), files: [.files[].path]}' <<<"$pr_json")"
fi

state_dir="${BABYSIT_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/babysit}"
key="$(jq -r '.url | sub("^https://github.com/"; "") | gsub("/"; "_")' <<<"$pr_json")"
baseline_file="$state_dir/$key.json"
mkdir -p "$state_dir"
if (( REBASELINE )) || [[ ! -s "$baseline_file" ]]; then
  echo "$size" >|"$baseline_file"
fi

jq -n \
  --argjson pr "$pr_json" \
  --argjson checks "$checks_json" \
  --argjson threads "$threads" \
  --argjson size "$size" \
  --argjson baseline "$(cat "$baseline_file")" \
  --arg me "$me" \
  --arg bots "${BABYSIT_BOTS:-coderabbit|bugbot|cursor|agent.?review|pullfrog|claude|codex|copilot|greptile}" '
  ($checks | map(select(.bucket == "fail" or .bucket == "cancel")) | map({name, link})) as $failing
  | ($checks | map(select(.bucket == "pending") | .name)) as $pending
  | ($pending | map(select(test($bots; "i")))) as $botsPending
  | {
      pr: $pr.number, url: $pr.url, head: $pr.headRefOid,
      branch: $pr.headRefName, base: $pr.baseRefName, state: $pr.state,
      mode: (if $pr.author.login == $me then "own" else "review" end),
      mergeable: $pr.mergeable, mergeState: $pr.mergeStateStatus,
      checks: {failing: $failing, pending: $pending,
               passed: ($checks | map(select(.bucket == "pass")) | length)},
      botsPending: $botsPending,
      threads: $threads,
      scope: {start: $baseline.lines, now: $size.lines,
              growth: ($size.lines - $baseline.lines),
              files: $size.files, newFiles: ($size.files - $baseline.files)},
      next: (
        if $pr.state == "MERGED" then "merged"
        elif $pr.state == "CLOSED" then "closed"
        elif $pr.mergeable == "CONFLICTING" then "conflicts"
        elif ($failing | length) > 0 then "ci"
        elif $threads > 0 then "threads"
        elif $pr.mergeStateStatus == "BEHIND" then "update"
        elif ($pending | length) > 0 or $pr.mergeable == "UNKNOWN" then "wait"
        else "done" end)
    }'
