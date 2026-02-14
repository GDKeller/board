#!/usr/bin/env bash
# board-scan.sh — Parse all active board files and output structured data.
# Usage: board-scan.sh [board_root]
#   board_root defaults to ./board
#
# Output format (tab-separated, one line per file):
#   filepath	type	status	priority	blocked_by	parent	title
#
# Files from board/archive/ are included with an [archived] marker in filepath.

set -euo pipefail

BOARD_ROOT="${1:-./board}"

parse_file() {
    local file="$1"
    local in_frontmatter=0
    local past_frontmatter=0
    local type="" status="" priority="" blocked_by="" parent="" title=""

    while IFS= read -r line; do
        # Detect frontmatter boundaries
        if [[ "$line" == "---" ]]; then
            if [[ $in_frontmatter -eq 1 ]]; then
                past_frontmatter=1
                in_frontmatter=0
                continue
            elif [[ $past_frontmatter -eq 0 ]]; then
                in_frontmatter=1
                continue
            fi
        fi

        # Parse frontmatter fields
        if [[ $in_frontmatter -eq 1 ]]; then
            case "$line" in
                type:*)     type="${line#type: }" ;;
                status:*)   status="${line#status: }" ;;
                priority:*) priority="${line#priority: }" ;;
                blocked_by:*) blocked_by="${line#blocked_by: }" ;;
                parent:*)   parent="${line#parent: }" ;;
            esac
        fi

        # First heading after frontmatter = title
        if [[ $past_frontmatter -eq 1 && -z "$title" && "$line" == "# "* ]]; then
            title="${line#\# }"
            break
        fi
    done < "$file"

    # Clean up values (trim quotes, brackets)
    type="${type//\"/}"
    status="${status//\"/}"
    priority="${priority//\"/}"
    blocked_by="${blocked_by//\"/}"
    parent="${parent//\"/}"

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$file" "$type" "$status" "${priority:--}" "${blocked_by:--}" "${parent:--}" "$title"
}

# Header
printf 'filepath\ttype\tstatus\tpriority\tblocked_by\tparent\ttitle\n'

# Scan active directories
for dir in tasks planning reference resources; do
    dirpath="$BOARD_ROOT/$dir"
    [[ -d "$dirpath" ]] || continue
    for file in "$dirpath"/*.md; do
        [[ -f "$file" ]] || continue
        parse_file "$file"
    done
done

# Scan archive (marked)
if [[ -d "$BOARD_ROOT/archive" ]]; then
    for file in "$BOARD_ROOT/archive"/*.md; do
        [[ -f "$file" ]] || continue
        parse_file "$file"
    done
fi
