---
name: board-update
description: "Reconciles the project board with the codebase by analyzing git history and code state to detect completed tasks, unblocked items, stale work, and new tasks needed. Activates when the user asks to update or sync the board, or via '/board:board-update'. Also activates autonomously after completing significant coding work that may have resolved tracked tasks."
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, AskUserQuestion
---

# Board Update

Analyze the codebase and git history to automatically reconcile the project board with reality. The system spec is bundled with the plugin at `${CLAUDE_PLUGIN_ROOT}/spec/board-system-spec.md`.

## Board Data

Pre-loaded active board data:

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh" ./board --active 2>&1`

Archive counts:

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh" ./board --archive-summary 2>&1`

## Steps

### 1. Review Board State

Parse the pre-loaded board data above. Identify:
- All items with `status: backlog` or `status: current` (candidates for completion)
- Epics and their child tasks (via `parent` field)
- Blocked items and their blockers
- Items with terminal status (`done`, `processed`) that should be archived
- Items missing a required `status` field (all types except `reference`)

### 2. Gather Codebase Context

- Run `git log --oneline` for recent commits (last 30) to understand what work has been done
- Only Read full file bodies for tasks whose status is `backlog` or `current` AND whose title suggests overlap with recent commits
- Use the context budget escalation (Glob → Grep → Read with limit → Full read) for any additional lookups

### 3. Detect Completed Work

For each task with `status: backlog` or `status: current`, check if the work described has already been done:

- Look at recent commits for evidence the work was completed
- Check the codebase for the feature/fix the task describes
- If the work is done, flag it for status update to `done`

### 4. Detect New Work Needed

Scan for things that should become tasks but aren't tracked yet:

- Check recent commits for TODOs or FIXMEs introduced in code
- Look at open epics — are there obvious next steps not yet captured as tasks?
- Check if any `blocked_by` dependencies have been resolved (unblocking tasks)

### 5. Update Epic Progress

For each active epic:

- Check if all child tasks are `done` — if so, flag the epic as `done`
- Check if any child tasks are `current` — if so, the epic should be `current`
- Update the task list in the epic body if tasks have been added/removed

### 6. Check for Stale Items

- Tasks marked `current` but with no related commits in the last 30 days
- Epics in `planning` with no child tasks
- Resources stuck in `inbox` or `processing`

### 7. Present Changes

Present ALL proposed changes as a single summary before making any edits:

```
## Board Update Proposal

### Status Changes → Archive
- TASK-0003: backlog → done → **archive** (cache-decoded-image: implemented in commit a1b2c3d)
- EPIC-0001: planning → current (has active child tasks)
- NOTE-0002: already processed → **archive**

### New Tasks Suggested
- "Fix FIXME in preprocessing.rs line 42" (found in recent commit)

### Missing Status
- TASK-0025: no status field (required for tasks)

### Stale Items
- TASK-0007: marked current but no activity in 45 days

### Unblocked
- TASK-0005: blocker TASK-0003 is now done
```

**Terminal-status items must be archived atomically.** When a status change results in a terminal status (`done` for tasks/epics, `processed` for resources/notes), the archiving step is bundled into the same proposal line — not presented as a separate action. Items already at a terminal status but not yet archived should also appear with an **archive** tag.

ADRs are the sole exception — they are never archived regardless of status.

**Avoid redundant invocations** — if this skill was already invoked earlier in the session and the board has not been modified since, reuse the previous board data instead of invoking again.

Ask the user to approve, reject, or cherry-pick which changes to apply. Then execute only the approved changes:

- **Status updates + archive**: For items reaching a terminal status, update the status field first, then immediately run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/archive-batch.sh" ./board <file>` in the same step. Never leave an item with a terminal status outside `archive/`.
- **Status updates (non-terminal)**: Use `/board:board-edit` to update status fields
- **New tasks**: Invoke `/board:board-add` for each approved new task
- **Archive-only** (items already at terminal status): Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/archive-batch.sh" ./board <file1> <file2> ...` directly
