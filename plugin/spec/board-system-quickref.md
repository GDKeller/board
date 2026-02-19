# Board System Quick Reference

> Full specification: `board-system-spec.md`

## File Naming

```
TYPE-NNNN_kebab-case-description.md
```

| Prefix | Type |
|--------|------|
| `TASK` | Task |
| `EPIC` | Epic |
| `ADR` | Architecture Decision Record |
| `REFE` | Reference |
| `RESO` | Resource |
| `NOTE` | Note |

## Document Types

| Type | Status Values | Description |
|------|---------------|-------------|
| `task` | `backlog` → `current` → `done` | Actionable work item |
| `epic` | `planning` → `current` → `done` | Container for related tasks |
| `adr` | `active` \| `superseded` \| `deprecated` | Decision record, written after decision made |
| `reference` | _(none)_ | Evergreen knowledge base (encyclopedic) |
| `resource` | `inbox` → `processing` → `processed` | External material to review |
| `note` | `inbox` → `processed` | Unrefined thoughts (to be refined, then archived) |

## Priority (Tasks)

| Value | Meaning |
|-------|---------|
| `1` | High |
| `2` | Medium |
| `3` | Low |

## Required Frontmatter

**Task:**
```yaml
---
type: task
status: backlog
priority: 2
created: YYYY-MM-DD
---
```

**Epic:**
```yaml
---
type: epic
status: planning
created: YYYY-MM-DD
---
```

**ADR:**
```yaml
---
type: adr
status: active
context_date: YYYY-MM-DD
created: YYYY-MM-DD
---
```

**Resource:**
```yaml
---
type: resource
status: inbox
url: https://example.com
created: YYYY-MM-DD
---
```

**Reference:**
```yaml
---
type: reference
created: YYYY-MM-DD
---
```

**Note:**
```yaml
---
type: note
status: inbox
created: YYYY-MM-DD
---
```

## Directory Structure

```
board/
├── tasks/       # TASK-* files
├── planning/    # EPIC-*, ADR-*, NOTE-* files
├── reference/   # REFE-* files
├── resources/   # RESO-* files
└── archive/     # Completed items (except ADRs — they stay in planning/)
```

## Writing Rules

### Task Titles: Use Imperative Mood

Start with a verb. Describe the action to be done.

| Bad | Good |
|-----|------|
| User Authentication | Add user authentication |
| PNG Compression | Optimize PNG compression |
| Bug in Login | Fix login authentication bug |

### REFE vs ADR

| REFE (Reference) | ADR (Decision Record) |
|------------------|----------------------|
| What things ARE | What WE DID/DECIDED |
| Objective, encyclopedic | Subjective to this project |
| Evergreen, keep current | Immutable, never edited |
| No project decisions | Documents our choices |

### Epics vs Tasks

- **Epic**: Container for related tasks (lives in `planning/`)
- **Task**: Single, completable unit of work (lives in `tasks/`)

If it can't be done in one focused effort, split it into tasks under an epic.

**Quick test:** "Could someone meaningfully complete and ship part of this while the rest remains undone?" If yes → EPIC.

**EPIC signals:** multiple distinct verbs/actions, work spans multiple code areas, sub-steps shippable independently, would produce multiple PRs, description joins separate deliverables with "and".

### NOTE Lifecycle

NOTEs are the "to be refined" inbox. When processed, they **spawn** new artifacts:

```
NOTE (inbox) → process → spawns TASK(s), REFE(s), ADR(s), RESO(s) → archive NOTE (processed)
```

- NOTEs spawn, never convert — the original stays as historical record
- Never delete NOTEs — archive with `status: processed`
- One NOTE can spawn many artifacts, or none

## ADR Structure

```markdown
# ADR-NNNN: Title

## Context
What problem were we solving?

## Considered Approaches
What we tried/evaluated and what happened.

## Decision
What we decided and why.

## Consequences
Effects and trade-offs of this decision.

## Spawned Items
- [[TASK-...]] or [[REFE-...]] created
- Or: "No follow-up needed"
```

**Key rules:**
- ADRs are written AFTER decisions, not during
- "Decide X" TASK → always produces ADR as outcome
- ADRs spawn TASKs and REFEs, never NOTEs
- ADRs are NOT archived — they stay in `planning/`
- Status is validity (active/superseded/deprecated), not workflow

**Decision chain:**
```
TASK: "Decide on X" → ADR → TASK(s) for implementation
```

## Task Dependencies

```yaml
blocked_by: ["[[TASK-0001]]", "[[TASK-0003]]"]
```

- `blocked_by` is **informational** (documents dependency)
- Status stays `backlog` (no separate "blocked" status)
- "Actionable" is **derived** (computed), not stored
- Task is actionable when: `blocked_by` is empty OR all blockers are `done`

## Archiving

- Tasks with `status: done` → move to `board/archive/`
- Resources with `status: processed` → move to `board/archive/`
- Notes with `status: processed` → move to `board/archive/`
- **ADRs are never archived** — stay in `board/planning/`
- Files keep their original filename and ID

## Error Correction & Type Conversion

When an item was created as the wrong type, fix it with delete + create. Git preserves history.

**Process:**
1. Create new item with correct type + next available ID for that type (via `next-id.sh`)
2. Carry over relevant content (adjust title/frontmatter for new type)
3. Delete old file via `git rm`
4. Update cross-references (`blocked_by`, `parent`, `tasks`, `spawned`, wiki-links) to new ID

**Key rules:**
- **IDs don't carry over** — TASK-0022 retyped to NOTE becomes NOTE-0005 (next available), not NOTE-0022
- **ADRs are immutable** — never convert FROM an ADR; create new item separately
- **Not the same as spawning** — error correction fixes a recent mistake; spawning extracts value from a correctly-typed item over time
