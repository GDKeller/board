---
name: check
description: "This skill should be used when the user asks to 'check the board', 'find related tasks', 'what's tracked for this area', 'is this already on the board', or when starting work on a feature to find related board context. Also triggered by '/board:check'. Can be activated autonomously when investigating a feature area or making changes that might overlap with existing tracked work."
---

# Board Check

Read-only lookup of the `board/` project board to find items relevant to the current context. The system spec is at `board/reference/REFE-0001_board-system-spec.md`.

This skill is for **consulting** the board, not modifying it. Use `/board:update` to make changes.

## When to Use

- Starting work on a feature or fix — check if there's an existing TASK or EPIC
- Investigating a code area — look for related REFEs or ADRs that document decisions
- Before creating a new task — verify it doesn't already exist
- When encountering unfamiliar architecture — check for ADRs explaining why

## Context Budget

This skill must be lightweight. Follow this escalation:

1. **Board scan** — run the scan script to get all items with metadata in one call. Cost: one Bash invocation.
2. **Filter by title** — match filenames/titles against current work keywords. Cost: zero (in-memory).
3. **Read with limit** — if a file looks relevant, use `Read` with `limit: 15` to get frontmatter + title. Do NOT read entire files at this stage. Cost: low.
4. **Full read** — only read the full body of a file if the user explicitly asks about it, or if the title strongly matches and you need the details to proceed. Cost: moderate.

Never read all doc files. Never read a file body just to check if it's relevant — the title from the scan tells you that.

## Steps

### 1. Determine Search Context

From the current work, identify:
- Feature area or module name (e.g., "inference", "post-processing", "model management")
- Relevant keywords from the task at hand
- File paths being modified (map to likely doc topics)

### 2. Scan the Board

Run the board scan script to get all items with parsed frontmatter:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh
```

Filter the output by matching titles and filenames against the keywords from step 1. Look for:

| Type | What to look for |
|------|-----------------|
| TASK | Existing TASKs related to this work — could be duplicates, blockers, or related items |
| EPIC/ADR/NOTE | EPICs this work falls under, ADRs documenting relevant decisions, NOTEs with context |
| REFE | REFEs with technical knowledge relevant to the code area |
| RESO | RESOurces (articles, docs) that inform the work |

Only use `Read` (with `limit: 15`) on items whose titles suggest relevance.

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

- **Minimize context usage** — most checks should cost only the board scan + a few targeted Read calls
- Don't interrupt flow — present findings concisely, then continue with the actual work
- If you find a directly related TASK, mention it so the user knows work is tracked
- If you find a relevant ADR, factor its decisions into your approach
- If you find a relevant REFE, use it as context for better implementation
