---
type: task
status: backlog
priority: 2
created: 2026-05-19
---

# TASK-0025: Add `bin/` directory so board scripts are invokable as bare commands

## Description

Claude Code plugins support a `bin/` directory whose contents are added to the Bash tool's `PATH` while the plugin is enabled (see https://code.claude.com/docs/en/plugins-reference#file-locations-reference). Today, every skill that runs a board script writes the full path:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh ./board --active
```

If we add a `bin/` directory with thin wrappers (or symlinks) to the scripts in `plugin/scripts/`, those calls collapse to:

```bash
board-scan ./board --active
```

This makes skill bodies dramatically more readable and reduces the surface area for path mistakes.

## Changes Required

1. Create `plugin/bin/` with executable wrappers (or symlinks) for each script currently in `plugin/scripts/`:
   - `board-scan` → `scripts/board-scan.sh`
   - `board-init` → `scripts/board-init.sh`
   - `board-lint` → `scripts/board-lint.sh`
   - `next-id` → `scripts/next-id.sh`
   - `validate-status` → `scripts/validate-status.sh`
   - `archive-batch` → `scripts/archive-batch.sh`
2. Decide between symlinks (simpler, but tricky on Windows and across plugin cache copies) and thin shell wrappers (e.g., `exec "$(dirname "$0")/../scripts/board-scan.sh" "$@"`). Verify symlink behavior in the plugin cache — the docs note symlinks within a plugin's own directory are preserved.
3. Update every skill body in `plugin/skills/*/SKILL.md` to use the bare command form instead of `bash ${CLAUDE_PLUGIN_ROOT}/scripts/...`.
4. Update `hooks/hooks.json` (SessionStart auto-lint) to use the bare command if appropriate.
5. Update example invocations in `.claude/CLAUDE.md` and `docs/implementation-guide.md`.
6. Verify the bare-command form works after plugin install (not just from the source directory) by testing in a clean project.

## Acceptance Criteria

- All skills invoke board scripts as bare commands (`board-scan`, `next-id`, etc.) with no `${CLAUDE_PLUGIN_ROOT}` path prefix
- `board-lint` still runs on session start via the hook
- Scripts behave identically whether invoked as `board-scan` or `bash plugin/scripts/board-scan.sh`
- Documentation reflects the new invocation style
