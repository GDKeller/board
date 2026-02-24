---
type: epic
status: current
priority: 1
created: 2026-02-24
---

# EPIC-0001: Harden BoardPM from system review

## Objective

Address all findings from the six-agent system review conducted on 2026-02-24. The review covered architecture, script quality, spec consistency, skill/UX design, board file validation, and silent failure analysis.

## Scope

Three phases of work, ordered by impact-to-effort ratio:

1. **Phase 1 — Quick wins** (TASK-0001 through TASK-0004): One-line or near-one-line fixes for the most impactful reliability issues.
2. **Phase 2 — Correctness** (TASK-0005 through TASK-0008): Moderate-effort fixes for parsing bugs, race conditions, and validation gaps.
3. **Phase 3 — Documentation & polish** (TASK-0009 through TASK-0011): Spec sync, example board improvements, and skill UX refinements.

## Success Criteria

- All scripts exit non-zero on genuine errors (no silent success on missing board)
- All script invocations pass explicit `./board` path
- `next-id.sh` atomically claims IDs via `.doc-ids` writeback
- `board-scan.sh` parsing is correct for frontmatter boundaries and value trimming
- `board-lint.sh` validates all cross-reference types (`parent`, `spawned`, not just `blocked_by`)
- Spec, quickref, and implementation guide are fully in sync
- Example board demonstrates the system's capabilities
