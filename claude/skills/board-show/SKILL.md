---
name: board-show
description: "Show the project board overview. Use when the user asks to see the board, check task status, view backlog, see what's in progress, or asks about project progress."
disable-model-invocation: true
---

# Board Overview

Display a summary of the active project board. The system spec is at `board/reference/REFE-0001_board-system-spec.md`.

## Steps

1. Read all `.md` files in `board/tasks/`, `board/planning/`, `board/reference/`, and `board/resources/` (NOT `board/archive/`)
2. Parse YAML frontmatter from each file to get `type`, `status`, `priority`, `blocked_by`
3. Display the board in this format:

```
## Project Board

### Current (in progress)
- TASK-0003: Cache decoded image [priority: 1]
- EPIC-0001: Native inference optimization

### Backlog (ready)
- TASK-0005: Optimize PNG compression [priority: 2]
- TASK-0006: Add SIMD morphological ops [priority: 3]

### Backlog (blocked)
- TASK-0001: Add CoreML macOS acceleration [blocked by: TASK-0008]

### Epics
- EPIC-0002: System info detection [planning] — 0/3 tasks done
- EPIC-0006: GPU execution providers [planning] — 0/2 tasks done

### Resource Inbox
- (none)

### Stats
- Tasks: 2 current, 5 backlog (3 ready, 2 blocked), 4 archived
- Epics: 0 current, 3 planning, 5 archived
```

## Sorting

- Current items first
- Backlog sorted by priority (1=high first), then by ID
- Blocked items last within backlog
- Determine "blocked" by checking if all items in `blocked_by` have `status: done` — if any blocker is NOT done, the task is blocked

## Epic Progress

For each epic, count child tasks (items whose `parent` references the epic) and show how many are done vs total.
