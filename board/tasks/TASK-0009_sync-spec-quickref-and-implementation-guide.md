---
type: task
status: backlog
priority: 3
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0009: Sync spec, quickref, and implementation guide

## Description

The spec consistency review found multiple discrepancies between the full spec, quick reference, CLAUDE.md, and implementation guide. These need to be reconciled.

## Changes Required

### Quick reference (`plugin/spec/board-system-quickref.md`)

1. **Add EPIC archiving rule** to the Archiving section — "Epics with `status: done` → move to board/archive/"
2. **Clarify "Required Frontmatter" section** — rename to "Frontmatter Templates" or add note that fields beyond `type`, `status`, and `created` are optional
3. **Add prefix-to-type mapping note** — clarify that frontmatter `type` uses the full word (`reference`, `resource`), not the filename prefix abbreviation (`REFE`, `RESO`)

### Full spec (`plugin/spec/board-system-spec.md`)

4. **Add EPIC to archiving section** (line ~510) — "When a task is `done`, epic is `done`, resource is `processed`, or note is `processed`"
5. **Add explicit REFE archiving policy** — "Reference docs are not archived; they are evergreen and should be kept current or deleted if obsolete"
6. **Reword Guiding Principle #6** — "Minimal status values per type (2-3 each)" instead of selectively citing TASKs and ADRs
7. **Remove or update minimal Setup section** (lines 593-607) — point to implementation guide or `/board:board-init`

### CLAUDE.md

8. **Ensure REFE archiving "No" is consistent** with new explicit spec statement

### Implementation guide (`docs/implementation-guide.md`)

9. Covered by TASK-0004 (separate task since it's a quick fix)
