---
type: task
status: backlog
priority: 3
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0010: Improve example board

## Description

The board validator found the example board is too sparse (just ADR-0001) to serve as a useful example or self-management tool. Empty directories aren't tracked by git. ADR-0001 has two minor structural violations.

## Changes Required

### Fix ADR-0001

1. Add ID prefix to heading: `# ADR-0001: Adopt dynamic context injection for board skills`
2. Add "Considered Approaches" section between Context and Decision (even a brief one about the alternative of explicit Bash tool calls)

### Add `.gitkeep` files

Create `.gitkeep` in empty directories so they survive git clone:
- `board/tasks/.gitkeep`
- `board/reference/.gitkeep`
- `board/resources/.gitkeep`
- `board/archive/.gitkeep`

### Consider example items

Optionally add 1-2 representative items per type to demonstrate the system. However, since this board is also used for self-management, the EPIC and TASKs from this review now serve as live examples. Evaluate whether additional synthetic examples are needed after the review tasks are complete.
