---
type: note
status: processed
created: 2026-02-24
spawned:
  - "[[EPIC-0001]]"
  - "[[TASK-0001]]"
  - "[[TASK-0002]]"
  - "[[TASK-0003]]"
  - "[[TASK-0004]]"
  - "[[TASK-0005]]"
  - "[[TASK-0006]]"
  - "[[TASK-0007]]"
  - "[[TASK-0008]]"
  - "[[TASK-0009]]"
  - "[[TASK-0010]]"
  - "[[TASK-0011]]"
---

# NOTE-0001: System review findings

## Context

Six specialized agents reviewed the BoardPM system in parallel on 2026-02-24:

| Agent | Focus | Key Findings |
|-------|-------|--------------|
| Architect | System design & data flow | 8 strengths, 8 weaknesses |
| Code Reviewer | Script bugs & bash 3.2 compat | 8 issues |
| Spec Analyst | Documentation consistency | 20 findings (3 critical) |
| UX Explorer | Skill prompt quality | 15 issues across 7 skills + hook |
| Board Validator | Example board files | 2 violations, 3 observations |
| Silent Failure Hunter | Error handling & race conditions | 19 issues (4 critical) |

## Architecture Verdict

The system is well-designed. Core decisions are sound: scripts for determinism, LLM for judgment; dynamic `!` injection with `--active` bounding; derived state over stored state; git-native archiving. Weaknesses are implementation gaps, not design flaws.

## Critical Findings (Deduplicated)

1. **Missing `./board` argument** in 5 script invocations across skills and hook (flagged by 3 agents)
2. **Race condition in `next-id.sh`** — IDs not atomically claimed, `.doc-ids` never written back (flagged by 3 agents)
3. **Silent success on missing `board/`** — both scan and lint exit 0 with no real error (flagged by 2 agents)
4. **`archive-batch.sh` suppresses all error details** via `2>/dev/null` (flagged by 2 agents)
5. **`board-scan.sh` emits empty TSV rows** for malformed files (flagged by 2 agents)

## High-Priority Findings

- `board-lint.sh` `get_field` strips ALL spaces with `tr -d ' '`
- `board-lint.sh` `|| true` masks pipeline failures
- `board-scan.sh` frontmatter boundary detection matches `--- some text` incorrectly
- `board-scan.sh` value trimming only strips one trailing whitespace character
- `board-init.sh` doesn't check for path conflicts (file where directory expected)
- `archive-batch.sh` `cd` failure silently bypasses path traversal check
- `validate-status.sh` can't distinguish invalid FROM status from invalid transition
- Implementation guide references non-existent `next-doc-id.sh`
- Implementation guide `.doc-ids` example incomplete (4 of 6 types, wrong format)
- `board-lint.sh` treats `created` as WARN but spec says required (ERROR)
- Quick reference omits EPIC archiving rule
- Implementation guide omits `/board:board-edit` and `/board:board-lint` from skills list
- ADR body template absent from `/board:board-add`
- Non-git fallback missing for `git mv` in `/board:board-edit`
- `/board:board-update` sub-skill delegation ambiguous
- `/board:board-init` available commands list missing `/board:board-lint`
- `board-lint.sh` doesn't validate `parent` or `spawned` cross-references

## Strengths Worth Preserving

- Script/LLM boundary correctly drawn everywhere
- ADR immutability enforced at 4 layers (spec, lint, archive, edit)
- Progressive escalation in `/board:board-check` — best-designed skill
- `validate-status.sh` exit code convention (0/1/2) is clean API design
- `board-init.sh` idempotency — safe to re-run
- Context budget management via `--active`, `--archive-summary`, 50-line parse limit
- Guiding Principles section provides durable "why" documentation
