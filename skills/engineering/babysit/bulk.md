# Bulk mode

For PRs with more threads than one context handles well (~20 to ~100). A Workflow fans out, so it needs the user's explicit opt-in; offer it and wait.

1. **Triage, in parallel, read-only.** One subagent per thread, or per small group touching the same code. Each returns a bucket (`fix`, `decline`, `question`, `needs-human`) and, for `fix`, a patch plan plus the test that proves it. Subagents make no GitHub writes and no pushes.
2. **Converge in the main loop.** Dedupe overlapping fixes, apply them test-first, commit, run the scope guard, push, and wait for green.
3. **Reply, in sequence.** Post each reply with `respond.sh`, one thread at a time, so GitHub writes stay ordered. `needs-human` and unanswerable `question` threads use `noresolve`.

List every thread the fan-out dropped or couldn't decide in the exit comment.
