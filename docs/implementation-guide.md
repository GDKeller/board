# Board System — Implementation Guide

This covers tooling-specific setup for the board system. For the framework itself, see `plugin/spec/board-system-spec.md`.

---

## Installing in a New Project

### 1. Create Directory Structure

```bash
mkdir -p board/{tasks,planning,reference,resources,archive}
```

### 2. Add to CLAUDE.md

Add the following to your project's `CLAUDE.md`:

```markdown
## Project Board

This project uses a structured board system for project management. **Ask before creating new board files.**
```

Projects start REFE numbering at 0001.

### 3. (Optional) Install Claude Skills

Copy the `board-*` skills into your Claude Code skills directory to enable slash commands:
- `/board:add` — Create new board items
- `/board:show` — View board overview
- `/board:check` — Look up relevant board context
- `/board:update` — Reconcile board with codebase
- `/board:archive` — Archive completed items

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
     "http://127.0.0.1:27123/vault/tasks/TASK-0002.md"
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

1. **Manual** — Check highest existing ID for that type across all directories (including `board/archive/`)
2. **Script** — `./scripts/next-doc-id.sh TASK` outputs next available
3. **Tracking file** (optional):

```
board/.doc-ids
TASK=3
REFE=2
RESO=2
NOTE=1
```

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

To migrate existing documentation into the board system:

1. Add frontmatter to existing files
2. Rename with `TYPE-NNNN` prefix
3. Move to appropriate directory under `board/`
4. Update any internal links
5. Set up vault symlink (if using Obsidian)
