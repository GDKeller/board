---
type: task
status: done
priority: 1
parent: EPIC-0002
created: 2026-03-26
---

# TASK-0019: Enforce ADR structure and context_date inference for migrated ADRs

## context_date (H2)

ADRs are immutable. The skill currently defaults `context_date` to today, but for migrated files the decision was almost certainly made earlier. A wrong `context_date` cannot be corrected without creating a new ADR.

**Fix:** Change instruction to: "ADRs get `status: active` and `context_date` set to the decision date — infer from file content, git history (`git log --follow <file>`), or ask the user if unclear. Do NOT default to today."

## Body structure (M2)

The spec mandates ADR bodies include: Context, Considered Approaches, Decision, Consequences, and Spawned Items. `board-lint.sh` validates "Spawned Items" at minimum. Migrated ADRs whose source docs lack these sections will immediately fail lint.

**Fix:** Add a note in Step 6 for ADR migration: "ADR body must include the required sections. If the source file lacks them, scaffold the section headers and populate from available content. Always include `## Spawned Items` — use 'No follow-up needed' if nothing applies."

## Findings addressed

- H2, M2 from [[NOTE-0004]]
