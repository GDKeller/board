---
name: board-migrate
description: "Migrates existing Markdown files into the board system by discovering untracked docs, classifying them interactively, and moving them into the correct board directories with proper frontmatter and naming. Activates when the user asks to migrate, import, or onboard existing docs into the board, or via '/board:board-migrate'."
argument-hint: "[path]"
allowed-tools: Bash, Read, Write, Glob, Grep, AskUserQuestion
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

Verify `board/` directory exists with these exact subdirectories: `tasks/`, `planning/`, `reference/`, `resources/`, `archive/`. If `board/` is missing entirely, tell the user to run `/board:board-init` first and stop. If specific subdirectories are missing, list which ones and suggest running init.

### 2. Pre-Flight Checks

Run `git status --porcelain` to check for staged or unstaged changes. If the working tree is dirty, warn the user:

> "There are uncommitted changes in the working tree. I recommend committing or stashing before migration — this makes it easier to undo if something goes wrong. Continue anyway?"

This is advisory, not blocking — proceed if the user says yes.

### 3. Discover Candidate Files

Scan these default locations for `.md` files:

- Project root (`*.md` — non-recursive)
- `docs/` directory (recursive) — if `docs/` does not exist, skip it silently

If `$ARGUMENTS` contains a path, scan that path recursively as well. Before scanning a user-supplied path, verify it exists and is a directory. If not, report the specific invalid path and ask the user to correct it.

**Exclude** these files from candidates — they are never board items:

- `README.md`, `CHANGELOG.md`, `LICENSE.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`
- `CLAUDE.md` and any `.claude/**/*.md`
- Anything already inside `board/` or `board/archive/`
- `node_modules/`, `.git/`, `vendor/`, `dist/`, `build/`, `.next/`
- Any file already matching the `TYPE-NNNN_*.md` naming pattern
- Symlinks — skip and note to the user ("skipped: symlink, requires manual handling")

### 4. Present Discovery Results

List all candidate files found with their paths.

If zero candidates found:
- Report that no untracked Markdown files were found in the scanned locations
- If the user provided a `[path]` argument, confirm it was scanned correctly
- Suggest using `/board:board-add` to create new items directly
- Stop here

After listing candidates, note: "If there are files in other locations you'd like to include, tell me the path and I'll re-scan."

### 5. Classify Each File

For each candidate file:

