#!/usr/bin/env bash
# next-id.sh — Determine the next available ID for a board document type.
# Usage: next-id.sh <TYPE> [board_root]
#   TYPE: TASK, EPIC, ADR, REFE, RESO, NOTE (case-insensitive)
#   board_root defaults to ./board
#
# Output: next ID as 4-digit zero-padded number (e.g., 0005)

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: next-id.sh <TYPE> [board_root]" >&2
    exit 1
fi

TYPE="$(echo "$1" | tr '[:lower:]' '[:upper:]')"
BOARD_ROOT="${2:-./board}"

# Validate type
case "$TYPE" in
    TASK|EPIC|ADR|REFE|RESO|NOTE) ;;
    *)
        echo "Error: Invalid type '$TYPE'. Must be TASK, EPIC, ADR, REFE, RESO, or NOTE." >&2
        exit 1
        ;;
esac

max_id=0

# Scan all directories (including archive) for files matching the type prefix
for file in "$BOARD_ROOT"/*/"${TYPE}"-*.md "$BOARD_ROOT"/archive/"${TYPE}"-*.md; do
    [[ -f "$file" ]] || continue
    basename="$(basename "$file")"
    # Extract the numeric ID: TYPE-NNNN_...
    id_str="${basename#"${TYPE}"-}"
    id_str="${id_str%%_*}"
    # Skip non-numeric IDs (e.g., TASK-draft_something.md)
    if ! [[ "$id_str" =~ ^[0-9]+$ ]]; then
        continue
    fi
    # Convert to integer (strip leading zeros)
    id_num=$((10#$id_str))
    if [[ $id_num -gt $max_id ]]; then
        max_id=$id_num
    fi
done

# Also check .doc-ids tracking file if it exists
doc_ids_file="$BOARD_ROOT/.doc-ids"
if [[ -f "$doc_ids_file" ]]; then
    tracked_id=$(grep "^${TYPE}=" "$doc_ids_file" 2>/dev/null | cut -d= -f2)
    if [[ -n "$tracked_id" ]]; then
        tracked_num=$((10#$tracked_id))
        if [[ $tracked_num -gt $max_id ]]; then
            max_id=$tracked_num
        fi
    fi
fi

next_id=$((max_id + 1))
printf '%04d\n' "$next_id"
