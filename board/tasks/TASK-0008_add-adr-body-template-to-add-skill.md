---
type: task
status: backlog
priority: 2
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0008: Add ADR body template to /board:board-add skill

## Description

The `/board:board-add` skill provides detailed frontmatter templates for all six types but gives zero guidance about body content structure. The ADR type requires a specific 5-section structure (Context, Considered Approaches, Decision, Consequences, Spawned Items) per the spec. The LLM is left to guess, and the "Spawned Items" section (a lint-checked requirement) is easy to miss.

## Changes Required

### In `plugin/skills/board-add/SKILL.md`

After the frontmatter templates section, add body templates for structured types:

**ADR:**
```markdown
## Context
[What forces are at play? What is the current situation?]

## Considered Approaches
[What options were evaluated? Include enough detail to avoid re-trying failed approaches.]

## Decision
[What was decided and why?]

## Consequences
[Benefits, tradeoffs, and risks of the decision.]

## Spawned Items
[Explicit TASK/REFE links, or "No follow-up needed."]
```

Also add a post-creation reminder: "For ADRs, confirm the user has addressed the 'Spawned Items' section — it is required by the spec and lint-checked."

### Non-git fallback for edit skill

While in this area, also add a note to `plugin/skills/board-edit/SKILL.md` for the rename/retype paths: "If the project is not a git repository, use plain `mv` instead of `git mv`."
