---
type: task
status: backlog
priority: 2
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0007: Fix board-lint.sh field extraction and validation gaps

## Description

Multiple issues in `board-lint.sh` identified by the code review and silent failure analysis.

## Changes Required

### 1. `get_field` strips all spaces (line 54)

Replace `tr -d ' '` with targeted leading/trailing trim:

```bash
sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
```

### 2. `get_field` `|| true` masks pipeline failures (line 50)

Separate the `|| true` so it only applies to `grep` (which legitimately returns 1 on no match), not the entire pipeline. Check file readability before parsing.

### 3. Extend `validate_references` (line 233+)

Currently only checks `blocked_by` references in TASK files. Also validate:
- `parent` fields in TASK files → check EPIC ID exists
- `spawned` fields in NOTE files → check all referenced IDs exist
- `superseded_by` fields in ADR files → check ADR ID exists

The `EXISTING_IDS` temp file already has all IDs — just need to query it for these fields.

### 4. Reference validation only greps `TASK-NNNN` (line 265)

Broaden to `(TASK|EPIC|ADR|REFE|RESO|NOTE)-[0-9]{4}` so references to any type are validated.

### 5. `created` field severity (lines 133-136)

Promote from WARN to ERROR to match the spec's designation as a required field. Same for `url` in RESO files and `context_date` in ADR files.

### 6. Add signal traps for temp file cleanup (line 31)

Add `INT TERM HUP` to the EXIT trap to prevent orphaned temp files on timeout/interrupt.
