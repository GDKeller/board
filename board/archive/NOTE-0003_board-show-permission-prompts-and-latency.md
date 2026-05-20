---
type: note
status: processed
created: 2026-03-25
---

# Board-show permission prompts and latency

## Observations

### 1. Command substitution triggers permission prompts

When running `/board-show` in a project, the `for` loop with `$()` substitution (e.g., `$(basename $f)`) triggers Claude Code's "Command contains $() command substitution" approval prompt. This forces the user to manually approve each shell command instead of executing seamlessly.

Example prompt seen:

```
for f in <project-root>/board/planning/*.md; do echo "===FILE: $(basename $f)==="; head -30
"$f"; echo; done
Read frontmatter from all planning files

Command contains $() command substitution
```

### 2. Unexpected "thinking" delay

User expected `/board-show` to immediately invoke shell scripts and display output without agent deliberation. Instead, the skill appeared to "think" before executing, adding latency and suggesting the LLM is reasoning about what to do rather than directly running the scripts.

## Root Cause Analysis

The skill (`plugin/skills/show/SKILL.md`) is hybrid — half deterministic, half LLM-dependent:

1. **Data injection works correctly.** The `!` backtick syntax runs `board-scan.sh --active` and `--archive-summary` at activation time. The TSV data is injected into the prompt before the LLM sees it. The scripts themselves only use `$((...))` for arithmetic — no command substitution that would trigger permission prompts.

2. **Presentation is delegated to the LLM.** The skill says "Parse the board data above and display the board in this format" with an example template. This forces the LLM to:
   - **Think** about how to format the output (the "thinking delay")
   - Potentially run its own shell commands to resolve relationships not obvious from the TSV (e.g., counting epic children, verifying blocker status) — this is where the `for f in ... $(basename $f)` commands originate

3. **The `for` loop is LLM-generated, not from our scripts.** The LLM decides on its own to read planning files to gather data it feels is missing or needs verification. These ad-hoc commands use `$()` substitution, which triggers Claude Code's safety prompt.

### Why the TSV isn't enough for the LLM

The TSV includes `blocked_by`, `parent`, `status`, and `priority` — theoretically everything needed. But the LLM still runs extra commands because:
- Counting epic children requires cross-referencing `parent` fields across rows — doable from TSV but the LLM isn't confident
- The formatting template is an *example*, not a rigid spec — the LLM treats it as guidance rather than a strict contract
- `disable-model-invocation: true` prevents the skill from being auto-triggered, but does NOT prevent the LLM from reasoning or running tools once activated

## Goal

`/board-show` should be **100% deterministic** — the LLM should act as a pure passthrough, displaying pre-formatted output with zero reasoning, zero additional shell commands, and zero permission prompts.

## Proposed Fix Direction

### Option A: Fully scripted output (preferred)
Add a `--formatted` flag to `board-scan.sh` (or create a new `board-show.sh` script) that outputs the complete formatted board view as markdown. The skill prompt becomes:

```
!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-show.sh ./board`

Display the above output to the user exactly as-is. Do not modify, reformat, or run any additional commands.
```

This eliminates all LLM reasoning — the script handles sorting, grouping, epic child counts, blocked detection, and archive stats.

### Option B: Stronger prompt constraints (weaker)
Keep the current TSV injection but rewrite the skill instructions to be extremely prescriptive ("output EXACTLY this, do NOT run any commands"). This is fragile — LLMs don't reliably follow "don't think" instructions.

## Potential TASKs to spawn

- Create `board-show.sh` script that outputs fully formatted board markdown (sorting, grouping, epic progress, blocked detection, archive stats)
- Rewrite `/board-show` skill to be a pure passthrough of script output
- Consider whether other skills (`/board-check`, `/board-update`) have similar hybrid issues

## Spawned Items

- **TASK-0012**: Create board-show.sh formatted output script
- **TASK-0013**: Rewrite board-show skill as pure passthrough (blocked by TASK-0012)
- **TASK-0014**: Audit other skills for hybrid determinism issues
