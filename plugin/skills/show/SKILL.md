---
name: board-show
description: "Displays a formatted project board overview grouped by status, with priority sorting, epic progress, blocking relationships, and archive statistics. Activates when the user asks to see the board, show tasks, view backlog, or check project status, or via '/board:board-show'."
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob
---

# Board Overview

Display a summary of the active project board. The system spec is bundled with the plugin at `${CLAUDE_PLUGIN_ROOT}/spec/board-system-spec.md`.

## Board Data

Pre-loaded active board data:

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh ./board --active`

Archive counts (type and count):

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh ./board --archive-summary`

## Instructions

Parse the board data above and display the board in this format:

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

## Notes

- **Avoid redundant invocations** — if this skill was already invoked earlier in the session and the board has not been modified since, use the previous results instead of invoking again

## Epic Progress

For each epic, count child tasks (items whose `parent` references the epic) and show how many are done vs total.
