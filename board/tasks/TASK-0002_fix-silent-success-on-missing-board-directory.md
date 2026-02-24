---
type: task
status: backlog
priority: 1
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0002: Fix silent success on missing board directory

## Description

Both `board-scan.sh` and `board-lint.sh` exit 0 with no error when the `board/` directory doesn't exist. This causes every skill to receive what looks like a valid empty board rather than an error condition — no duplicate detection, empty show output, no lint findings, all silently wrong.

## Changes Required

### `plugin/scripts/board-scan.sh` (lines 26-30)

Change the missing-directory handler to exit non-zero with a stderr message:

```bash
if [[ ! -d "$BOARD_ROOT" ]]; then
    echo "Error: No board directory found at $BOARD_ROOT. Run /board:init to set up." >&2
    exit 1
fi
```

### `plugin/scripts/board-lint.sh` (lines 21-23)

Output a diagnostic even in the no-board case:

```bash
if [[ ! -d "$BOARD_ROOT" ]]; then
    echo "Board lint: no board/ directory found at $BOARD_ROOT — skipping."
    exit 0
fi
```

Note: lint stays exit 0 (not every project uses board), but now produces visible output so the user knows it ran.
