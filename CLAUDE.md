# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

BoardPM is a plain-text project management framework for human-AI collaboration. It defines a structured system of Markdown files with YAML frontmatter for task tracking, decision records, and knowledge management. This is a **boilerplate/template repository** — not a software application. It is designed to be copied into other projects or installed globally via `~/.claude`.

## Repository Structure

```
board/                    # Core board system (the product)
├── tasks/               # TASK-* files (actionable work items)
├── planning/            # EPIC-*, ADR-*, NOTE-* files
├── reference/           # REFE-* files (evergreen knowledge)
├── resources/           # RESO-* files (external material inbox)
└── archive/             # Completed items (ADRs never archived)

claude/skills/           # Claude Code skills (slash commands)
├── board-add/           # /board:add — create new board items
├── board-show/          # /board:show — display board overview
├── board-check/         # /board:check — search for relevant context
├── board-update/        # /board:update — reconcile board with codebase
└── board-archive/       # /board:archive — archive completed items

implementation-guide.md  # Setup instructions for installing in projects
claude-md-snippet.md     # Template snippet for project CLAUDE.md files
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

This repo has no build system, tests, or linter — it's pure Markdown/YAML files. Changes involve editing document content, skill definitions, or the system specification itself.

When modifying the board system spec (`REFE-0001`) or quick reference (`REFE-0002`), ensure they stay in sync. The quick reference is a condensed version of the spec — not a separate document with independent rules.

When modifying skills in `claude/skills/`, each skill is a single `SKILL.md` file containing the skill's system prompt and instructions.
