---
type: note
status: inbox
created: 2026-03-26
---

# NOTE-0005: Skills reference spec path but don't ensure it gets read

## Observation

All skills mention `${CLAUDE_PLUGIN_ROOT}/spec/board-system-spec.md` in their descriptions, but none force Claude to actually read it. When Claude needs spec details (e.g., REFE vs RESO distinction), it searches the working directory instead of reading from the plugin root.

Observed in a session where Claude couldn't find the spec and had to ask the user for the REFE/RESO distinction.

## Possible Directions

- Inject quickref content directly into skills via `` !`cat ${CLAUDE_PLUGIN_ROOT}/spec/board-system-quickref.md` ``
- Add an explicit "Read the spec first" instruction as a required first step in relevant skills
- Inline the most critical distinctions (type definitions, lifecycles) into each skill that needs them
