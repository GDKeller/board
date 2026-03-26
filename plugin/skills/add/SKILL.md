---
name: board-add
description: "Creates new board items (tasks, epics, ADRs, notes, references, resources) with correct frontmatter, ID assignment, and duplicate detection. Activates when the user asks to add, create, or track a new board item, or via '/board:board-add'."
argument-hint: "[type] [title]"
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion
disable-model-invocation: true
---

# Add Board Item

Create a new item in the `board/` project management system. The system spec is bundled with the plugin at `${CLAUDE_PLUGIN_ROOT}/spec/board-system-spec.md`.

## Existing Board Items

Pre-loaded board data for duplicate detection:

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh ./board --active`

Before creating, check if a similar item already exists. If a close match is found, ask the user if they still want to create a new one.

## Scope Assessment

When the user requests a **TASK**, evaluate whether it is actually EPIC-sized before creating it. Look for these signals:

- Multiple distinct steps or deliverables in the description
- Multiple action verbs joined by "and" (e.g., "add auth and set up roles and integrate SSO")
- Work that spans different code areas or concerns
- Sub-steps that could be completed and shipped independently

**Quick test:** "Could someone meaningfully complete and ship part of this while the rest remains undone?" If yes → likely an EPIC.

If EPIC signals are present, suggest an EPIC + sub-TASKs with a concrete breakdown. For example:

> "This looks like it has multiple independent deliverables. Want me to create an EPIC with separate TASKs for each piece instead?"

**This is a soft suggestion only.** If the user says "just make it a task," comply without pushback.

This assessment only applies to TASK creation — do not second-guess EPICs, NOTEs, or other types.

## Arguments

The user provides the type and title: `/board:board-add task <title>`, `/board:board-add epic <title>`, etc.

If no type is given, ask the user what type of item to create.

## Determine Next ID

Run the ID assignment script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/next-id.sh <TYPE> ./board
```

This scans all directories (including `board/archive/` and `.doc-ids`) and returns the next available 4-digit zero-padded ID.

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
