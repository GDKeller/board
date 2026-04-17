---
type: note
status: inbox
created: 2026-04-10
---

# NOTE-0009: Add narrowly-scoped agents to the plugin for /board skills

Claude Code plugins support bundled agents (see https://code.claude.com/docs/en/plugins-reference#agents). We should explore adding one or more narrowly-scoped agents to the BoardPM plugin to improve accuracy and consistency of `/board:*` skill execution.

## Rationale

- Skills currently run in the main conversation context, which means board operations compete with unrelated context and inherit whatever tone/assumptions the main agent has drifted into.
- A narrowly-scoped agent (e.g., "board-curator") with a tight system prompt focused on board hygiene — imperative task titles, ADR immutability, correct directory placement, status transition rules — would likely produce more accurate and consistent results than freehand skill execution.
- Agents also isolate context, which helps keep board operations cheap and predictable.

## Open Questions

- One agent for all board operations, or specialized agents per skill (add, update, lint, archive)?
- Should the agent be invoked automatically by skills, or exposed as a user-invocable agent the user delegates to?
- How does bundling an agent interact with the existing skill/script architecture — does it replace any skill logic, or sit alongside it?
- What's the minimal tool surface an agent needs (Read/Write/Bash for scripts, plus Grep/Glob)?

## Next Steps (when processed)

- Review plugin agents reference documentation
- Prototype one agent (likely `board-curator` scoped to add/edit/update operations) and measure accuracy vs. current skill-only flow
- Decide on single-agent vs. multi-agent architecture
