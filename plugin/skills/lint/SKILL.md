---
name: lint
description: "Validates board files for structural integrity — checks frontmatter, status values, directory placement, duplicate IDs, and broken references, then offers interactive fixes. Activates when the user asks to lint or validate the board, or when board-lint.sh reports errors on session startup, or via '/board:lint'."
allowed-tools: Bash, Read, Edit, Glob, AskUserQuestion
disable-model-invocation: true
---

# Board Lint

Validate board files for structural and data issues, and help fix any problems found. The system spec is bundled with the plugin at `${CLAUDE_PLUGIN_ROOT}/spec/board-system-spec.md`.

## Steps

### 1. Lint Results

The following lint output is pre-loaded (checks: frontmatter validity, required fields, status/priority values, directory placement, filename patterns, duplicate IDs, ADRs in archive, broken references):

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-lint.sh`

### 2. Interpret Results

Parse the lint output above. Each line is either:
- `ERROR: <file>: <message>` — must be fixed
- `WARN:  <file>: <message>` — should be reviewed

If no issues found, report that the board is healthy and stop.

### 3. Present Issues

Group issues by file and present them clearly:

```
## Board Health Report

### Errors (must fix)
- TASK-0003_add-caching.md: Invalid status 'wip' (must be backlog|current|done)
- ADR-0001_chose-redis.md: ADR is in archive/ — must move back to planning/

### Warnings (review)
- RESO-0002_redis-article.md: Missing field: url
```

### 4. Offer Fixes

For each error, offer to fix it:

- **Invalid status**: Ask the user what the correct status should be, then use `/board:edit` to update
- **Wrong directory**: Offer to move the file to the correct directory via `git mv`
- **Missing fields**: Ask the user for the value, then add it to frontmatter
- **Duplicate IDs**: Offer to reassign one of the duplicates using `next-id.sh`
- **ADR in archive**: Offer to move it back to `board/planning/`
- **Broken references**: Ask if the reference should be removed or if a missing file should be created

### 5. LLM-Only Checks

After script-based validation, perform checks that require language understanding:

- **Task title mood**: Scan task files and check if titles use imperative mood (verb-first). Flag noun phrases like "User Authentication" that should be "Add user authentication".
- **ADR completeness**: Check if ADRs have a "Spawned Items" section. If missing, flag it.

Present these as suggestions, not errors — they require judgment.

### 6. Re-validate

After fixing issues, run the lint script again to confirm all errors are resolved.
