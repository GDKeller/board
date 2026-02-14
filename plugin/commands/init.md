---
name: init
description: "Initialize the board system in the current project"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# Initialize Board System

Scaffold the board project management system into the current project.

## Steps

### 1. Check for Existing Board

Check if a `board/` directory already exists in the project root.

- If it exists, inform the user and ask if they want to re-initialize (which would overwrite spec files but preserve existing board items)
- If it doesn't exist, proceed with full initialization

### 2. Create Directory Structure

Create the board directories:

```bash
mkdir -p board/{tasks,planning,reference,resources,archive}
```

### 3. Copy Spec Files

Copy the board system specification and quick reference from the plugin templates into the project:

- Copy `${CLAUDE_PLUGIN_ROOT}/templates/REFE-0001_board-system-spec.md` to `board/reference/REFE-0001_board-system-spec.md`
- Copy `${CLAUDE_PLUGIN_ROOT}/templates/REFE-0002_board-system-quickref.md` to `board/reference/REFE-0002_board-system-quickref.md`

Use the Read tool to read each template file, then the Write tool to write it to the destination.

### 4. Create ID Tracking File

Create `board/.doc-ids` with initial values:

```
TASK=0000
EPIC=0000
ADR=0000
REFE=0002
RESO=0000
NOTE=0000
```

REFE starts at 0002 because REFE-0001 and REFE-0002 are the spec files just created.

### 5. Update CLAUDE.md

Read `${CLAUDE_PLUGIN_ROOT}/templates/claude-md-snippet.md` for the snippet content.

- If a `CLAUDE.md` exists in the project root, check if it already contains a "Project Board" section
  - If yes, inform the user it's already configured
  - If no, append the snippet to the end of the file
- If no `CLAUDE.md` exists, ask the user if they want one created with the board snippet

### 6. Summary

Display what was created:

```
Board system initialized:
  board/tasks/          — actionable work items
  board/planning/       — epics, ADRs, notes
  board/reference/      — evergreen knowledge (spec files added)
  board/resources/      — external material inbox
  board/archive/        — completed items
  board/.doc-ids        — ID tracking file

Available commands:
  /board:show           — view board overview
  /board:add            — create new items
  /board:check          — find related board context
  /board:update         — reconcile board with codebase
  /board:archive        — archive completed items
```
