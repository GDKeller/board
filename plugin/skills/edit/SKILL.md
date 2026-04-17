---
name: board-edit
description: "Modifies existing board items — changes status, priority, blockers, titles, body content, and type (convert/retype) with validation of status transitions, ADR immutability, and imperative mood enforcement. Activates when the user asks to edit, update, change, convert, or retype a board item, or via '/board:board-edit'."
argument-hint: "[item-id] [field] [value]"
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, AskUserQuestion
disable-model-invocation: true
---

# Edit Board Item

Modify an existing item in the `board/` project management system. The system spec is bundled with the plugin at `${CLAUDE_PLUGIN_ROOT}/spec/board-system-spec.md`.

## Arguments

The user provides the item ID and what to change: `/board:board-edit TASK-0003 status current`, `/board:board-edit TASK-0005 priority 1`, etc.

If the item ID is ambiguous or missing, search by keyword using Glob on filenames and ask the user to confirm which item.

## Board Data

Pre-loaded board data:

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh ./board --active`

## Locate the Item

1. Find the item in the board data above by matching the ID from `$ARGUMENTS`
2. Read the file with `limit: 15` to get current frontmatter
3. If not found in the active board data, check `board/archive/` with Glob before reporting the item doesn't exist

## Validation Rules

### Status Transitions

Validate transitions using the script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-status.sh <type> <from_status> <to_status>
```

Exit codes: `0` = valid forward transition, `2` = backward transition (confirm with user), `1` = invalid.

Valid forward transitions:

| Type | Valid Transitions |
|------|-------------------|
| task | `backlog` → `current` → `done` |
| epic | `planning` → `current` → `done` |
| resource | `inbox` → `processing` → `processed` |
| note | `inbox` → `processed` |
| adr | `active` → `superseded` or `active` → `deprecated` |

Backward transitions (e.g., `done` → `backlog`) are allowed but should confirm with the user first — they may indicate a reopened task.

### ADR Immutability

ADRs are **immutable**. The only permitted edit is changing `status` (to `superseded` or `deprecated`). If the user asks to edit ADR content, explain that ADRs are write-once and suggest:
- Adding a dated addendum at the bottom of the file
- Creating a new ADR that supersedes the old one (via `/board:board-add adr`)

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
| `type` | all except adr | Retype/convert — creates new file, deletes old (see below) |

## Retype (Convert Type)

When the user asks to convert or retype an item (e.g., "convert TASK-0022 to a note", "retype this as an epic"):

### Validation

1. **Refuse if source is ADR** — ADRs are immutable. Explain why and suggest creating a new item separately.
2. **Confirm with user** — "This will delete TASK-0022 and create a new NOTE with the next available ID. Proceed?"

### Procedure

1. **Get next ID** for the target type:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/next-id.sh <TARGET_TYPE> ./board
   ```
2. **Create new file** with:
   - Correct type prefix and ID in filename
   - Correct directory for the target type
   - Correct frontmatter (initial status for new type, carry over applicable fields)
   - Body content carried over from old item
   - Title adjusted if needed (e.g., imperative mood for TASKs, relaxed for NOTEs)
3. **Delete old file** via `git rm`
4. **Find and update cross-references** — use Grep to search for the old ID across all board files:
   - `blocked_by` lists
   - `parent` fields
   - `tasks` lists (in EPICs)
   - `spawned` lists (in NOTEs)
   - Wiki-links (`[[OLD-ID]]`) in body content

   Update each reference to the new ID.
5. **Report** the change: `Retyped: TASK-0022 → NOTE-0005 (old file deleted, references updated)`

### Type-Specific Adjustments

| Target Type | Adjustments |
|-------------|-------------|
| task | Title must be imperative mood; `status: backlog`; add `priority: 2` |
| epic | Title stays imperative; `status: planning`; consider adding `tasks:` list |
| note | `status: inbox`; title can relax imperative mood |
| reference | No status field; content must be objective/encyclopedic |
| resource | Requires `url` (ask user); `status: inbox` |

## Execution

1. Apply the edit via targeted frontmatter field replacement (use Edit tool, not full file rewrite)
2. If renaming, use `git mv` for the file and update the `# heading`
3. **If the status change results in a terminal status** (`done` for tasks/epics, `processed` for resources/notes), archive the item immediately after updating the status:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/archive-batch.sh ./board <file_path>
   ```
   ADRs are the sole exception — they are never archived regardless of status.
   If the user explicitly asks NOT to archive, respect that but note the lint warning they will see.
4. Show a summary of what changed: `TASK-0003: status backlog → done → archived`
5. If the edit unblocks other tasks (a blocker was marked `done`), mention which tasks are now unblocked

## Notes

- **Avoid redundant invocations** — if this skill was already invoked earlier in the session and the board has not been modified since, reuse the previous board data instead of invoking again
