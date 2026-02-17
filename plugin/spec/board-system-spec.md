---
type: reference
created: 2026-02-12
---
# Board System Specification

> **Status:** Active

A documentation and project management system designed for human-AI collaboration. Plain text files, minimal process, maximum clarity.

---

## Guiding Principles

These axioms inform every design decision in the system.

### 1. Never Rely on Discipline

Human willpower, memory, and routine are points of failure. They will fail — it's a matter of when, not if. The system must be designed so that:
- Nothing falls through the cracks due to forgotten reviews
- No periodic "check on X" rituals are required
- Relevant context surfaces automatically when needed

### 2. Explicit Over Implicit

Every outcome must be resolved explicitly. No vague items lingering in documents.
- ADRs must list spawned items or state "no follow-up needed"
- TASKs are actionable or they're not TASKs yet
- If something is worth tracking, decide what type it is

### 3. Write-Once Artifacts

Documents should be written once and not require ongoing maintenance.
- ADRs are immutable historical records
- Status reflects validity, not workflow
- No "update this when X happens" requirements

### 4. One Home for Each Concern

Every type of information has exactly one place:
- Work to do → TASK
- Decisions made → ADR
- Domain knowledge → REFE
- Unrefined thoughts → NOTE
- External material → RESO

No overlap. No ambiguity about where something belongs.

### 5. Binary Actionability

Something is either actionable or it's not. No intermediate states.
- If you can write the first concrete step → TASK
- If it's still fuzzy → NOTE (refine until it's a TASK, or discard)
- No "maybe someday" purgatory

### 6. Simple Over Complex

Resist the pull toward JIRA/PM complexity hell.
- Minimal status values (3 for TASKs, 3 for ADRs)
- No custom fields proliferation
- If a workflow feels heavy, question whether it's necessary

### 7. The Artifact is Separate from the Work

- TASK = the work to be done
- ADR = the artifact produced by decision work
- REFE = the artifact produced by knowledge extraction
- Don't conflate process with output

## Design Goals

1. **Single source of truth** — metadata lives with the document, no separate index to maintain
2. **Self-identifying files** — type and ID visible in filename
3. **Standalone files** — each file makes sense without the organizational system
4. **Query-friendly** — structured metadata enables filtering and search
5. **Portable** — plain text (markdown + YAML) works anywhere

---

## Document Types

### Overview

| Type | Purpose | Status Values |
|------|---------|---------------|
| TASK | Actionable work item | `backlog` → `current` → `done` |
| EPIC | Container for related tasks | `planning` → `current` → `done` |
| ADR | Immutable decision record | `active` \| `superseded` \| `deprecated` |
| REFE | Evergreen knowledge base | *(none)* |
| RESO | External material to process | `inbox` → `processing` → `processed` |
| NOTE | Unrefined thoughts (inbox) | `inbox` → `processed` |

### TASK (Actionable Work)

A TASK is a single, completable unit of work. If it can't be done in one focused effort, split it into multiple TASKs under an EPIC.

**Required metadata:**
- `type: task`
- `status`: `backlog` | `current` | `done`
- `created`: date

**Optional metadata:**
- `priority`: `1` (high) | `2` (medium) | `3` (low)
- `due`: target completion date
- `blocked_by`: list of blocking tasks
- `parent`: link to parent epic/task
- `tags`: list of cross-cutting tags

#### Task Dependencies (blocked_by)

The `blocked_by` field documents task dependencies. It is **informational**, not a system-enforced constraint.

**Key points:**
- Status remains workflow-only (`backlog`/`current`/`done`) — no separate "blocked" status
- A task with `blocked_by` stays in `backlog` until blockers are `done`
- When choosing what to work on, tasks with unresolved blockers are skipped

**Determining if a task is actionable:**
1. Status is `backlog` (not already current or done)
2. Either `blocked_by` is empty/missing, OR all tasks in `blocked_by` have `status: done`

#### Derived vs Explicit State

The "is actionable" state is **derived**, not explicit:

| Approach | How it works | Trade-off |
|----------|--------------|-----------|
| **Derived** (our approach) | Computed on-demand from `blocked_by` + blocker statuses | Requires computation, but always accurate |
| **Explicit** (avoided) | Stored as field like `actionable: true` | Requires updating when blockers change |

