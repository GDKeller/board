---
type: task
status: backlog
priority: 2
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0005: Add atomic ID claiming to next-id.sh via .doc-ids writeback

## Description

`next-id.sh` reads the highest existing ID and increments it, but never writes back to `.doc-ids`. Two rapid `/board:board-add` calls (before the first file is created on disk) will return the same ID, causing a silent duplicate.

## Changes Required

After computing `next_id`, update `.doc-ids` before printing:

```bash
next_id=$((max_id + 1))
next_id_padded=$(printf '%04d' "$next_id")

# Claim the ID by updating .doc-ids
if [[ -f "$doc_ids_file" ]]; then
    if sed -i.bak "s/^${TYPE}=.*/${TYPE}=${next_id_padded}/" "$doc_ids_file" 2>/dev/null; then
        rm -f "${doc_ids_file}.bak"
    else
        echo "Warning: Could not update .doc-ids — ID $next_id_padded is not reserved" >&2
    fi
fi

printf '%04d\n' "$next_id"
```

Also update `plugin/skills/board-add/SKILL.md` to remove any instruction for the LLM to manually update `.doc-ids` (the script handles it now).
