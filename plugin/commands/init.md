---
name: board-init
description: "Initialize the board system in the current project"
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# Initialize Board System

Scaffold the board project management system into the current project.

## Steps

### 1. Check for Existing Board

Check if a `board/` directory already exists in the project root.

- If it exists, inform the user and ask if they want to re-initialize (which would overwrite spec files but preserve existing board items)
- If it doesn't exist, proceed with full initialization

### 2. Run Init Script

Run the initialization script to create directories, copy specs, and set up ID tracking:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-init.sh ${CLAUDE_PLUGIN_ROOT}
```

This creates in one shot:
- `board/{tasks,planning,reference,resources,archive}/`
- `board/.doc-ids` (ID tracking file)

The script is idempotent — it skips files/directories that already exist.

### 3. Update CLAUDE.md

Read `${CLAUDE_PLUGIN_ROOT}/templates/claude-md-snippet.md` for the snippet content.

- If a `CLAUDE.md` exists in the project root, check if it already contains a "Project Board" section
  - If yes, inform the user it's already configured
  - If no, append the snippet to the end of the file
- If no `CLAUDE.md` exists, ask the user if they want one created with the board snippet

### 4. Summary

Display what was created:

```
Board system initialized:
  board/tasks/          — actionable work items
  board/planning/       — epics, ADRs, notes
  board/reference/      — evergreen knowledge
  board/resources/      — external material inbox
  board/archive/        — completed items
  board/.doc-ids        — ID tracking file

Available commands:
  /board:board-show           — view board overview
  /board:board-add            — create new items
  /board:board-edit           — modify existing items
  /board:board-check          — find related board context
  /board:board-update         — reconcile board with codebase
  /board:board-archive        — archive completed items
```
