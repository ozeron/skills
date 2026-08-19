# skills

Personal agent skills for Claude Code and Codex.

Structure modeled after [mattpocock/skills](https://github.com/mattpocock/skills);
some skills below are copied from there too (MIT-licensed), noted per entry.

## Layout

- `skills/engineering/` — daily code work
- `skills/productivity/` — daily non-code workflow tools
- `skills/misc/` — kept around, not promoted
- `skills/in-progress/` — beta, not shipped in the plugin
- `skills/deprecated/` — no longer used

Each bucket has its own `README.md` listing its skills.

## Skills

- **[tdd](./skills/engineering/tdd/SKILL.md)** — test-driven red-green-refactor loop. From [mattpocock/skills](https://github.com/mattpocock/skills).
- **[code-review](./skills/engineering/code-review/SKILL.md)** — two-axis diff review (standards + spec) via parallel sub-agents. From [mattpocock/skills](https://github.com/mattpocock/skills).
- **[grilling](./skills/productivity/grilling/SKILL.md)** — interview the user until a plan's design tree is fully resolved. From [mattpocock/skills](https://github.com/mattpocock/skills).
- **[handoff](./skills/productivity/handoff/SKILL.md)** — compact the conversation into a handoff doc for the next agent. From [mattpocock/skills](https://github.com/mattpocock/skills).
- **[i-have-adhd](./skills/productivity/i-have-adhd/SKILL.md)** — shape output for a reader with ADHD.
- **[deslop](./skills/engineering/deslop/SKILL.md)** — remove AI-generated code slop from a diff.
- **[babysit](./skills/engineering/babysit/SKILL.md)** — keep a PR merge-ready: triage comments, resolve conflicts, fix CI, in a loop. Originally a Cursor built-in skill.

## Dual harness support

`AGENTS.md` is a symlink to `CLAUDE.md`, so Codex and Claude Code read the same
instructions from this repo.

Run `scripts/link-skills.sh` to symlink every skill in `skills/` into the local
directories each harness reads from:

- `~/.claude/skills` (Claude Code)
- `~/.agents/skills` (Codex and other Agent Skills-compatible harnesses)

`scripts/list-skills.sh` prints every skill currently in the repo.

## Install as a Claude Code plugin

Once this repo ships skills, add it as a marketplace:

```
/plugin marketplace add ozeron/skills
/plugin install ozeron-skills@ozeron
```

`.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` make this
repo its own single-plugin marketplace.
