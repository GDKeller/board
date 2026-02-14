---
name: board-archive
description: "This skill should be used when the user asks to 'archive done tasks', 'clean up the board', 'move completed items', 'tidy the docs', or any variant of archiving completed board items. Also triggered by '/board:archive'."
disable-model-invocation: true
---

# Board Archive

Move completed items from active directories to `board/archive/`. The system spec is at `board/reference/REFE-0001_board-system-spec.md`.

## Steps

1. Run the board scan script to get all items with their statuses in one call:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh
```

Filter for items with terminal status (excluding archived items and ADRs):
   - Tasks with `status: done`
   - Epics with `status: done`
   - Notes with `status: processed`
   - Resources with `status: processed`
2. List all items found and ask the user to confirm which to archive
3. Move confirmed files to `board/archive/` using `git mv` (preserves git history)
4. Show a summary of what was moved

## Notes

- Files keep their original filename and ID after archiving
- Archived items remain searchable via grep and git log
- Links from other docs (e.g., `blocked_by`, `parent`) still work since the ID is stable
- ADRs are NOT archived — they stay in `board/planning/` regardless of status since they are immutable historical records that should remain easily discoverable
