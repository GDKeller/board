---
type: task
status: backlog
priority: 3
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0011: Fix skill UX issues

## Description

The UX review identified several prompt engineering and usability issues across skills and the init command.

## Changes Required

### Cross-skill: "Avoid redundant invocations" wording (4 skills)

Reword in `show`, `check`, `edit`, `archive` from "if this skill was already invoked earlier..." to: "If board data from this skill is already present in context and no board modifications have been made since, use that data rather than invoking this skill again."

### `/board:board-init` (plugin/skills/board-init/SKILL.md)

1. Add `/board:board-lint` to the available commands summary
2. Fix re-init description — it says "overwrite spec files" but `board-init.sh` is fully idempotent and skips existing files
3. Mention the SessionStart hook behavior so users know lint runs automatically

### `/board:board-update` (plugin/skills/board-update/SKILL.md)

4. Put `git log --oneline` in a fenced code block so the LLM executes it rather than describes it
5. Clarify sub-skill delegation: for status-only updates, apply directly with the Edit tool; for new tasks, invoke `/board:board-add`
6. Add guard: "If no git history is available, skip commit-based staleness checks"

### `/board:board-archive` (plugin/skills/board-archive/SKILL.md)

7. Add epic-status cascade suggestion: "If archiving tasks that belong to an epic, check whether all sibling tasks are also done. If so, suggest updating the epic to `done`."

### SessionStart hook (`plugin/hooks/hooks.json`)

8. Suppress "Board lint: all files valid." output for clean boards to reduce session noise
