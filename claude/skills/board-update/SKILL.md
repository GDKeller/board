---
name: board-update
description: "Automatically reconcile the project board with the codebase. Use when the user asks to update the board, sync tasks, check what's changed, refresh task statuses, or maintain the project board. Also activate autonomously after completing significant coding work (feature implementations, bug fixes, refactors) that may have resolved or affected tracked tasks."
---

# Board Update

Analyze the codebase and git history to automatically reconcile the project board with reality. The system spec is at `board/reference/REFE-0001_board-system-spec.md`.

## Context Budget

Minimize context usage with strict escalation:

1. **Glob** — get filenames from `board/{tasks,planning,resources}/*.md`. Cost: near zero.
2. **Grep** — extract frontmatter fields (`status:`, `priority:`, `blocked_by:`, `parent:`) from matching files. Cost: minimal.
3. **Read with limit** — use `limit: 15` to read just frontmatter + title of files that need deeper inspection. Cost: low.
4. **Full read** — only read full file bodies when you need to check if task work is actually done (compare body description against commits/code). Cost: moderate — do this selectively, not for all files.

Never bulk-read all doc files. Most reconciliation can be done from filenames + frontmatter fields + git log.

## Steps

### 1. Gather Context

- Use Glob to list active board items in `board/tasks/`, `board/planning/`, `board/resources/` (not archive)
- Use Grep to extract `status:` and `priority:` fields from those files (avoids reading full files)
- Run `git log --oneline` for recent commits (last 30) to understand what work has been done
- Only Read full file bodies for tasks whose status is `backlog` or `current` AND whose filename suggests overlap with recent commits

### 2. Detect Completed Work

For each task with `status: backlog` or `status: current`, check if the work described in the task body has already been done:

- Look at recent commits for evidence the work was completed
- Check the codebase for the feature/fix the task describes
- If the work is done, flag it for status update to `done`

### 3. Detect New Work Needed

Scan for things that should become tasks but aren't tracked yet:

- Check recent commits for TODOs or FIXMEs introduced in code
- Look at open epics — are there obvious next steps not yet captured as tasks?
- Check if any `blocked_by` dependencies have been resolved (unblocking tasks)

### 4. Update Epic Progress

For each active epic:

- Check if all child tasks are `done` — if so, flag the epic as `done`
- Check if any child tasks are `current` — if so, the epic should be `current`
- Update the task list in the epic body if tasks have been added/removed

### 5. Check for Stale Items

- Tasks marked `current` but with no related commits in the last 30 days
- Epics in `planning` with no child tasks
- Resources stuck in `inbox` or `processing`

### 6. Present Changes

Present ALL proposed changes as a single summary before making any edits:

```
## Board Update Proposal

### Status Changes
- TASK-0003: backlog -> done (cache-decoded-image: implemented in commit a1b2c3d)
- EPIC-0001: planning -> current (has active child tasks)

### New Tasks Suggested
- "Fix FIXME in preprocessing.rs line 42" (found in recent commit)

### Ready to Archive
- TASK-0003: done, ready to move to archive/

### Stale Items
- TASK-0007: marked current but no activity in 45 days

### Unblocked
- TASK-0005: blocker TASK-0003 is now done
```

Use AskUserQuestion to let the user approve, reject, or cherry-pick which changes to apply. Then execute only the approved changes:

- Update frontmatter status fields via targeted edits
- Create new task files for suggested tasks (if approved)
- Archive done items via `git mv` (if approved)
