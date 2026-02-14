#!/usr/bin/env bash
# archive-batch.sh — Move board items to the archive directory.
# Usage: archive-batch.sh <board_root> <file1> [file2] [file3] ...
#
# Uses git mv if inside a git repo, plain mv otherwise.
# Skips ADR files (they are never archived).
# Reports what was moved and what was skipped.

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: archive-batch.sh <board_root> <file1> [file2] ..." >&2
    exit 1
fi

BOARD_ROOT="$1"
shift
ARCHIVE_DIR="$BOARD_ROOT/archive"

# Ensure archive directory exists
mkdir -p "$ARCHIVE_DIR"

# Detect if we're in a git repo
use_git=false
if git rev-parse --is-inside-work-tree &>/dev/null; then
    use_git=true
fi

moved=()
skipped=()

for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        skipped+=("$file (not found)")
        continue
    fi

    basename="$(basename "$file")"

    # Verify file is within BOARD_ROOT (prevent path traversal)
    real_board="$(cd "$BOARD_ROOT" && pwd -P)"
    real_file="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"
    if [[ "$real_file" != "$real_board/"* ]]; then
        skipped+=("$file (outside board directory)")
        continue
    fi

    # Skip ADR files — they are never archived
    if [[ "$basename" == ADR-* ]]; then
        skipped+=("$file (ADR — never archived)")
        continue
    fi

    # Skip if already in archive
    if [[ "$file" == *"/archive/"* ]]; then
        skipped+=("$file (already archived)")
        continue
    fi

    dest="$ARCHIVE_DIR/$basename"

    if [[ -f "$dest" ]]; then
        skipped+=("$file (destination already exists)")
        continue
    fi

    if $use_git; then
        if ! git mv "$file" "$dest" 2>/dev/null; then
            skipped+=("$file (git mv failed — check for uncommitted changes)")
            continue
        fi
    else
        if ! mv "$file" "$dest" 2>/dev/null; then
            skipped+=("$file (mv failed)")
            continue
        fi
    fi
    moved+=("$basename")
done

# Report results
if [[ ${#moved[@]} -gt 0 ]]; then
    echo "Archived:"
    for item in "${moved[@]}"; do
        echo "  $item"
    done
fi

if [[ ${#skipped[@]} -gt 0 ]]; then
    echo "Skipped:"
    for item in "${skipped[@]}"; do
        echo "  $item"
    done
fi

echo ""
echo "Total: ${#moved[@]} archived, ${#skipped[@]} skipped"
