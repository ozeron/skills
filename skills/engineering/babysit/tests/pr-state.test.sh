#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../scripts/pr-state.sh"
FAILS=0

setup() {
  WORK="$(mktemp -d)"
  mkdir -p "$WORK/bin" "$WORK/fix" "$WORK/state" "$WORK/cwd"
  cat >"$WORK/bin/gh" <<'GH'
#!/usr/bin/env bash
F="$FAKE_FIX"
case "$1 $2" in
  "api user") cat "$F/user.json" ;;
  "repo view") echo "acme widgets" ;;
  "api graphql") cat "$F/threads.json" ;;
  "pr view") cat "$F/pr.json" ;;
  "pr checks")
    [[ -f "$F/checks.json" ]] || { echo "no checks reported" >&2; exit 1; }
    cat "$F/checks.json"; exit "${FAKE_CHECKS_EXIT:-0}" ;;
  *) echo "fake gh: unexpected $*" >&2; exit 99 ;;
esac
GH
  chmod +x "$WORK/bin/gh"
  echo '{"login":"me"}' >"$WORK/fix/user.json"
  threads 0
  pr '{}'
  checks '[{"name":"Test","bucket":"pass","link":"l1"}]'
}

pr() {
  jq -n --argjson o "$1" '{
    number: 7, url: "https://github.com/acme/widgets/pull/7", state: "OPEN",
    author: {login: "me"}, headRefName: "feat/x", baseRefName: "main",
    headRefOid: "abc123", mergeable: "MERGEABLE", mergeStateStatus: "CLEAN",
    isDraft: false, reviewDecision: "APPROVED",
    additions: 30, deletions: 10, files: [{path: "src/a.py"}, {path: "tests/test_a.py"}]
  } * $o' >"$WORK/fix/pr.json"
}

checks() { echo "$1" >"$WORK/fix/checks.json"; }

threads() {
  local n="$1"
  jq -n --argjson n "$n" '{data: {repository: {pullRequest: {reviewThreads: {
    pageInfo: {hasNextPage: false, endCursor: null},
    nodes: ([range(0; $n)] | map({id: "T\(.)", isResolved: false, isOutdated: false, path: "src/a.py", line: 1,
      comments: {nodes: [{databaseId: ., author: {login: "rev"}, createdAt: "2026-01-01T00:00:00Z", body: "fix", diffHunk: ""}]}}))
      + [{id: "R", isResolved: true, isOutdated: false, path: "x", line: 1,
          comments: {nodes: [{databaseId: 99, author: {login: "rev"}, createdAt: "2026-01-01T00:00:00Z", body: "done", diffHunk: ""}]}}]
  }}}}}' >"$WORK/fix/threads.json"
}

run() {
  OUT="$(cd "$WORK/cwd" && PATH="$WORK/bin:$PATH" FAKE_FIX="$WORK/fix" BABYSIT_STATE_DIR="$WORK/state" "$SCRIPT" "$@" 2>"$WORK/err")"
  STATUS=$?
}

expect() {
  local name="$1" filter="$2" want="$3" got
  got="$(jq -c "$filter" <<<"$OUT" 2>&1)"
  if [[ "$got" == "$want" ]]; then
    echo "ok   $name"
  else
    echo "FAIL $name: $filter = $got, want $want"
    [[ -s "$WORK/err" ]] && sed 's/^/     stderr: /' "$WORK/err"
    FAILS=$((FAILS + 1))
  fi
}

setup; run 7
[[ $STATUS == 0 ]] || { echo "FAIL exit $STATUS"; FAILS=$((FAILS + 1)); }
expect "green and clean is done" '.next' '"done"'
expect "own PR" '.mode' '"own"'
expect "head sha" '.head' '"abc123"'
expect "resolved threads ignored" '.threads' '0'

setup; pr '{"author":{"login":"someone"}}'; run 7
expect "other author is review mode" '.mode' '"review"'

setup; pr '{"mergeable":"CONFLICTING","mergeStateStatus":"DIRTY"}'
checks '[{"name":"Test","bucket":"fail","link":"l1"}]'; threads 2; run 7
expect "conflicts come first" '.next' '"conflicts"'

setup; checks '[{"name":"Test","bucket":"fail","link":"l1"},{"name":"Lint","bucket":"pass","link":"l2"}]'
FAKE_CHECKS_EXIT=1; export FAKE_CHECKS_EXIT; threads 2; run 7; unset FAKE_CHECKS_EXIT
expect "failing CI before threads" '.next' '"ci"'
expect "failing check listed with link" '.checks.failing' '[{"name":"Test","link":"l1"}]'
expect "passed count" '.checks.passed' '1'

setup; threads 3; run 7
expect "unresolved threads counted" '.threads' '3'
expect "threads next" '.next' '"threads"'

setup; pr '{"mergeStateStatus":"BEHIND"}'; run 7
expect "behind base asks for update" '.next' '"update"'

setup; checks '[{"name":"Test","bucket":"pending","link":"l1"},{"name":"CodeRabbit","bucket":"pending","link":""}]'
FAKE_CHECKS_EXIT=8; export FAKE_CHECKS_EXIT; run 7; unset FAKE_CHECKS_EXIT
expect "pending checks mean wait" '.next' '"wait"'
expect "pending names" '.checks.pending' '["Test","CodeRabbit"]'
expect "review bots pending" '.botsPending' '["CodeRabbit"]'

setup; rm "$WORK/fix/checks.json"; run 7
expect "no checks reported is not an error" '.checks' '{"failing":[],"pending":[],"passed":0}'

setup; pr '{"mergeable":"UNKNOWN","mergeStateStatus":"UNKNOWN"}'; run 7
expect "unknown mergeability means wait" '.next' '"wait"'

setup; pr '{"isDraft":true,"reviewDecision":"REVIEW_REQUIRED"}'; run 7
expect "own draft must be marked ready" '.next' '"ready"'
expect "draft flag" '.draft' 'true'
expect "review decision" '.review' '"REVIEW_REQUIRED"'

setup; pr '{"isDraft":true}'; threads 1; run 7
expect "threads before ready" '.next' '"threads"'

setup; pr '{"isDraft":true,"author":{"login":"someone"}}'; run 7
expect "someone else's draft is not ours to ready" '.next' '"done"'

setup; pr '{"state":"MERGED"}'; run 7
expect "merged PR" '.next' '"merged"'

setup; run 7; pr '{"additions":250,"deletions":10,"files":[{"path":"src/a.py"},{"path":"tests/test_a.py"},{"path":"infra/b.tf"}]}'; run 7
expect "scope keeps the first-run baseline" '.scope.start' '40'
expect "scope growth" '.scope.growth' '220'
expect "scope new files" '.scope.newFiles' '["infra/b.tf"]'
run 7 --rebaseline
expect "rebaseline resets growth" '.scope.growth' '0'

setup
git -C "$WORK/cwd" init -q -b main && git -C "$WORK/cwd" commit -q --allow-empty -m base
git -C "$WORK/cwd" update-ref refs/remotes/origin/main HEAD
git -C "$WORK/cwd" checkout -q -b feat/x
printf 'a\nb\nc\n' >"$WORK/cwd/new.txt"; git -C "$WORK/cwd" add new.txt; git -C "$WORK/cwd" commit -q -m local
run 7
expect "local branch sizes from local diff" '.scope.now' '3'
expect "local files" '.scope.files' '["new.txt"]'

if (( FAILS )); then echo "$FAILS failed"; exit 1; fi
echo "all passed"
