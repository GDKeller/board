# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

BoardPM is a plain-text project management framework for human-AI collaboration. It defines a structured system of Markdown files with YAML frontmatter for task tracking, decision records, and knowledge management. This is a **boilerplate/template repository** — not a software application. It is designed to be copied into other projects or installed globally via `~/.claude`.

## Repository Structure

```
plugin/                       # Claude Code plugin (primary distribution)
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/
│   └── init.md              # /board:init — scaffold board into a project
├── skills/                  # 7 plugin skills (use scripts for efficiency)
│   ├── add/                 # /board:add — create new board items
│   ├── show/                # /board:show — display board overview
│   ├── check/               # /board:check — search for relevant context
│   ├── edit/                # /board:edit — modify existing board items
│   ├── update/              # /board:update — reconcile board with codebase
│   ├── archive/             # /board:archive — archive completed items
│   └── lint/                # /board:lint — validate board file health
├── scripts/                 # Bash helpers (save context vs Glob/Grep)
│   ├── board-scan.sh        # Parse all board files to TSV
│   ├── board-init.sh        # Scaffold board directories + templates
│   ├── board-lint.sh        # Validate board files for errors
│   ├── next-id.sh           # Determine next available ID per type
│   ├── validate-status.sh   # Validate status transitions
│   └── archive-batch.sh     # Batch git mv to archive
├── hooks/
│   └── hooks.json           # SessionStart hook → auto-lint
├── spec/                    # System spec (plugin-internal, not board items)
│   ├── board-system-spec.md
│   └── board-system-quickref.md
└── templates/               # Board template files for init
    └── claude-md-snippet.md

board/                       # Example board (also used for self-management)
├── tasks/                   # TASK-* files (actionable work items)
├── planning/                # EPIC-*, ADR-*, NOTE-* files
├── reference/               # REFE-* files (evergreen knowledge)
├── resources/               # RESO-* files (external material inbox)
└── archive/                 # Completed items (ADRs never archived)

docs/                        # Documentation
└── implementation-guide.md  # Setup instructions for installing in projects
```

## Key Specifications

The authoritative system spec lives at `plugin/spec/board-system-spec.md`. The quick reference is at `plugin/spec/board-system-quickref.md`. Always consult these when making changes to the framework.

### File Naming Convention

```
TYPE-NNNN_kebab-case-description.md
```

IDs are 4-digit zero-padded, globally unique per type (not per directory). Archived files keep their original ID.

### Document Types & Lifecycles

| Type | Statuses | Directory | Archive? |
|------|----------|-----------|----------|
| TASK | `backlog` → `current` → `done` | `tasks/` | Yes |
| EPIC | `planning` → `current` → `done` | `planning/` | Yes |
| ADR | `active` / `superseded` / `deprecated` | `planning/` | **Never** |
| REFE | _(none)_ | `reference/` | No |
| RESO | `inbox` → `processing` → `processed` | `resources/` | Yes |
| NOTE | `inbox` → `processed` | `planning/` | Yes |

### Critical Design Rules

- **Task titles use imperative mood** — verb-first ("Add user auth", not "User Auth")
- **ADRs are immutable** — never edited after creation; create a new ADR to supersede
- **ADRs are never archived** — they stay in `planning/` permanently
- **`blocked_by` is informational only** — no separate "blocked" status; actionability is derived
- **NOTEs spawn, never convert** — processing a NOTE creates new artifacts; the NOTE itself gets archived
- **ADRs must have a "Spawned Items" section** — with explicit TASK/REFE links or "No follow-up needed"
- **"Decide X" tasks always produce an ADR**

### Next ID Assignment

Scan both `board/` and `board/archive/` for the highest existing ID of each type. If a `.doc-ids` tracking file exists in `board/`, use and update it.

## Working on This Repository

This repo has no build system, tests, or linter — it's pure Markdown/YAML files. Changes involve editing document content, skill definitions, scripts, or the system specification itself.

When modifying the board system spec (`plugin/spec/board-system-spec.md`) or quick reference (`plugin/spec/board-system-quickref.md`), ensure they stay in sync. The quick reference is a condensed version of the spec — not a separate document with independent rules.

### Scripts

All scripts in `plugin/scripts/` are bash 3.2+ compatible (macOS default). They use `set -euo pipefail` and avoid bash 4+ features (no associative arrays, no `declare -A`).

Example invocations from the repo root:

```bash
bash plugin/scripts/board-scan.sh ./board --active          # TSV of active items
bash plugin/scripts/board-scan.sh ./board --archive-summary  # Archive counts
bash plugin/scripts/board-lint.sh ./board                    # Validate all files
bash plugin/scripts/next-id.sh TASK ./board                  # Next TASK ID
bash plugin/scripts/validate-status.sh task backlog current  # Check transition
bash plugin/scripts/archive-batch.sh ./board board/tasks/TASK-0001_example.md
```

### Plugin Design Patterns

- **Dynamic context injection**: Skills use `` !`command` `` syntax to run `board-scan.sh` at activation time, injecting fresh board data without stale caches
- **TSV output format**: `board-scan.sh` outputs tab-separated data with a header row — compact and self-documenting
- **`--active` flag**: Excludes `board/archive/` to keep injected context proportional to active work. Critical for scaling — at 50+ active items, injection approaches context budget limits
- **Progressive escalation**: Skills filter by title (free) → Read with limit:15 (low cost) → full read (moderate) to minimize context consumption
- **Scripts over LLM generation**: Deterministic operations (ID assignment, status validation, linting) run as bash scripts whose output enters context — the script source never does

### Gotchas

- **Plugin cache copy**: Claude Code copies plugins to a cache directory. Paths that traverse outside the plugin root (`../`) will not resolve after installation. Always use `${CLAUDE_PLUGIN_ROOT}` for script references.
- **Bash 3.2 constraint**: macOS ships bash 3.2 by default. No associative arrays (`declare -A`), no `readarray`/`mapfile`, no `${var,,}` lowercase syntax.
- **Spec sync obligation**: `plugin/spec/board-system-spec.md` (full spec) and `plugin/spec/board-system-quickref.md` (quick ref) must stay in sync. The quick ref is a condensed derivative, not an independent document.
