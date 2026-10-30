# BoardPM

> A plain-text project management framework for human–AI collaboration, distributed as a Claude Code plugin.

BoardPM is a structured system of Markdown files with YAML frontmatter for task tracking, decision records, and knowledge management. Humans and AI agents (Claude Code in particular) read and modify the same source of truth — no UI, no database, no API. Just plain text in git.

## Why

Most PM tools optimize for humans (kanban boards) or machines (databases), but not both. BoardPM is built around a different goal: **the artifacts themselves are the system**. Tasks, decisions, and notes live as version-controlled files, so:

- An AI agent can read the entire project state from `git ls-files board/`
- A human reads the same files in any editor or markdown viewer
- History, blame, and diff "just work" because it's plain text
- Discipline is enforced by *structure* — naming conventions, lint rules, write-once artifacts — not by trust

## What you get

- 9 slash commands for board operations (`/board:board-init`, `/board:board-show`, `/board:board-add`, `/board:board-edit`, `/board:board-check`, `/board:board-update`, `/board:board-archive`, `/board:board-lint`, `/board:board-migrate`)
- A `SessionStart` hook that lints the board on every Claude Code session, silent when the board is clean
- Deterministic bash scripts for ID assignment, status validation, archiving, and formatted output (bash 3.2+ compatible — works on stock macOS)
- A complete system spec ([`plugin/spec/board-system-spec.md`](plugin/spec/board-system-spec.md)) and a [quick reference](plugin/spec/board-system-quickref.md)

## Requirements

- Claude Code 2.1 or newer (plugins, skills, and hooks)
- bash 3.2 or newer (stock macOS works, no Homebrew bash needed)
- git is optional. Archiving uses `git mv` for tracked files and falls back to plain `mv`.

## Install

The plugin is published through the [`gdkeller` marketplace](https://github.com/GDKeller/claude-marketplace). From inside Claude Code:

```
/plugin marketplace add GDKeller/claude-marketplace
/plugin install board@gdkeller
```

To try it from a local checkout without installing:

```
claude --plugin-dir ./plugin
```

Then, from any project root:

```
/board:board-init
```

This scaffolds `board/{tasks,planning,reference,resources,archive}/`, creates an ID tracker, and appends a board section to your `CLAUDE.md`. From then on the plugin's `SessionStart` hook lints the board at the start of every session. It stays silent when everything is valid, and in projects that have no board at all.

## A typical session

```
/board:board-add task Add rate limiting to the upload endpoint
/board:board-check upload                  # related tasks, ADRs, and references
/board:board-edit TASK-0012 status current
/board:board-update                        # reconcile the board with git history after coding
/board:board-archive                       # move done items to board/archive/
```

`/board:board-show` prints the board as Markdown.

## Document types

| Type | Purpose | Statuses | Archived? |
|---|---|---|---|
| TASK | Actionable work | `backlog` → `current` → `done` | Yes |
| EPIC | Container for related tasks | `planning` → `current` → `done` | Yes |
| ADR  | Architecture Decision Record | `active`, `superseded`, `deprecated` | **Never** |
| REFE | Reference / evergreen knowledge | _(none)_ | No |
| RESO | External resource inbox | `inbox` → `processing` → `processed` | Yes |
| NOTE | Unrefined thoughts to be processed | `inbox` → `processed` | Yes |

## Anatomy of a board item

Files use the naming convention `TYPE-NNNN_kebab-case-title.md` and start with YAML frontmatter:

```yaml
---
type: task
status: backlog
priority: 2
created: 2026-04-17
blocked_by: [TASK-0005]
parent: EPIC-0001
---

# TASK-0012: Add rate limiting to the upload endpoint

## Description
Unauthenticated clients can hammer `/upload`. Add a token bucket per client IP…
```

IDs are 4-digit zero-padded and globally unique per type. Archived files keep their original ID. Reference fields (`blocked_by`, `parent`, `spawned`) hold bare IDs. `[[Wikilinks]]` belong in body text, where editors like Obsidian resolve them.

## Design principles

A few axioms from the [spec](plugin/spec/board-system-spec.md):

- **ADRs are immutable.** Never edited after creation; supersede with a new ADR.
- **`blocked_by` is informational only.** No separate "blocked" status — actionability is *derived*, not stored.
- **NOTEs spawn, never convert.** Processing a NOTE creates new artifacts; the NOTE itself gets archived as a historical record.
- **Scripts over LLM for deterministic ops.** ID assignment, status validation, and linting run as bash — the LLM sees their output, not their source. This shrinks context and removes a hallucination surface.
- **Dynamic context injection.** Skills use the `` !`command` `` activation syntax to inject *fresh* board state at every invocation, so prompts never carry stale caches.

## Project layout

```
plugin/                           # The Claude Code plugin (served by GDKeller/claude-marketplace)
├── .claude-plugin/plugin.json
├── skills/                       # 9 skills (board-add, board-show, board-edit, …)
├── scripts/                      # Bash helpers (bash 3.2 compatible)
├── hooks/hooks.json              # SessionStart auto-lint
├── spec/                         # System spec + quick reference
└── templates/                    # CLAUDE.md snippet for /board:board-init
board/                            # The example board — also self-manages this repo
docs/                             # Implementation guide: setup, ID tracking, migration, Obsidian
```

## Self-management

This repo dogfoods its own system. Browse [`board/`](board/) to see real tasks, ADRs, NOTEs, and archived work — the plugin that ships here is what tracks its own development.

## Development

```bash
bash plugin/scripts/board-lint.sh ./board     # Validate all board files
bash plugin/scripts/board-show.sh ./board     # Formatted board overview
bash plugin/scripts/board-scan.sh ./board --active   # TSV of active items
```

Scripts are bash 3.2+ compatible (no `declare -A`, no `mapfile`, no `${var,,}`) and all use `set -euo pipefail`.

## Status

`v0.1.0` — actively dogfooded, public preview.
