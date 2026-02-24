---
type: task
status: backlog
priority: 1
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0001: Add missing ./board arguments to script invocations

## Description

Five script calls across skills and the hook omit the explicit `./board` board root argument, relying on the script default which breaks if CWD isn't the project root. This is the single most impactful reliability risk identified by the review.

## Changes Required

| File | Script | Current | Fix |
|------|--------|---------|-----|
| `plugin/skills/add/SKILL.md` | `next-id.sh` | `next-id.sh <TYPE>` | `next-id.sh <TYPE> ./board` |
| `plugin/skills/lint/SKILL.md` | `board-lint.sh` | `board-lint.sh` | `board-lint.sh ./board` |
| `plugin/hooks/hooks.json` | `board-lint.sh` | `board-lint.sh` | `board-lint.sh ./board` |
| `plugin/skills/archive/SKILL.md` | `archive-batch.sh` | `archive-batch.sh board` | `archive-batch.sh ./board` |
| `plugin/skills/update/SKILL.md` | `archive-batch.sh` | (same) | (same) |
