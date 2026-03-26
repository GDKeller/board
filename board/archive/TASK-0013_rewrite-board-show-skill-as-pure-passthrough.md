---
type: task
status: done
priority: 2
blocked_by: TASK-0012
parent: EPIC-0001
created: 2026-03-26
---

# TASK-0013: Rewrite board-show skill as pure passthrough

## Description

Rewrite the `/board:board-show` skill (`plugin/skills/show/SKILL.md`) to be a pure passthrough of `board-show.sh` output. The LLM should display pre-formatted output verbatim with zero reasoning, zero additional shell commands, and zero permission prompts.

## Context

See NOTE-0003 for full analysis. Depends on TASK-0012 (the script must exist first).

## Changes Required

1. Replace the current TSV injection + formatting instructions with a single `board-show.sh` invocation
2. Skill prompt should say: "Display the above output to the user exactly as-is. Do not modify, reformat, or run any additional commands."
3. Remove the example formatting template (the script handles this now)
4. Keep the `--active` vs full board flag passthrough if applicable
