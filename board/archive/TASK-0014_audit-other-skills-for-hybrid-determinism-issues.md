---
type: task
status: done
priority: 3
parent: EPIC-0001
created: 2026-03-26
---

# TASK-0014: Audit other skills for hybrid determinism issues

## Description

Review `/board:board-check`, `/board:board-update`, and other skills for the same hybrid pattern found in `/board:board-show`: injecting raw data then asking the LLM to process/format it, which causes unnecessary reasoning, latency, and potential permission prompts.

## Context

See NOTE-0003 root cause analysis. The board-show issue is a symptom of a broader pattern where skills delegate deterministic work to the LLM instead of scripts.

## Scope

For each skill, determine:
1. Does it inject raw data and ask the LLM to format/process it?
2. Could a script handle the deterministic parts instead?
3. If so, file follow-up tasks for each skill that needs the same treatment

## Audit Results

### `/board:board-show` — FIXED (TASK-0012, TASK-0013)
- **Was hybrid**: Injected raw TSV, asked LLM to format into markdown board view.
- **Fix**: Created `board-show.sh` that outputs pre-formatted markdown. Skill is now a pure passthrough.

### `/board:board-check` — No action needed
- **Pattern**: Injects TSV, but the LLM's job is inherently non-deterministic — it must interpret the user's current work context, match keywords against board titles, and decide which items are relevant.
- **Why not scriptable**: The "filter by relevance to current work" step requires language understanding. A script can't decide if TASK-0005 is related to the code the user is editing.
- **Verdict**: Appropriately hybrid. The TSV injection is data input, not presentation — the LLM adds genuine value by interpreting relevance.

### `/board:board-update` — No action needed
- **Pattern**: Injects TSV + archive counts, then asks LLM to cross-reference with git log and codebase state.
- **Why not scriptable**: Detecting completed work requires understanding commit messages, reading task descriptions, and matching them — a language task. Suggesting new tasks from TODOs/FIXMEs also requires judgment.
- **Verdict**: Appropriately hybrid. The LLM is doing analysis, not formatting. No permission prompt risk since it's told to use specific commands (`git log --oneline`).

### `/board:board-edit` — No action needed
- **Pattern**: Injects TSV for item lookup, then applies targeted edits.
- **Why not scriptable**: The LLM needs to interpret user intent ("change status to current"), locate the right item, validate transitions, and apply edits. These are inherently LLM tasks.
- **Verdict**: Clean design. Uses `validate-status.sh` for the deterministic part (transition validation) and delegates only judgment calls to the LLM.

### `/board:board-add` — No action needed
- **Pattern**: Injects TSV for duplicate detection, uses `next-id.sh` for ID assignment.
- **Why not scriptable**: Duplicate detection requires fuzzy title matching. Scope assessment (is this a task or an epic?) requires understanding.
- **Verdict**: Clean design. Deterministic parts already scripted.

### `/board:board-archive` — No action needed
- **Pattern**: Injects TSV, filters for terminal-status items, uses `archive-batch.sh` for the move.
- **Minor note**: The filtering step (find items with done/processed status) is deterministic and could be a script flag, but the current approach is low-risk — the LLM just scans a small TSV for status values and lists them. No reasoning or extra commands needed.
- **Verdict**: Acceptable. Could add a `--archivable` flag to `board-scan.sh` as a minor optimization, but not worth a task — the current overhead is negligible.

### `/board:board-lint` — No action needed (minor note)
- **Pattern**: Injects `board-lint.sh` output, then LLM interprets errors and offers fixes. Also does LLM-only checks (imperative mood, ADR completeness).
- **Imperative mood check**: Genuinely requires LLM — ambiguous cases (e.g., "Testing infrastructure" vs. "Test infrastructure") need language understanding.
- **ADR "Spawned Items" check**: Structural presence check (`## Spawned Items` heading) is scriptable via grep and could move into `board-lint.sh` in future. Currently low-impact since the LLM doing it in-memory causes no harm.
- **Verdict**: Appropriately hybrid. The script handles all deterministic validation. The LLM adds value with language checks and interactive fix suggestions.

## Conclusion

Only `/board:board-show` had the hybrid determinism problem. All other skills either use the LLM for genuine language/judgment tasks or already delegate deterministic work to scripts. No follow-up tasks needed.