**Why derived is better:**
- **No sync discipline** — Nothing to update when blockers complete
- **Single source of truth** — Each task owns only its own `status`
- **Can't get stale** — Computed from current state

This aligns with Principle #1 (Never Rely on Discipline).

### EPIC (Initiative Container)

Epics are containers for related tasks. They track overall progress of a larger initiative.

**Required metadata:**
- `type: epic`
- `status`: `planning` | `current` | `done`
- `created`: date

**Optional metadata:**
- `tasks`: list of child task links
- `tags`: list of cross-cutting tags

**Rule of thumb:** If it can't be completed in a single focused effort, it's probably an epic that should be split into tasks.

### ADR (Architecture Decision Record)

ADRs are **immutable historical records of decisions already made**. They document what was tried, what was decided, and why. ADRs are written *after* a decision is made, not during the decision-making process.

> **Key principle**: If you need to track "we must decide X", that's a TASK. The ADR is the artifact produced when the TASK completes.

**Required metadata:**
- `type: adr`
- `status`: `active` | `superseded` | `deprecated`
- `context_date`: when this decision was made
- `created`: date

**Optional metadata:**
- `superseded_by`: link to ADR that supersedes this one
- `tags`: list of cross-cutting tags

#### ADR Status (Validity, Not Workflow)

ADR status reflects whether the decision still applies, not where it is in a process:

| Status | Meaning |
|--------|---------|
| `active` | This decision still applies to the project |
| `superseded` | Replaced by a newer ADR (link in `superseded_by`) |
| `deprecated` | No longer relevant (context changed, feature removed, etc.) |

There is no `proposed` or `pending` status. Decision-making work is tracked as TASKs.

#### ADR Document Structure

```markdown
# ADR-NNNN: Title (Decision Summary)

## Context
What problem were we solving? What was the situation that required a decision?

## Considered Approaches
What options did we evaluate? Include enough detail to avoid re-trying failed approaches.

### Approach 1: Name
- What it involves
- Pros and cons
- Why selected or rejected

### Approach 2: Name
...

## Decision
What we decided and why. Be explicit about the rationale.

## Consequences
Effects of this decision — both positive and negative. What trade-offs are we accepting?

## Spawned Items
Explicit list of artifacts created from this ADR. **All outcomes must be resolved here.**

- [[REFE-0008_smoothing-algorithms]] — domain knowledge extracted
- [[TASK-0010_research-bilateral-filtering]] — follow-up exploration
- No other action needed.
```

#### What ADRs Can Spawn

ADRs must have explicit, closed outcomes. Every follow-up becomes a concrete item:

| Outcome Type | Spawns | Example |
|--------------|--------|---------|
| Domain knowledge learned | REFE | "How smoothing algorithms work" |
| Actionable work (any kind) | TASK | "Research bilateral filtering feasibility" |
| New decision needed | TASK | "Determine approach for X" → future ADR |
| Just context | Nothing | Note in Consequences: "No follow-up needed" |

**ADRs never spawn NOTEs.** If something is worth capturing, decide what it is (TASK or REFE). If it's too vague to categorize, it's not worth tracking separately — leave it as context in the Consequences section.

#### ADR Lifecycle

```
Problem identified
    → TASK: "Decide on approach for X"
    → Work happens, decision made
    → ADR written (status: active)
    → TASK completed (links to ADR)
    → ADR spawns TASKs/REFEs as needed

Later, if revisited:
    → New TASK: "Revisit decision on X"
    → New ADR written
    → Old ADR: status: superseded, superseded_by: [[new ADR]]
```

#### "Decide" TASKs Always Produce ADRs

When a TASK uses the verb "Decide" (or similar: "Determine", "Evaluate", "Choose"), its outcome is always an ADR:

```
TASK: "Decide on caching strategy"
    → ADR-0005: Caching Strategy Decision
        → spawns: TASK: "Implement Redis caching layer"
        → spawns: TASK: "Add cache invalidation logic"

TASK: "Determine GPU acceleration approach"
    → ADR-0006: GPU Acceleration Decision
        → spawns: TASK: "Create implementation plan for integration"
            → spawns: TASK: "Add execution provider"
            → spawns: TASK: "Add fallback logic for unsupported hardware"
```

