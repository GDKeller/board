---
id: NOTE-0006
title: Set up personal GitHub plugin marketplace for proper distribution
type: note
status: inbox
created: 2026-03-26
---

## Observation

BoardPM plugin is currently loaded via `--plugin-dir` CLI flag pointing at the repo. This works but means:

- Plugin files aren't cached in `~/.claude/plugins/cache/` like marketplace-installed plugins
- No automatic updates
- Requires the shell alias to be present on every machine
- The plugin doesn't appear in `installed_plugins.json`

## Possible Directions

- Create a personal GitHub repo as a plugin marketplace
- Register it as a custom marketplace in Claude Code
- Install BoardPM from it like any other plugin
- Would also serve as a home for other personal plugins
