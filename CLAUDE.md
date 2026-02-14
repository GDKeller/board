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
└── templates/               # Board template files for init
    ├── REFE-0001_board-system-spec.md
    ├── REFE-0002_board-system-quickref.md
    └── claude-md-snippet.md

standalone/                  # Standalone skills (no plugin dependency)
└── skills/                  # Same 7 skills, using Glob/Grep instead of scripts
    ├── board-add/
    ├── board-show/
    ├── board-check/
    ├── board-edit/
    ├── board-update/
    ├── board-archive/
    └── board-lint/

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

The authoritative system spec lives at `board/reference/REFE-0001_board-system-spec.md`. The quick reference is at `board/reference/REFE-0002_board-system-quickref.md`. Always consult these when making changes to the framework.

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

When modifying the board system spec (`REFE-0001`) or quick reference (`REFE-0002`), ensure they stay in sync. The quick reference is a condensed version of the spec — not a separate document with independent rules.

### Plugin vs Standalone Skills

The **plugin** (`plugin/`) is the primary distribution. Its skills reference `${CLAUDE_PLUGIN_ROOT}/scripts/` for efficient operation (single Bash call instead of multiple Glob/Grep/Read calls).

The **standalone skills** (`standalone/skills/`) are a fallback for users who copy skills directly into `~/.claude/skills/` without installing the plugin. They use Glob/Grep/Read instead of scripts. When modifying a skill, update both versions to stay in sync.

### Scripts

All scripts in `plugin/scripts/` are bash 3.2+ compatible (macOS default). They use `set -euo pipefail` and avoid bash 4+ features (no associative arrays, no `declare -A`).