This ensures all significant decisions are documented. The ADR is the artifact; the TASK is the work to produce it.

#### Immutability

ADRs are never edited to change the historical record. If new information emerges:
- Add a dated addendum at the bottom (preserves original context)
- Or create a new ADR that supersedes the old one

### REFE (Reference)

Reference docs are **evergreen encyclopedia entries**. They explain concepts, show pros/cons, and link to external resources. They contain no prescriptive assertions about what this project should do — that belongs in ADRs or TASKs.

**Required metadata:**
- `type: reference`
- `created`: date

**Optional metadata:**
- `topic`: category (e.g., "databases", "auth", "deployment")
- `version`: if doc is version-specific
- `verified`: last confirmed accurate (for tracking currency)
- `tags`: list of cross-cutting tags

#### Reference Doc Character

- **Objective**: Explains what things ARE, not what we SHOULD do
- **Textbook-style**: Defines terms, explains algorithms, shows tradeoffs
- **Evergreen**: Should be kept current; use `verified` to track when reviewed
- **No project decisions**: Those belong in ADRs

### RESO (Resource)

Resources are external material to be processed — articles, repos, videos, documentation.

**Required metadata:**
- `type: resource`
- `status`: `inbox` | `processing` | `processed`
- `url`: primary external URL
- `created`: date

**Optional metadata:**
- `source_type`: `repo` | `article` | `docs` | `video` | `tool`
- `processed`: date when fully processed
- `spawned_tasks`: list of tasks created from this
- `tags`: list of cross-cutting tags

#### Resource Document Structure

```markdown
# Resource Title

## Why Interesting
<!-- Your initial notes on why you're saving this -->

## Key Takeaways
<!-- Filled during processing — main points extracted -->

## Relevant to This Project
<!-- How it applies, what could be adopted -->

## TODOs
- [ ] Review X
- [ ] Extract Y

## Tasks Created
<!-- Links added as tasks are spawned -->
- [[TASK-0001_...]]
```

#### Resource Lifecycle

```
inbox → processing → processed (→ archive/)
```

1. **inbox** — Just added, needs review
2. **processing** — Actively extracting info, making decisions
3. **processed** — Done; tasks spawned, can be archived

### NOTE (Unrefined Thoughts)

Notes are the **"to be refined" inbox** — unprocessed thoughts that haven't been categorized yet. When processed, NOTEs **spawn** other artifacts; they are never converted or deleted.

**Required metadata:**
- `type: note`
- `status`: `inbox` | `processed`
- `created`: date

**Optional metadata:**
- `spawned`: list of spawned artifact links (when processed)
- `tags`: list of cross-cutting tags

#### Note Lifecycle

```
Raw thought → NOTE (status: inbox)
                │
                ├── Process the NOTE
                │     ├── spawns TASK(s) for actionable work
                │     ├── spawns ADR for decisions made
                │     ├── spawns REFE for domain knowledge extracted
                │     ├── spawns RESO for external material discovered
                │     └── (can spawn multiple artifacts of any combination)
                │
                └── Archive the NOTE (status: processed)
                      └── Move to archive/ with spawned: links
```

#### Key Principles

1. **NOTEs spawn, not convert** — The NOTE remains as the historical record of the original thought. Spawned artifacts are new documents that may reference back to the NOTE.

2. **Never delete NOTEs** — Even if a NOTE spawns nothing useful, archive it with `status: processed`. The thought process has value as historical context.

3. **One NOTE can spawn many** — A single NOTE might spawn 3 TASKs, 1 REFE, and an ADR. Or it might spawn nothing but still get archived.

4. **Archive after processing** — Once all useful artifacts have been spawned, update `status: processed`, add `spawned:` links, and move to `archive/`.

#### Processed NOTE Example

```yaml
---
type: note
status: processed
created: 2026-01-15
spawned:
  - "[[TASK-0012]]"
  - "[[TASK-0013]]"
  - "[[REFE-0005]]"
---

# Original Note Title

[Original content preserved...]
```

