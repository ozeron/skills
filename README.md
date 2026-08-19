# skills

Personal agent skills for Claude Code and Codex. Barebone scaffold, no skills yet.

Modeled after [mattpocock/skills](https://github.com/mattpocock/skills).

## Layout

- `skills/engineering/` — daily code work
- `skills/productivity/` — daily non-code workflow tools
- `skills/misc/` — kept around, not promoted
- `skills/in-progress/` — beta, not shipped in the plugin
- `skills/deprecated/` — no longer used

Each bucket has its own `README.md` listing its skills.

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
