---
type: task
status: done
priority: 1
parent: EPIC-0002
created: 2026-03-26
---

# TASK-0015: Add pre-flight checks to board-migrate

Add validation steps that run before discovery/migration begins.

## Requirements

- **Dirty working tree warning (H5, M5):** After confirming `board/` exists, run `git status --porcelain` and warn the user if there are staged or unstaged changes. Recommend committing or stashing before proceeding. Advisory, not blocking.
- **Path validation (H5):** Before scanning a user-supplied path, verify it exists and is a directory. If not, report the specific invalid path and ask the user to correct it.
- **Board subdirectory enumeration (M7 from edge review):** Enumerate the exact expected subdirectories (`tasks/`, `planning/`, `reference/`, `resources/`, `archive/`) in Step 1. If any are missing, list which ones specifically rather than a generic "subdirectories missing" message.
- **`docs/` non-existence (L2):** If `docs/` does not exist, skip it silently — do not treat it as an error.

## Findings addressed

- H5, M5, L2 from [[NOTE-0004]]