Notes are intentionally lightweight. Don't over-structure them — the point is to capture thoughts quickly and refine later.

---

## File Naming Convention

```
TYPE-NNNN_kebab-case-description.md
```

### Type Prefixes

| Prefix | Type |
|--------|------|
| `TASK` | Task |
| `EPIC` | Epic |
| `ADR` | Architecture Decision Record |
| `REFE` | Reference |
| `RESO` | Resource |
| `NOTE` | Note |

### ID Assignment

- IDs are 4-digit, zero-padded: `0001`, `0002`, etc.
- IDs are globally unique per type (not per directory)
- Archived files keep their original ID
- IDs provide stable references even if title changes

### Benefits

- Files sort by type, then by ID
- Type visible in file listings without opening
- Globally unique, easy to reference
- IDs remain stable even if description changes
- Grep-friendly for finding references

---

## Directory Organization

```
board/
├── tasks/           # Actionable work items (TASK-*)
├── planning/        # Epics, ADRs, and notes (EPIC-*, ADR-*, NOTE-*)
├── reference/       # Evergreen knowledge base (REFE-*)
├── resources/       # External material inbox (RESO-*)
└── archive/         # Completed/processed items
```

| Type | Directory |
|------|-----------|
| TASK | `tasks/` |
| EPIC | `planning/` |
| ADR | `planning/` |
| NOTE | `planning/` |
| REFE | `reference/` |
| RESO | `resources/` |

**Never put:**
- Reference docs in `planning/` (they're evergreen, not plans)
- Epics in `tasks/` (they're not individually actionable)
- ADRs in `reference/` (they're project-specific history, not general knowledge)
- Completed items in active directories (archive them)

---

## Writing Guidelines

### Task Titles: Imperative Mood

Task titles MUST use imperative mood (action-oriented language). Start with a verb that describes what will be done.

| Bad (noun/passive) | Good (imperative) |
|-------------------|-------------------|
| `User Authentication` | `Add user authentication` |
| `PNG Compression` | `Optimize PNG compression` |
| `Performance Tuning` | `Benchmark database performance` |
| `Bug in Login` | `Fix login authentication bug` |

The filename should match the title in kebab-case:
- Title: "Add user authentication"
- Filename: `TASK-0001_add-user-authentication.md`

### Reference Docs: Pure Reference Only

Reference documents (REFE) must contain only reference material:
- Technical specifications
- Configuration options
- API documentation
- External links and resources

**Reference docs must NOT contain:**
- Actionable items or TODOs
- Implementation steps
- Task lists or checklists
- Status tracking

If a reference doc has actionable items, extract them into separate TASK files.

### REFE vs ADR: Key Distinction

| REFE (Reference) | ADR (Decision Record) |
|------------------|----------------------|
| What things ARE | What WE DID/DECIDED |
| Objective, encyclopedic | Subjective to this project |
| Evergreen, keep current | Immutable, never edited |
| No project decisions | Documents our choices |

---

## Archiving

When a task is `done`, resource is `processed`, or note is `processed`:

1. Update `status` field
2. Move file to `board/archive/` subdirectory
3. Queries automatically exclude archived items (different path)

Archived items remain searchable and linkable.

**ADRs are NOT archived** — they stay in `board/planning/` regardless of status since they are immutable historical records that should remain easily discoverable.

---

## Validation

Required fields by type:

| Type | Required Fields |
|------|-----------------|
| task | type, status, created |
| epic | type, status, created |
| adr | type, status, context_date, created (spawned items in body) |
| reference | type, created |
| resource | type, status, url, created |
| note | type, status, created (spawned when processed) |

---

## Setup

To use this system in a new project:

1. Create the directory structure:
   ```bash
   mkdir -p board/{tasks,planning,reference,resources,archive}
   ```

2. Copy the framework docs into `board/reference/`:
   - `REFE-0001_board-system-spec.md` (this file)
   - `REFE-0002_board-system-quickref.md`

3. Reference the quickref from your project's `CLAUDE.md`:
   ```markdown
   ## Project Board
   @board/reference/REFE-0002_board-system-quickref.md
   ```
