---
type: task
status: done
priority: 2
parent: EPIC-0002
created: 2026-03-26
---

# TASK-0024: Consolidate post-migration output and add recovery guidance

## Consolidate output (L7)

After execution, the skill currently presents four distinct outputs: migration summary, references to update, lint output, and follow-up prompts. This is overwhelming after an already long interaction.

**Fix:**
- Keep the summary + references in one block
- Reduce lint to a one-liner: "Board lint passed." or "N lint errors found — run `/board:board-lint` to fix."
- Only offer follow-up suggestions when something specific warrants them (e.g., only mention splitting if a multi-item file was actually flagged during classification)

## Empty-state messaging

If zero candidates found, expand beyond "report that and stop":
- Report that no untracked Markdown files were found in the scanned locations
- If the user provided a `[path]` argument, confirm it was scanned
- Suggest using `/board:board-add` to create new items directly

## Findings addressed

- L7, plus empty-state from UX review, plus recovery guidance from H4/M7 (execution details in TASK-0017)
