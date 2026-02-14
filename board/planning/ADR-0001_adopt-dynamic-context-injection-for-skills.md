---
type: adr
status: active
context_date: 2026-02-14
created: 2026-02-14
---

# Adopt dynamic context injection for board skills

## Context

Board skills (show, check, edit, add, archive, update) all need board state data to operate. Previously, each skill instructed Claude to run `board-scan.sh` as its first step — a Bash tool call that consumed a full round-trip before Claude could begin processing.

Claude Code introduced the `!`command`` preprocessing syntax, which runs shell commands before the skill content reaches Claude. The output replaces the placeholder inline, so Claude receives actual data rather than instructions to fetch it.

The key tension: injecting data via `!` saves a tool-call round-trip per skill invocation, but the output goes into the context window every time — and `board-scan.sh` scans all files including archive, which grows unboundedly over a project's lifetime.

## Decision

Adopt `!` dynamic context injection for all board skills that need scan data, with two safeguards against context bloat:

1. **`--active` flag** on `board-scan.sh` — skips `board/archive/` directory entirely. Used by 6 of 7 skills since they only need active items.

2. **`--archive-summary` flag** — outputs per-type file counts (4-6 lines) instead of parsing every archived file. Used only by `show` and `update`, which need archive counts for stats.

No skill ever injects the full archive scan into context.

Additionally:
- The `update` skill was changed from delegating reads to `show`/`archive` (which each triggered their own `!` preprocessing) to being self-contained for reading with its own `!` injection, delegating only for write operations.
- A guard was added to `board-scan.sh` for missing `board/` directories, outputting a header + comment and exiting cleanly.

## Consequences

**Benefits:**
- Each skill invocation saves one Bash tool-call round-trip
- Data is guaranteed to be present — Claude cannot skip or forget the scan step
- Context cost is bounded: scales with active items only, not total project history
- `update` no longer produces 3 redundant copies of board data in context

**Tradeoffs:**
- `!` preprocessing always runs, even if Claude wouldn't have needed the data (acceptable since these skills always need it)
- Skills that are model-invocable (`check`, `update`) inject data every time Claude autonomously invokes them — mitigated by `--active` keeping output small, and a soft instruction in `check` to reuse previous results within a session
- `edit` uses `--active` scan and falls back to Glob on `board/archive/` if an item isn't found — rare case, acceptable extra step

**Risks:**
- `!` behavior on script failure (non-zero exit, stderr) is not fully documented — mitigated by the `board/` directory guard and `exit 0` on missing directory

## Spawned Items

No follow-up needed.
