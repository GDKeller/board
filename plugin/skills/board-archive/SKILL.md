---
name: board-archive
description: "Moves completed board items (done tasks, done epics, processed notes/resources) to board/archive/ while preserving IDs and git history. Never archives ADRs. Activates when the user asks to archive, clean up, or tidy the board, or via '/board:board-archive'."
allowed-tools: Bash, Read, Glob, AskUserQuestion
---

# Board Archive

Move completed items from active directories to `board/archive/`. The system spec is bundled with the plugin at `${CLAUDE_PLUGIN_ROOT}/spec/board-system-spec.md`.

## Board Data

Pre-loaded board data:

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh" ./board --active 2>&1`

## Steps

1. Filter the board data above for items with terminal status (excluding archived items and ADRs):
   - Tasks with `status: done`
   - Epics with `status: done`
   - Notes with `status: processed`
   - Resources with `status: processed`
2. List all items found and ask the user to confirm which to archive
3. Move confirmed files using the archive script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/archive-batch.sh" ./board <file1> <file2> ...
```

This handles `git mv` (or plain `mv` outside git repos), skips ADRs automatically, and reports results.
4. Show a summary of what was moved

## Notes

- **Avoid redundant invocations** — if this skill was already invoked earlier in the session and the board has not been modified since, reuse the previous board data instead of invoking again
- Files keep their original filename and ID after archiving
- Archived items remain searchable via grep and git log
- Links from other docs (e.g., `blocked_by`, `parent`) still work since the ID is stable
- ADRs are NOT archived — they stay in `board/planning/` regardless of status since they are immutable historical records that should remain easily discoverable
