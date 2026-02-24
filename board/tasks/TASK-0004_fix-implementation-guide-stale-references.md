---
type: task
status: backlog
priority: 1
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0004: Fix implementation guide stale references

## Description

The implementation guide (`docs/implementation-guide.md`) has several stale or incomplete references identified by the spec consistency review.

## Changes Required

1. **Line 235**: Change `./scripts/next-doc-id.sh TASK` to `bash plugin/scripts/next-id.sh TASK ./board` (script name is wrong)
2. **Lines 237-243**: Update `.doc-ids` example to show all 6 types with zero-padded format matching what `board-init.sh` produces
3. **Lines 28-35**: Add `/board:edit` and `/board:lint` to the skills list (currently only lists 5 of 7)
4. **Lines 19-22**: Either update the CLAUDE.md snippet example to match `plugin/templates/claude-md-snippet.md`, or reference the template file directly