1. **Read with `limit: 30`** to get the heading + opening content. This is sufficient for most classifications.
2. **If classification is ambiguous** after the preview (file purpose is unclear, content doesn't match any heuristic well), do a full read for that file only.
3. **Apply skip guards** before classifying:
   - **Empty/whitespace-only:** Skip automatically. Report as "skipped (no content)."
   - **Binary content** (non-UTF-8, NUL bytes, garbled output): Skip. Report as "skipped (binary content)."
   - **Frontmatter-only** (stripping YAML frontmatter leaves zero body content): Ask the user whether to skip, fold frontmatter key-value pairs into the body as prose, or create a stub item.
   - **Very large files (>500 lines):** Warn the user and ask: (a) proceed with full migration, (b) classify from the preview and migrate full content without reading it all, or (c) skip.
4. **Strip any existing frontmatter** — existing YAML frontmatter is almost certainly not board-compatible. It will be discarded; its content may inform classification but will not be preserved as frontmatter. If the existing frontmatter contains useful context, fold it into the body content.
5. **Suggest a board type** based on content analysis:

| Signal | Suggested Type |
|--------|---------------|
| Actionable work: describes something to build, fix, or do; imperative language; TODO items | **task** |
| Groups of related work items; roadmap; phased plan; multiple deliverables | **epic** |
| Documents a decision already made; compares alternatives; has "we chose X because Y" | **adr** |
| Encyclopedic/reference material; explains how something works; API docs; architecture overview | **reference** |
| Primarily links to external URLs; article summaries; external material | **resource** |
| Rough notes; brainstorming; meeting notes; unstructured thoughts; investigation notes | **note** |

6. **Suggest a title** — derive from the file's `# heading` if present, otherwise from filename. For tasks, rewrite to imperative mood.

**Ambiguous cases:** If a file doesn't clearly fit one type, note the ambiguity and give your best suggestion with a brief reason. The user will confirm or override.

**Multi-item files:** If a single file contains what should clearly be multiple board items (e.g., a doc listing 5 separate tasks), flag this and suggest splitting. Do NOT auto-split — just note it in the plan for the user to decide.

**Batching:** If there are >10 candidates, process in batches of 5 — classify a batch, then continue to the next. Present the full plan once all batches are classified.

### 6. Present Migration Plan

**Duplicate detection:** Before presenting the plan, check the pre-loaded board data for items with similar titles. Warn the user if any candidate overlaps with an existing board item.

**Filename collision check:** If two candidate files would produce the same target filename, disambiguate by incorporating path context into the kebab title (e.g., `docs-notes` vs `planning-notes`) or ask the user to rename one.

**Resource URL check:** For any item classified as resource, note the URL requirement now: "Item #N is a resource — do you have a URL? (You can reclassify as a note if no URL is available.)"

**ADR context_date check:** For any item classified as ADR, attempt to infer the decision date from file content or `git log --follow "<file>"`. If the date is unclear, ask during plan review — not during execution. ADRs are immutable; a wrong `context_date` cannot be corrected later. Example: "Item #N is an ADR — when was this decision made? I see the file was last modified on 2025-11-03. Use that date?"

Present the plan as a numbered list:

```
## Migration Plan (5 files)

1. docs/auth-design.md → ADR: "Chose JWT for session management"
   Target: board/planning/ADR-0003_chose-jwt-for-session-management.md
2. docs/api-endpoints.md → reference: "API endpoint reference"
   Target: board/reference/REFE-0004_api-endpoint-reference.md
3. TODO.md → epic: "Implement user dashboard"
   Target: board/planning/EPIC-0002_implement-user-dashboard.md
   Note: Contains 4 sub-items that could be individual TASKs under this EPIC
4. docs/meeting-notes.md → note: "Sprint 3 planning notes"
   Target: board/planning/NOTE-0003_sprint-3-planning-notes.md
5. docs/redis-article.md → resource: "Redis caching patterns article"
   Target: board/resources/RESO-0001_redis-caching-patterns-article.md
   URL needed — please provide, or reclassify
```

Then ask the user to review:

> "Review the plan above. You can:
> - **Accept all**: 'looks good' or 'proceed'
> - **Reclassify**: '#2 should be a note', 'make 3 an epic'
> - **Skip**: 'skip #4', 'skip 4 and 6'
> - **Rename**: '#1 title should be Adopt JWT over sessions'
> - **Bulk**: 'make 2, 3, and 5 all notes'
>
> Which changes, if any?"

Handle bulk operations — apply all stated changes to the plan, then re-present for final confirmation. Iterate until the user confirms.

### 7. Execute Migration

**CRITICAL — Sequential execution:** For each approved item, perform the full cycle before moving to the next: assign ID → write file to disk → remove original → next item. **Never batch ID assignments.** Each file must exist on disk before the next ID is requested, because `next-id.sh` scans the filesystem for existing IDs.

For each approved item, in order:

**a. Assign ID:**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/next-id.sh <TYPE> ./board
```

**b. Create the new board file** using the correct frontmatter template:

Task:
```yaml
---
type: task
status: backlog
priority: 2
created: YYYY-MM-DD
---
```

Epic:
```yaml
---
type: epic
status: planning
created: YYYY-MM-DD
---
```

ADR:
```yaml
---
type: adr
status: active
context_date: YYYY-MM-DD
created: YYYY-MM-DD
---
```

Note:
```yaml
---
type: note
status: inbox
created: YYYY-MM-DD
---
```

Reference:
```yaml
---
type: reference
created: YYYY-MM-DD
---
```

Resource:
```yaml
---
type: resource
status: inbox
url: <url>
created: YYYY-MM-DD
---
```

Set `created` to today's date. Use `# TYPE-NNNN: Title` as the heading.

**Type-specific rules:**

- **ADR `context_date`:** Set to the decision date, NOT today. Infer from file content, git history (`git log --follow "<file>"`), or ask the user if unclear. ADRs are immutable — a wrong `context_date` cannot be corrected later.
- **ADR body structure:** The body must include the required sections: Context, Considered Approaches, Decision, Consequences, and Spawned Items. If the source file lacks these, scaffold the section headers and populate from available content. Always include `## Spawned Items` — use "No follow-up needed" if nothing applies.
- **Resource `url`:** Required field. The URL should have been collected during plan review (Step 6). Do not create a resource without a `url`.
- **Task titles:** Must be imperative mood (verb-first).

Carry over body content from the original file. Preserve content faithfully — do not summarize, truncate, or rewrite.

**c. Remove the original file:**

Before removing, check if the file is git-tracked:

```bash
git ls-files --error-unmatch "<path>" 2>/dev/null
```

- If tracked: `git rm "<path>"`
- If untracked: `rm "<path>"`

Always double-quote file paths in all Bash calls to handle spaces and special characters.

**d. Check for cross-references:**

Use Grep to find references to the original filename in `*.md` files. Limit results to 20 — if more are found, summarize the count. Report these so the user can update them.

**Important:** Do NOT use `git mv` for this operation since the file content is being transformed (new frontmatter, renamed, restructured). Use Write to create the new file and `git rm`/`rm` to remove the old one. Git may detect this as a rename and preserve history linkage, but this is not guaranteed when content changes significantly.

**Failure handling:** If any single file fails during execution (Read error, `git rm` failure, etc.), log it as "failed" in the post-migration summary, continue with remaining files, and report all failures at the end.

### 8. Post-Migration Report

Present a single consolidated summary:

```
## Migration Complete

### Migrated (4 files)
- docs/auth-design.md → board/planning/ADR-0003_chose-jwt-for-session-management.md
- docs/api-endpoints.md → board/reference/REFE-0004_api-endpoint-reference.md
- TODO.md → board/planning/EPIC-0002_implement-user-dashboard.md
- docs/meeting-notes.md → board/planning/NOTE-0003_sprint-3-planning-notes.md

### Skipped
- docs/scratch.md (user chose to skip)
- docs/empty.md (no content)

### Failed
- docs/locked-file.md (git rm failed: file has staged changes)

### References to Update
- README.md:15 references "docs/api-endpoints.md"
```

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-lint.sh ./board` and report as a single line: "Board lint: all files valid." or "Board lint: N errors found — run `/board:board-lint` to fix."

Only offer follow-up suggestions when something specific warrants them:
- If a multi-item file was flagged: "Want me to split #3 into individual tasks?"
- If cross-references were found: "Want me to update the references above?"
- If there were failures: "Want me to retry the failed files?"

**Recovery note:** If migration was interrupted (partial completion), re-running `/board:board-migrate` is safe — already-migrated files are excluded by the `TYPE-NNNN_*.md` filter and won't be re-discovered. However, check for orphaned originals — if a crash occurred between Write and `git rm`, the source file may still exist alongside the new board item, creating a content duplicate.

## Guidelines

- **Never auto-migrate without user confirmation** — always present the plan and wait for approval
- **Preserve content faithfully** — the body of migrated files should retain all original content. Do not summarize, truncate, or rewrite unless the user asks
- **One file = one board item** — if a file should become multiple items, flag it but don't auto-split
- **ADR caution** — only classify as ADR if the file genuinely documents a decision already made. Design docs or proposals are more likely NOTEs or REFEs
- **Resource requires URL** — `url` is a required field. Surface during plan review, not execution. If no URL is available, suggest reclassifying as a note
- **Duplicate detection** — before finalizing the plan, check the pre-loaded board data for items with similar titles. Warn the user if a candidate overlaps with an existing board item
- **Always quote paths** — double-quote all file paths in Bash calls to handle spaces and special characters
