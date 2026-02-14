---
name: board-archive
description: "This skill should be used when the user asks to 'archive done tasks', 'clean up the board', 'move completed items', 'tidy the docs', or any variant of archiving completed board items. Also triggered by '/board:archive'."
disable-model-invocation: true
---

# Board Archive

Move completed items from active directories to `board/archive/`. The system spec is at `board/reference/REFE-0001_board-system-spec.md`.

## Steps

### 1. Find Completed Items

Scan all board files to identify items with terminal statuses:

1. Use Glob to find all `.md` files in `board/tasks/`, `board/planning/`, `board/resources/`
2. For each file, use Read with `limit: 10` to extract `type` and `status` from frontmatter
3. Filter for items with terminal status:
   - Tasks with `status: done`
   - Epics with `status: done`
   - Notes with `status: processed`
   - Resources with `status: processed`

**Important**: ADRs are NEVER archived — they stay in `board/planning/` permanently regardless of status.

### 2. Confirm with User

List all items found and ask the user to confirm which to archive.

### 3. Move Files

For each confirmed file, use `git mv` (to preserve history) to move the file to `board/archive/`:

```bash
git mv board/tasks/TASK-0003_add-caching.md board/archive/TASK-0003_add-caching.md
```

If not in a git repo, use plain `mv` instead. Create `board/archive/` if it doesn't exist.

### 4. Show Summary

Show a summary of what was moved.

## Notes

- Files keep their original filename and ID after archiving
- Archived items remain searchable via grep and git log
- Links from other docs (e.g., `blocked_by`, `parent`) still work since the ID is stable
- ADRs are NOT archived — they stay in `board/planning/` regardless of status since they are immutable historical records that should remain easily discoverable
