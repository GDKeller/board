---
name: board-migrate
description: "Migrates existing Markdown files into the board system by discovering untracked docs, classifying them interactively, and moving them into the correct board directories with proper frontmatter and naming. Activates when the user asks to migrate, import, or onboard existing docs into the board, or via '/board:board-migrate'."
argument-hint: "[path]"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
disable-model-invocation: true
---

# Migrate Existing Docs to Board

Import existing Markdown files into the `board/` project management system. The system spec is bundled with the plugin at `${CLAUDE_PLUGIN_ROOT}/spec/board-system-spec.md`.

This skill handles the common scenario where a project already has scattered `.md` files — often AI-generated docs placed in the project root or `/docs/` — that should be organized into the board system.

## Pre-Loaded Board Data

Current board state (for duplicate/overlap detection):

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-scan.sh ./board --active`

## Steps

### 1. Confirm Board Exists

Verify `board/` directory exists with the expected subdirectories. If not, tell the user to run `/board:board-init` first and stop.

### 2. Discover Candidate Files

Start by scanning these default locations for `.md` files:

- Project root (`*.md` — non-recursive)
- `docs/` directory (recursive)

**Exclude** these files from candidates — they are never board items:

- `README.md`, `CHANGELOG.md`, `LICENSE.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`
- `CLAUDE.md` and any `.claude/**/*.md`
- Anything already inside `board/` or `board/archive/`
- `node_modules/`, `.git/`, `vendor/`, `dist/`, `build/`, `.next/`
- Any file already matching the `TYPE-NNNN_*.md` naming pattern

Then ask the user:

> "I'll scan the project root and `docs/` for Markdown files to migrate. Are there any additional directories I should include?"

If they provide paths, scan those recursively as well. If they say no, proceed with the defaults.

### 3. Present Discovery Results

List all candidate files found with their paths. If zero candidates found, report that and stop.

If there are many candidates (>15), ask the user if they want to proceed with all of them or narrow the scope.

### 4. Classify Each File

For each candidate file:

1. **Read the full file** — classification requires understanding the file's purpose, not just a preview. Files may be long-form and frontmatter-free.
2. **Strip any existing frontmatter** — existing YAML frontmatter is almost certainly not board-compatible. It will be discarded; its content may inform classification but will not be preserved as frontmatter. If the existing frontmatter contains useful context, fold it into the body content.
3. **Suggest a board type** based on content analysis using these heuristics:

| Signal | Suggested Type |
|--------|---------------|
| Actionable work: describes something to build, fix, or do; imperative language; TODO items | **task** |
| Groups of related work items; roadmap; phased plan; multiple deliverables | **epic** |
| Documents a decision already made; compares alternatives; has "we chose X because Y" | **adr** |
| Encyclopedic/reference material; explains how something works; API docs; architecture overview | **reference** |
| Primarily links to external URLs; article summaries; external material | **resource** |
| Rough notes; brainstorming; meeting notes; unstructured thoughts; investigation notes | **note** |

4. **Suggest a title** — derive from the file's `# heading` if present, otherwise from filename. For tasks, rewrite to imperative mood.

**Ambiguous cases:** If a file doesn't clearly fit one type, note the ambiguity and give your best suggestion with a brief reason. The user will confirm or override.

**Multi-item files:** If a single file contains what should clearly be multiple board items (e.g., a doc listing 5 separate tasks), flag this and suggest splitting. Do NOT auto-split — just note it in the plan for the user to decide.

### 5. Present Migration Plan

Present the full plan as a table for the user to review:

```
## Migration Plan

| # | Source File | → Type | Suggested Title | Target Path |
|---|------------|--------|-----------------|-------------|
| 1 | docs/auth-design.md | adr | Chose JWT for session management | board/planning/ADR-0003_chose-jwt-for-session-management.md |
| 2 | docs/api-endpoints.md | reference | API endpoint reference | board/reference/REFE-0004_api-endpoint-reference.md |
| 3 | TODO.md | epic | Implement user dashboard | board/planning/EPIC-0002_implement-user-dashboard.md |
| 4 | docs/meeting-notes.md | note | Sprint 3 planning notes | board/planning/NOTE-0003_sprint-3-planning-notes.md |
| 5 | docs/redis-article.md | resource | Redis caching patterns article | board/resources/RESO-0001_redis-caching-patterns-article.md |

### Notes
- #3: Contains 4 sub-items that could be individual TASKs under this EPIC
- #5: Needs a URL — will ask during migration
```

Then ask the user:

> "Review the plan above. For each item you can:
> - **Accept** as-is
> - **Reclassify** (e.g., '#2 should be a note')
> - **Skip** (exclude from migration)
> - **Rename** (suggest a different title)
>
> Which changes, if any?"

Iterate until the user confirms the plan.

### 6. Execute Migration

For each approved item, in order:

1. **Assign ID** — run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/next-id.sh <TYPE> ./board` for each file. Run these sequentially (each assignment updates state for the next).

2. **Create the new board file** with:
   - Correct frontmatter for the type (see quick reference for required fields)
   - `created` set to today's date
   - Tasks get `status: backlog`, `priority: 2` (unless the user specified otherwise)
   - Epics get `status: planning`
   - ADRs get `status: active` and `context_date` set to today
   - Notes get `status: inbox`
   - Resources get `status: inbox` (ask user for `url` if not evident from content)
   - References get no status
   - Body content from the original file (with existing non-board frontmatter stripped or folded into body)
   - Title as `# TYPE-NNNN: Title` heading

3. **Remove the original file** — use `git rm` on the source file. The board file was created at the new path, and git tracks the content lineage.

4. **Check for cross-references** — use Grep to find any references to the original filename across the codebase (other docs, code comments, README). Report these so the user can update them.

**Important:** Do NOT use `git mv` for this operation since the file content is being transformed (new frontmatter, renamed, restructured). Use Write to create the new file + `git rm` to remove the old one. Git's rename detection will still link the history.

### 7. Post-Migration Report

After all items are migrated, present a summary:

```
## Migration Complete

### Migrated (5 files)
- docs/auth-design.md → board/planning/ADR-0003_chose-jwt-for-session-management.md
- docs/api-endpoints.md → board/reference/REFE-0004_api-endpoint-reference.md
- TODO.md → board/planning/EPIC-0002_implement-user-dashboard.md
- docs/meeting-notes.md → board/planning/NOTE-0003_sprint-3-planning-notes.md
- docs/redis-article.md → board/resources/RESO-0001_redis-caching-patterns-article.md

### Skipped
- docs/scratch.md (user chose to skip)

### References to Update
- README.md:15 references "docs/api-endpoints.md" — update to board path
```

Then run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-lint.sh ./board` to validate the newly created files pass lint.

### 8. Offer Follow-Up

After migration, suggest next steps if applicable:

- "Want me to split any of the multi-item files into individual tasks?"
- "Want me to update the cross-references I found?"
- "Run `/board:board-update` to reconcile the board with the codebase?"

## Guidelines

- **Never auto-migrate without user confirmation** — always present the plan and wait for approval
- **Preserve content faithfully** — the body of migrated files should retain all original content. Do not summarize, truncate, or rewrite unless the user asks
- **One file = one board item** — if a file should become multiple items, flag it but don't auto-split
- **ADR caution** — only classify as ADR if the file genuinely documents a decision already made. Design docs or proposals are more likely NOTEs or REFEs
- **Resource requires URL** — if classifying as resource but no URL is evident, ask the user for one during execution
- **Duplicate detection** — before finalizing the plan, check the pre-loaded board data for items with similar titles. Warn the user if a candidate overlaps with an existing board item
