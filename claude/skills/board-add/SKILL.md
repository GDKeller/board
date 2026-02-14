---
name: board-add
description: "Create a new board item (task, epic, ADR, note, reference, or resource). Use when the user wants to add a task, create an epic, write an ADR, add a note, create a reference doc, or track a resource."
disable-model-invocation: true
---

# Add Board Item

Create a new item in the `board/` project management system. The system spec is at `board/reference/REFE-0001_board-system-spec.md`.

## Arguments

The user provides the type and title: `/board:add task <title>`, `/board:add epic <title>`, etc.

If no type is given, ask the user what type of item to create.

## Determine Next ID

1. Scan ALL directories including `board/archive/` for files matching the type prefix (e.g., `TASK-*`)
2. Find the highest existing ID number
3. Use the next number (zero-padded to 4 digits)

## Create the File

Use the correct directory, frontmatter, and naming convention:

| Type | Directory | Filename Example |
|------|-----------|-----------------|
| task | `board/tasks/` | `TASK-0014_add-batch-processing.md` |
| epic | `board/planning/` | `EPIC-0009_batch-mode.md` |
| adr | `board/planning/` | `ADR-0002_chose-webgpu-over-wasm.md` |
| note | `board/planning/` | `NOTE-0001_explore-wasm-option.md` |
| reference | `board/reference/` | `REFE-0007_webgpu-overview.md` |
| resource | `board/resources/` | `RESO-0001_webgpu-article.md` |

## Frontmatter Templates

Task:
```yaml
---
type: task
status: backlog
priority: 2
created: YYYY-MM-DD
---
```

Epic:
```yaml
---
type: epic
status: planning
created: YYYY-MM-DD
---
```

ADR:
```yaml
---
type: adr
status: active
context_date: YYYY-MM-DD
created: YYYY-MM-DD
---
```

Note:
```yaml
---
type: note
status: inbox
created: YYYY-MM-DD
---
```

Reference:
```yaml
---
type: reference
created: YYYY-MM-DD
---
```

Resource (ask user for URL):
```yaml
---
type: resource
status: inbox
url: <url>
created: YYYY-MM-DD
---
```

## Naming Rules

- Convert title to kebab-case for filename
- Task titles MUST be imperative mood (start with a verb). If the user gives a noun phrase, rewrite it (e.g., "batch processing" -> "Add batch processing support")
- Use today's date for `created`

## After Creation

Show the file path and ask if the user wants to add more detail to the body.
