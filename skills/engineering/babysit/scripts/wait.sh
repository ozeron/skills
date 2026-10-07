#!/usr/bin/env bash
# Block until a PR's checks register and settle and mergeability is known,
# then print one compact pr-state line.
#
# Usage: wait.sh [PR]   (run through Monitor or a background shell)
#
# BABYSIT_POLL: seconds between polls (default 30).
# BABYSIT_GRACE: seconds to let new checks (review bots) register after a push or
# ready-for-review before trusting a settled snapshot (default 60).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PR="${1:-$(gh pr view --json number -q .number)}"
POLL="${BABYSIT_POLL:-30}"

for _ in $(seq 1 20); do
  gh pr checks "$PR" --json name -q length 2>/dev/null | grep -qv '^0$' && break
  sleep "$POLL"
done
sleep "${BABYSIT_GRACE:-60}"
for _ in $(seq 1 20); do
  gh pr checks "$PR" --watch --fail-fast --interval "${POLL/#0/1}" >/dev/null 2>&1
  state="$("$HERE/pr-state.sh" "$PR")"
  [[ "$(jq -r .next <<<"$state")" == wait ]] || break
  sleep "$POLL"
done
jq -c '{pr, next, head, draft, review, failing: .checks.failing, pending: .checks.pending, botsPending, threads, growth: .scope.growth}' <<<"$state"
