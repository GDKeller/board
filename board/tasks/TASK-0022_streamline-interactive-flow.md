---
type: task
status: backlog
priority: 1
parent: EPIC-0002
created: 2026-03-26
---

# TASK-0022: Streamline interactive flow and reduce blocking prompts

The current flow has 3 sequential blocking prompts before any work begins. The `board-update` skill achieves a similar plan-then-execute flow with a single approval gate.

## Requirements

- **Remove upfront directory prompt (H3):** Scan defaults (root `*.md`, `docs/` recursive) plus any path in `$ARGUMENTS`. In the discovery results, note: "If there are files in other locations you'd like to include, tell me and I'll re-scan." This converts the upfront gate to an inline escape hatch.
- **Remove >15 files confirmation:** Let the user trim scope in the plan review step instead of a separate gate.
- **Result: single approval gate** — discovery → classification → plan presentation → user approves/adjusts → execute.
- **Progressive read strategy (M10):** Read with `limit: 30` first for classification. Only full-read if classification is ambiguous. If >10 candidates, process in batches of 5.

## Findings addressed

- H3, M10 from [[NOTE-0004]]
