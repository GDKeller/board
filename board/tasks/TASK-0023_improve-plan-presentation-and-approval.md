---
type: task
status: done
priority: 2
parent: EPIC-0002
created: 2026-03-26
---

# TASK-0023: Improve plan presentation format and approval interaction

## Plan format (M8)

Replace the markdown table (which doesn't render in Claude Code's terminal) with a numbered list format matching `board-update`'s proposal style:

```
## Migration Plan (5 files)

1. docs/auth-design.md → ADR: "Chose JWT for session management"
   Target: board/planning/ADR-0003_chose-jwt-for-session-management.md
2. docs/api-endpoints.md → reference: "API endpoint reference"
   Target: board/reference/REFE-0004_api-endpoint-reference.md
```

## Approval interaction (M9)

Add inline examples to the approval prompt so users know how to express changes:

> - Accept all: "looks good" or "proceed"
> - Reclassify: "#2 should be a note", "make 3 an epic"
> - Skip: "skip #4", "skip 4 and 6"
> - Rename: "#1 title should be 'Adopt JWT over sessions'"
> - Bulk: "make 2, 3, and 5 all notes"

Add: "Handle bulk operations — apply all stated changes to the plan before re-presenting for final confirmation."

## Cross-reference grep scope (L4)

Scope the post-migration reference grep to `*.md`, `*.txt`, `*.rst`. Limit results to 20 and summarize if more are found.

## Findings addressed

- M8, M9, L4 from [[NOTE-0004]]
