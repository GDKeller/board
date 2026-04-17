---
type: task
status: done
priority: 2
parent: EPIC-0002
created: 2026-03-26
---

# TASK-0018: Add explicit frontmatter templates to board-migrate execution step

Step 6 describes what fields to set per type in prose but provides no YAML template blocks. The `board-add` skill provides explicit blocks for all six types. Without templates, the LLM must reconstruct correct frontmatter from memory, increasing risk of field omissions.

## Requirements

- Add inline YAML template blocks in Step 6 for all six types, matching the canonical forms in `board-system-quickref.md` and `board-add`
- Include all required fields per type (task needs `priority`, resource needs `url`, ADR needs `context_date`, etc.)

## Findings addressed

- M1 from [[NOTE-0004]]
