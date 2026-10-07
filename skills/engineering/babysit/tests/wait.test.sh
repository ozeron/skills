#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
mkdir -p "$WORK/bin" "$WORK/skill/scripts"
command cp -f "$HERE/../scripts/wait.sh" "$WORK/skill/scripts/"
cat >"$WORK/skill/scripts/pr-state.sh" <<'S'
#!/usr/bin/env bash
echo x >>"$FAKE_LOG.state"
next=done; (( $(grep -c x "$FAKE_LOG.state") < 3 )) && next=wait
echo "{\"next\":\"$next\",\"head\":\"abc\",\"checks\":{\"failing\":[],\"pending\":[]},\"botsPending\":[],\"threads\":0,\"scope\":{\"growth\":0},\"pr\":$1}"
S
cat >"$WORK/bin/gh" <<'GH'
#!/usr/bin/env bash
echo "$*" >>"$FAKE_LOG"
case "$*" in
  *--watch*) exit 0 ;;
  "pr checks"*)
    n=$(grep -c '^pr checks.*--json' "$FAKE_LOG")
    if (( n < 3 )); then echo "no checks reported" >&2; exit 1; fi
    echo 2 ;;
esac
GH
chmod +x "$WORK/bin/gh" "$WORK/skill/scripts/pr-state.sh"

# shellcheck disable=SC2034
OUT="$(PATH="$WORK/bin:$PATH" FAKE_LOG="$WORK/log" BABYSIT_POLL=0 "$WORK/skill/scripts/wait.sh" 7)"
FAILS=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; FAILS=$((FAILS + 1)); fi; }
check "retries until checks register" '[[ $(grep -c "^pr checks 7 --json" "$WORK/log") == 3 ]]'
check "then watches with fail-fast" 'grep -q "^pr checks 7 --watch --fail-fast" "$WORK/log"'
check "re-polls while next is wait" '[[ $(grep -c x "$WORK/log.state") == 3 ]]'
check "prints one compact state line" '[[ $(grep -c "" <<<"$OUT") == 1 ]] && jq -e ".next == \"done\" and .pr == 7" <<<"$OUT" >/dev/null'
(( FAILS )) && { cat "$WORK/log"; echo "$FAILS failed"; exit 1; }
echo "all passed"
