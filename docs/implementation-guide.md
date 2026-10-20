# Board System — Implementation Guide

This covers tooling-specific setup for the board system. For the framework itself, see `plugin/spec/board-system-spec.md`.

---

## Installing in a New Project

Install the plugin (see the [README](../README.md#install)), then run `/board:board-init` from the project root. It creates:

- `board/{tasks,planning,reference,resources,archive}/`, each with a `.gitkeep`
- `board/.doc-ids` (ID tracking file)
- A "Project Board" section appended to your `CLAUDE.md`, taken from `plugin/templates/claude-md-snippet.md`

Re-running init is safe. It only creates what is missing.

### Without the plugin

The board is plain files, so it also works by hand:

```bash
mkdir -p board/{tasks,planning,reference,resources,archive}
```

Then paste `plugin/templates/claude-md-snippet.md` into your `CLAUDE.md` and follow `plugin/spec/board-system-quickref.md` when writing items. You lose the skills, the session-start lint, and script-assigned IDs.

### Skills

| Skill | Purpose |
|-------|---------|
| `/board:board-init` | Scaffold the board into a project |
| `/board:board-show` | Formatted board overview |
| `/board:board-add` | Create new items with correct frontmatter and IDs |
| `/board:board-edit` | Change status, priority, blockers, titles, or type |
| `/board:board-check` | Read-only lookup of items relevant to current work |
| `/board:board-update` | Reconcile the board with git history and code state |
| `/board:board-archive` | Move done items to `board/archive/` |
| `/board:board-lint` | Validate board files and offer fixes |
| `/board:board-migrate` | Import existing Markdown docs into the board |

---

## Obsidian Integration

### Vault Setup (Symlink Approach)

Project docs live in the repo but appear in your main Obsidian vault via symlink:

```bash
# From your main vault directory
ln -s /path/to/project/board ./projects/project-name
```

**Benefits:**
- Docs are git-tracked in the project repo
- Searchable and linkable from main vault
- Can link between project docs and personal notes
- Single Obsidian window, no vault switching

**Structure in vault:**
```
your-vault/
├── personal/
├── work/
└── projects/
    └── my-project/    # ← symlink to project/board/
        ├── tasks/
        ├── reference/
        └── ...
```

### Multi-Project Vaults

If you symlink multiple projects into one Obsidian vault, filenames may collide (e.g., two projects both have `TASK-0001`). Options:

1. **Rely on folder context** — Obsidian shows the folder path, so `projects/app-a/tasks/TASK-0001` is distinguishable from `projects/app-b/tasks/TASK-0001`
2. **Add a project prefix** — Use `PROJ-TYPE-NNNN` naming (e.g., `APP-TASK-0001`) for global uniqueness. This is optional and only needed for multi-project vaults.

### Dataview vs Bases

This schema works with both:

**Dataview** — Query-based, more powerful, requires learning DQL
```dataview
TABLE status, priority FROM "projects/my-project/tasks"
WHERE status != "done"
SORT priority ASC
```

**Bases** — GUI-based, easier setup, native Obsidian feature (v1.5+)
- Create a Base, point it at `projects/my-project/tasks/`
- Frontmatter properties auto-detected
- Drag-and-drop kanban, table views, filters

Recommendation: Start with Bases for simplicity, use Dataview for complex queries.

### Recommended Plugins

| Plugin | Purpose |
|--------|---------|
| Dataview | Powerful queries and dynamic views |
| Templater | Templates for new TASK/RESO/etc files |
| Linter | Validate frontmatter on save |
| Local REST API | Programmatic access from external tools |

### Example Dataview Queries

Adjust paths based on your vault structure.

**Task Kanban:**
```dataview
TABLE WITHOUT ID
  file.link as Task,
  status,
  priority,
  due
FROM "board/tasks"
WHERE type = "task"
SORT choice(status = "current", 0, choice(status = "backlog", 1, 2)) ASC, priority ASC
```

**Resource Inbox:**
```dataview
TABLE WITHOUT ID
  file.link as Resource,
  source_type,
  created
FROM "board/resources"
WHERE status = "inbox" OR status = "processing"
SORT created DESC
```

**Unblocked Backlog Tasks:**
```dataview
TABLE WITHOUT ID
  file.link as Task,
  priority
FROM "board/tasks"
WHERE status = "backlog"
  AND (!blocked_by OR length(blocked_by) = 0)
SORT priority ASC
```

### Obsidian Templates

**Template: TASK**
```markdown
---
type: task
status: backlog
priority: 2
tags: []
created: {{date:YYYY-MM-DD}}
due:
blocked_by: []
parent:
---

# {{title}}

## Description

## Acceptance Criteria

## Notes
```

**Template: RESO**
```markdown
---
type: resource
status: inbox
url:
source_type:
tags: []
created: {{date:YYYY-MM-DD}}
processed:
spawned_tasks: []
---

# {{title}}

## Why Interesting

## Key Takeaways

## Relevant to This Project

## TODOs
- [ ]

## Tasks Created
```

---

## Programmatic Access

### Obsidian Local REST API

The [Local REST API plugin](https://github.com/coddingtonbear/obsidian-local-rest-api) provides HTTP access to vault contents AND Dataview query execution.

**Execute a Dataview query:**
```bash
curl -X POST \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/vnd.olrapi.dataview.dql+txt" \
     "http://127.0.0.1:27123/search/" \
     -d 'TABLE status, priority, blocked_by FROM "board/tasks" WHERE status = "backlog"'
```

**Get a single file with structured frontmatter:**
```bash
curl -H "Accept: application/vnd.olrapi.note+json" \
     -H "Authorization: Bearer $TOKEN" \
     "http://127.0.0.1:27123/vault/tasks/TASK-0002_example.md"
```

### Query Strategy

| Need | Approach |
|------|----------|
| All backlog tasks | Dataview query via `/search/` |
| Unblocked tasks only | Dataview query with `WHERE length(blocked_by) = 0` |
| Single task details | GET file with JSON accept header |
| Check blocker status | GET each blocker file, check `status` field |

### Fallback: Direct File Reads

If Obsidian isn't running, read files directly from `board/`. YAML frontmatter is simple to parse. The REST API is preferred for batch queries, but direct file access works fine — especially for Claude Code, which can read files natively.

---

## ID Tracking

To assign the next available ID, either:

1. **Script** — `bash plugin/scripts/next-id.sh TASK ./board` prints the next available ID (the skills do this for you)
2. **Manual** — Check the highest existing ID for that type across all directories, including `board/archive/`

The script also reads `board/.doc-ids` if present and takes the higher of the two. `board-init.sh` creates it with every type at zero:

```
TASK=0000
EPIC=0000
ADR=0000
REFE=0000
RESO=0000
NOTE=0000
```

Nothing writes it back yet, so it is a floor, not a ledger.

---

## Claude Code Workflow Guidelines

### Use Plan Mode for Significant Work

When working on tasks that involve:
- **Architectural changes** (new modules, restructuring)
- **Multi-file refactoring**
- **New features requiring design decisions**
- **Complex implementations** spanning multiple components

Claude Code SHOULD enter plan mode to:
1. Thoroughly explore the codebase
2. Understand existing patterns and dependencies
3. Design an informed implementation approach
4. Present the plan for user approval before executing

### When Plan Mode is NOT Needed

Skip plan mode for:
- Simple bug fixes with obvious solutions
- Single-file changes
- Documentation updates
- Small, well-defined tasks

### Task Planning

When creating TASKs that describe significant work:
- Use plan mode to analyze the codebase BEFORE writing detailed implementation steps
- Ground the task details in actual code analysis, not assumptions
- Reference specific files, line numbers, and functions

---

## Migrating Existing Docs

Run `/board:board-migrate [path]`. It discovers stray Markdown files (project root, `docs/`, and any path you pass), proposes a type and title for each, and after you approve the plan creates the board items and removes the originals.

By hand, the equivalent is:

1. Add frontmatter to each file
2. Rename with the `TYPE-NNNN_` prefix
3. Move it to the right directory under `board/`
4. Update any internal links
5. Set up the vault symlink (if using Obsidian)
