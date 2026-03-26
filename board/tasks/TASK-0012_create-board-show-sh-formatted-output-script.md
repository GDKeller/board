---
type: task
status: done
priority: 2
parent: EPIC-0001
created: 2026-03-26
---

# TASK-0012: Create board-show.sh formatted output script

## Description

Create a new `board-show.sh` script (or add a `--formatted` flag to `board-scan.sh`) that outputs a complete, pre-formatted board view as markdown. This eliminates LLM reasoning from `/board-show` by moving all presentation logic into a deterministic script.

## Context

See NOTE-0003 for full analysis. Currently `/board-show` injects raw TSV via `board-scan.sh` and delegates formatting to the LLM. This causes the LLM to "think" about layout and sometimes run ad-hoc shell commands with `$()` substitution, triggering Claude Code permission prompts.

## Requirements

The script must handle:
- Grouping tasks by epic parent
- Sorting by priority within groups
- Epic progress (child task counts by status)
- Blocked detection (items with unresolved `blocked_by`)
- Archive summary stats
- Standalone/orphan task section
- Output as clean markdown matching the current board-show format

## Constraints

- Bash 3.2+ compatible (no associative arrays, no `readarray`)
- Use `set -euo pipefail`
- Accept board root as first argument
- Exit with error if board directory doesn't exist
