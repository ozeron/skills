---
name: babysit
description: >-
  Babysit a PR to merge-ready. Use when asked to babysit, ship, or land a PR,
  get its CI green, address or resolve review comments, or fix its merge
  conflicts.
---
# Babysit PR

Drive the PR to **merge-ready**: checks green, mergeable, zero unresolved threads. Each pass clears one blocker with the smallest fix, then waits.

`S=~/.claude/skills/babysit/scripts`. `$S/pr-state.sh <pr>` prints one JSON snapshot; `.next` names the blocker.

## Mode

`.mode` from the first snapshot decides what you may write:

- `own`: commit fixes, push, reply and resolve threads.
- `review` (someone else's PR): GitHub comments only. Threaded replies plus one `gh pr comment` with findings; threads stay open for the author.

History is append-only: commit on top and merge the base in.

## Loop

Snapshot, act on `.next`, repeat:

| `.next` | Action |
| --- | --- |
| `conflicts` | `git merge origin/<base>`; resolve keeping both sides' intent. Intents clash → `git merge --abort` and ask. |
| `ci` | Per `.checks.failing`: `gh run view <run> --log-failed`. Caused by this PR → smallest fix, narrowest test first. Otherwise merge the base in once; still red → report it as out of scope. CI config stays as is. |
| `threads` | [Threads](#threads). |
| `update` | Merge the base in. |
| `wait` | [Wait](#wait). |
| `done` | [Exit](#exit). |
| `merged`, `closed` | Report and stop. |

A pass ends on a push followed by a wait, or on `done`.

## Threads

`$S/fetch-threads.sh <pr>` lists unresolved threads; read each body, path and line, nothing else. Check every bot finding against the code before acting on it.

Close each thread once its fix is pushed, or once you decline it with a reason:
`$S/respond.sh <pr> <rootCommentId> <threadId> resolve "<what changed> (<sha>)"`

Use `noresolve` and ask when it needs a product call, the code can't answer it, or the fix couldn't be verified. Review mode always uses `noresolve`. Over ~20 threads, offer [bulk mode](bulk.md).

## Scope guard

Before every push, snapshot and read `.scope` (it counts unpushed commits). `growth` over ~200 lines, or `newFiles` outside the PR's area → stop and ask. Once the user approves, `$S/pr-state.sh <pr> --rebaseline`.

## Wait

Start `$S/wait.sh <pr>` with the Monitor tool (`timeout_ms: 1800000`; re-arm on expiry). It waits for checks to register and settle, then prints one snapshot line. Every wait goes through it.

`done` also needs the review bots' pass on the latest head: `botsPending` empty and their new threads handled.

## Exit

- **Done**: one `gh pr comment` mapping each handled thread to its fixing SHA or decline reason, plus the head SHA and `threads: 0`. Then PushNotification: `PR #<n> merge-ready at <sha>`.
- **Blocked**: PushNotification with the one question, then stop.

## Friction

When this skill, a script, or a repo doc misleads you, append to `~/.agent-feedback/<repo>/<branch with / as _>.md` (the repo's AGENTS.md "Feedback scratchpad" format if present): `### <date> · <what> · blocked|slowed|wrong`, then `Hit:`, `Workaround:`, `Fix:`.
