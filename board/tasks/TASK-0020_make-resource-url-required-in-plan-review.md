---
type: task
status: backlog
priority: 2
parent: EPIC-0002
created: 2026-03-26
---

# TASK-0020: Make resource URL required and surface during plan review

The spec marks `url` as required for resource frontmatter, but the skill treats it as optional ("ask if not evident"). Additionally, the URL prompt happens during execution (Step 6) rather than plan review (Step 5), meaning migration can stall mid-run.

## Requirements

- Strengthen the instruction: "Resources require `url` (required field). Do not create a resource without a URL."
- Move the URL prompt to the plan presentation step: "Item #N is classified as a resource — do you have a URL? (You can reclassify as a note if no URL is available.)"
- This surfaces the dependency before execution begins and provides an explicit escape path

## Findings addressed

- M3 from [[NOTE-0004]]
