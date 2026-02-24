---
type: task
status: backlog
priority: 2
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0006: Fix board-scan.sh parsing issues

## Description

Three parsing issues in `board-scan.sh` identified by the code review and silent failure analysis.

## Changes Required

### 1. Frontmatter boundary detection (line 49)

Current `${line%%[[:space:]]*}` matches `--- some text` as a delimiter. Replace with regex:

```bash
if [[ "$line" =~ ^---[[:space:]]*$ ]]; then
```

### 2. Value trimming (lines 75 and 99)

Current `${val%%[[:space:]]}` (no `*`) only strips one trailing whitespace character. Replace with:

```bash
val=$(echo "$val" | sed 's/[[:space:]]*$//')
```

### 3. Malformed file handling (line 130-134)

Files with unclosed frontmatter silently emit rows with empty fields. Add stderr warning and skip the row:

```bash
if [[ $in_frontmatter -eq 1 ]]; then
    printf 'Warning: %s has unclosed frontmatter\n' "$file" >&2
    return
fi
```

### 4. Argument parsing (lines 15-23)

Shift `$1` before flag scanning to prevent board root from being matched as a flag:

```bash
BOARD_ROOT="${1:-./board}"
shift 1
for arg in "$@"; do
    case "$arg" in ...
```

### 5. Key regex (line 92)

Broaden to allow hyphenated keys: `^([a-zA-Z_][a-zA-Z0-9_-]*):` instead of `^([a-z_]+):`.
