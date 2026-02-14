---
name: board-lint
description: "This skill should be used when the user asks to 'lint the board', 'validate board files', 'check board health', 'fix board issues', or when board validation errors are reported. Also triggered by '/board:lint'."
disable-model-invocation: true
---

# Board Lint

Validate board files for structural and data issues, and help fix any problems found. The system spec is at `board/reference/REFE-0001_board-system-spec.md`.

## Steps

### 1. Scan All Board Files

Use Glob to find all `.md` files in `board/tasks/`, `board/planning/`, `board/reference/`, `board/resources/`, and `board/archive/`.

For each file, use Read with `limit: 15` to extract frontmatter, then validate:

### 2. Validation Checks

**Filename pattern**: Must match `TYPE-NNNN_kebab-case.md` (e.g., `TASK-0003_add-caching.md`).

**Required frontmatter**: Every board file must have `---` delimited YAML frontmatter with at minimum a `type` field.

**Type-specific validation**:

| Type | Required Fields | Valid Statuses | Valid Directory |
|------|----------------|----------------|-----------------|
| task | type, status | backlog, current, done | tasks/, archive/ |
| epic | type, status | planning, current, done | planning/, archive/ |
| adr | type, status | active, superseded, deprecated | planning/ (NEVER archive/) |
| reference | type | _(none)_ | reference/ |
| resource | type, status | inbox, processing, processed | resources/, archive/ |
| note | type, status | inbox, processed | planning/, archive/ |

**Cross-checks**:
- Type in frontmatter must match filename prefix (e.g., `TASK-*` files must have `type: task`)
- Priority (if present) must be 1, 2, or 3
- No duplicate IDs within the same type
- `blocked_by` references must point to existing task IDs
- ADRs must never be in `board/archive/`

### 3. Present Issues

Group issues by severity:

```
## Board Health Report

### Errors (must fix)
- TASK-0003_add-caching.md: Invalid status 'wip' (must be backlog|current|done)
- ADR-0001_chose-redis.md: ADR is in archive/ — must move back to planning/

### Warnings (review)
- RESO-0002_redis-article.md: Missing field: url
- TASK-0007_setup-auth.md: Missing field: created
```

If no issues found, report that the board is healthy and stop.

### 4. Offer Fixes

For each error, offer to fix it:

- **Invalid status**: Ask the user what the correct status should be, then update frontmatter
- **Wrong directory**: Offer to move the file to the correct directory via `git mv`
- **Missing fields**: Ask the user for the value, then add it to frontmatter
- **Duplicate IDs**: Offer to reassign one of the duplicates to the next available ID
- **ADR in archive**: Offer to move it back to `board/planning/`
- **Broken references**: Ask if the reference should be removed or if a missing file should be created

### 5. LLM-Only Checks

After structural validation, perform checks that require language understanding:

- **Task title mood**: Scan task files and check if titles use imperative mood (verb-first). Flag noun phrases like "User Authentication" that should be "Add user authentication".
- **ADR completeness**: Check if ADRs have a "Spawned Items" section. If missing, flag it.

Present these as suggestions, not errors — they require judgment.

### 6. Re-validate

After fixing issues, re-scan the affected files to confirm all errors are resolved.
