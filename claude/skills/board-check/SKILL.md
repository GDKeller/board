---
name: board-check
description: "Look up the project board for context relevant to current work. Use autonomously when starting a task, investigating a feature area, or making changes that might overlap with existing tracked work. Checks for related TASKs, EPICs, ADRs, REFEs, and RESOurces in board/. Also use when the user asks what's on the board for a topic, or to check if something is already tracked."
---

# Board Check

Read-only lookup of the `board/` project board to find items relevant to the current context. The system spec is at `board/reference/REFE-0001_board-system-spec.md`.

This skill is for **consulting** the board, not modifying it. Use `board-update` to make changes.

## When to Use

- Starting work on a feature or fix — check if there's an existing TASK or EPIC
- Investigating a code area — look for related REFEs or ADRs that document decisions
- Before creating a new task — verify it doesn't already exist
- When encountering unfamiliar architecture — check for ADRs explaining why

## Context Budget

This skill must be lightweight. Follow this strict escalation:

1. **Glob only** — use `board/{tasks,planning,reference,resources}/*.md` to get filenames. Filenames contain the type prefix and kebab-case title, which is often enough. Cost: near zero.
2. **Grep for frontmatter** — if you need status/priority, use Grep for `status:` or `priority:` within specific files. Returns just matching lines. Cost: minimal.
3. **Read with limit** — if a file looks relevant by name, use `Read` with `limit: 15` to get just the frontmatter + title. Do NOT read entire files at this stage. Cost: low.
4. **Full read** — only read the full body of a file if the user explicitly asks about it, or if the title strongly matches and you need the details to proceed. Cost: moderate.

Never read all doc files. Never read a file body just to check if it's relevant — the filename tells you that.

## Steps

### 1. Determine Search Context

From the current work, identify:
- Feature area or module name (e.g., "inference", "post-processing", "model management")
- Relevant keywords from the task at hand
- File paths being modified (map to likely doc topics)

### 2. Scan the Board

Search across active directories (NOT `board/archive/`):

| Directory | What to look for |
|-----------|-----------------|
| `board/tasks/` | Existing TASKs related to this work — could be duplicates, blockers, or related items |
| `board/planning/` | EPICs this work falls under, ADRs documenting relevant decisions, NOTEs with context |
| `board/reference/` | REFEs with technical knowledge relevant to the code area |
| `board/resources/` | RESOurces (articles, docs) that inform the work |

**Scanning approach**: Use Glob for filenames first. Use Grep to extract frontmatter fields (status, priority, blocked_by) from candidates. Only Read files (with `limit: 15`) when titles suggest relevance.

### 3. Report Findings

Present a brief summary of what's relevant:

```
## Board Context

### Related Tasks
- TASK-0005: Optimize PNG compression [backlog, priority 2]
  → Directly related to current work

### Relevant Decisions
- ADR-0001: Chose native inference over Python bridge
  → Explains why inference uses this approach

### Reference Material
- REFE-0002: Runtime initialization
  → Documents the startup pipeline being modified

### No Match
- No existing epic covers this work area
- No resources in the inbox relate to this
```

Only show categories that have matches. If nothing is relevant, say so briefly and move on.

## Guidelines

- **Minimize context usage** — most checks should cost only a Glob call + a few Grep calls
- Don't interrupt flow — present findings concisely, then continue with the actual work
- If you find a directly related TASK, mention it so the user knows work is tracked
- If you find a relevant ADR, factor its decisions into your approach
- If you find a relevant REFE, use it as context for better implementation
