---
name: board-edit
description: "This skill should be used when the user asks to 'edit a task', 'update a task', 'change task status', 'mark task as done', 'set priority', 'add a blocker', 'change task description', 'update an epic', or any variant of modifying an existing board item. Also triggered by '/board:edit'."
disable-model-invocation: true
---

# Edit Board Item

Modify an existing item in the `board/` project management system. The system spec is at `board/reference/REFE-0001_board-system-spec.md`.

## Arguments

The user provides the item ID and what to change: `/board:edit TASK-0003 status current`, `/board:edit TASK-0005 priority 1`, etc.

If the item ID is ambiguous or missing, search by keyword using Glob on filenames and ask the user to confirm which item.

## Locate the Item

1. Glob for `board/**/<TYPE>-<ID>_*.md` (search active directories first, then `board/archive/`)
2. Read the file with `limit: 15` to get current frontmatter
3. If not found, report the item doesn't exist

## Validation Rules

### Status Transitions

Valid forward transitions:

| Type | Valid Transitions |
|------|-------------------|
| task | `backlog` → `current` → `done` |
| epic | `planning` → `current` → `done` |
| resource | `inbox` → `processing` → `processed` |
| note | `inbox` → `processed` |
| adr | `active` → `superseded` or `active` → `deprecated` |

Backward transitions (e.g., `done` → `backlog`) are allowed but should confirm with the user first — they may indicate a reopened task.

Invalid transitions (e.g., `done` → `inbox`) must be rejected.

### ADR Immutability

ADRs are **immutable**. The only permitted edit is changing `status` (to `superseded` or `deprecated`). If the user asks to edit ADR content, explain that ADRs are write-once and suggest:
- Adding a dated addendum at the bottom of the file
- Creating a new ADR that supersedes the old one (via `/board:add adr`)

If setting an ADR to `superseded`, ask for the superseding ADR ID and add `superseded_by` to the frontmatter.

### Task Title Changes

If editing a task title (the `# heading` or filename), enforce imperative mood. If the new title is a noun phrase, rewrite it (e.g., "authentication" → "Add authentication").

Renaming also requires renaming the file to match: `TASK-NNNN_new-kebab-case-title.md`. Use `git mv` to preserve history.

### Reference Docs

REFE items have no status field. Edits to reference content are unrestricted — they are meant to be kept current.

### Priority Values

Only `1` (high), `2` (medium), or `3` (low) are valid. Reject other values.

## Editable Fields

| Field | Types | Notes |
|-------|-------|-------|
| `status` | all except reference | Must follow valid transitions |
| `priority` | task | Values: 1, 2, 3 |
| `blocked_by` | task | List of task IDs; add or remove individual blockers |
| `parent` | task | Link to parent epic |
| `due` | task | Date value |
| `tags` | all | List of strings; add or remove individual tags |
| `title` | all | Rename heading + file; imperative mood for tasks |
| `body` | all except adr | Freeform content below frontmatter |
| `superseded_by` | adr | Only when setting status to superseded |
| `url` | resource | Primary external URL |

## Execution

1. Apply the edit via targeted frontmatter field replacement (use Edit tool, not full file rewrite)
2. If renaming, use `git mv` for the file and update the `# heading`
3. Show a summary of what changed: `TASK-0003: status backlog → current`
4. If the edit unblocks other tasks (a blocker was marked `done`), mention which tasks are now unblocked
