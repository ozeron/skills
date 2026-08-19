# Skills

Skills are organized into bucket folders under `skills/`:

- `engineering/`: daily code work
- `productivity/`: daily non-code workflow tools
- `misc/`: kept around but rarely used, not promoted
- `in-progress/`: beta: public on purpose, feedback wanted, not shipped in the plugin
- `deprecated/`: no longer used

Every skill in `engineering/` or `productivity/` (the promoted buckets) must have an
entry in the top-level `README.md` and in `.claude-plugin/plugin.json`'s `skills`
array (the Claude Code plugin ships exactly the promoted set). Skills in `misc/`,
`in-progress/`, and `deprecated/` must not appear in either.

`.claude-plugin/marketplace.json` makes this repo its own single-plugin marketplace.
Run `claude plugin validate . --strict` after touching either manifest.

Each bucket folder has a `README.md` that lists every skill in the bucket with a
one-line description, linking the skill name to its `SKILL.md`.

To (re)link every skill into the local harness skill directories
(`~/.claude/skills`, `~/.agents/skills`), run `scripts/link-skills.sh`. Each entry
is a symlink into this repo, so a `git pull` keeps installed skills current;
re-run the script after adding, removing, or renaming a skill.

`AGENTS.md` is a symlink to this file, so Codex and Claude Code read the same
instructions.
