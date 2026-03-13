#!/usr/bin/env bash
# board-scan.sh — Parse all active board files and output structured data.
# Usage: board-scan.sh [board_root] [--active] [--archive-summary]
#   board_root defaults to ./board
#   --active            skip archive/ directory (smaller output for most operations)
#   --archive-summary   output only per-type counts for archive (e.g., "task	12")
#
# Output format (tab-separated, one line per file):
#   filepath	type	status	priority	blocked_by	parent	title
#
# Without --active, files from board/archive/ are included alongside active files.

set -euo pipefail

BOARD_ROOT="${1:-./board}"
INCLUDE_ARCHIVE=1
ARCHIVE_SUMMARY=0
for arg in "$@"; do
    case "$arg" in
        --active) INCLUDE_ARCHIVE=0 ;;
        --archive-summary) ARCHIVE_SUMMARY=1; INCLUDE_ARCHIVE=0 ;;
    esac
done

# Guard: if no board directory exists, output header only
if [[ ! -d "$BOARD_ROOT" ]]; then
    printf 'filepath\ttype\tstatus\tpriority\tblocked_by\tparent\ttitle\n'
    printf '# No board directory found at %s. Run /board:board-init to set up.\n' "$BOARD_ROOT"
    exit 0
fi

parse_file() {
    local file="$1"
    local in_frontmatter=0
    local past_frontmatter=0
    local in_multiline_key=""
    local type="" status="" priority="" blocked_by="" parent="" title=""
    local line_num=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$((line_num + 1))

        # Safety: stop scanning after 50 lines (frontmatter + title should be well within this)
        if [[ $line_num -gt 50 ]]; then
            break
        fi

        # Detect frontmatter boundaries (must be exactly "---" with optional trailing whitespace)
        local trimmed="${line%%[[:space:]]*}"
        if [[ "$trimmed" == "---" ]]; then
            if [[ $in_frontmatter -eq 1 ]]; then
                past_frontmatter=1
                in_frontmatter=0
                in_multiline_key=""
                continue
            elif [[ $past_frontmatter -eq 0 && $line_num -le 2 ]]; then
                in_frontmatter=1
                continue
            fi
        fi

        # Parse frontmatter fields
        if [[ $in_frontmatter -eq 1 ]]; then
            # Skip comments
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi

            # Detect multi-line list continuation (indented lines starting with -)
            if [[ -n "$in_multiline_key" && "$line" =~ ^[[:space:]]+-[[:space:]] ]]; then
                local item="${line#*- }"
                # Strip quotes
                item="${item//\"/}"
                item="${item//\'/}"
                item="${item%%[[:space:]]}"
                case "$in_multiline_key" in
                    blocked_by)
                        if [[ -n "$blocked_by" ]]; then
                            blocked_by="$blocked_by,$item"
                        else
                            blocked_by="$item"
                        fi
                        ;;
                esac
                continue
            fi

            # Non-indented line ends any multi-line value
            in_multiline_key=""

            # Extract key: value pairs (handles optional leading/trailing whitespace)
            if [[ "$line" =~ ^([a-z_]+):[[:space:]]*(.*) ]]; then
                local key="${BASH_REMATCH[1]}"
                local val="${BASH_REMATCH[2]}"

                # Strip quotes and trailing whitespace
                val="${val//\"/}"
                val="${val//\'/}"
                val="${val%%[[:space:]]}"

                case "$key" in
                    type)       type="$val" ;;
                    status)     status="$val" ;;
                    priority)   priority="$val" ;;
                    parent)     parent="$val" ;;
                    blocked_by)
                        if [[ -z "$val" ]]; then
                            # Multi-line YAML list follows
                            in_multiline_key="blocked_by"
                        else
                            # Inline value (could be bracket list or single value)
                            # Strip brackets: [x, y] -> x, y
                            val="${val#\[}"
                            val="${val%\]}"
                            blocked_by="$val"
                        fi
                        ;;
                esac
            fi
        fi

        # First heading after frontmatter = title
        if [[ $past_frontmatter -eq 1 && -z "$title" && "$line" == "# "* ]]; then
            title="${line#\# }"
            break
        fi
    done < "$file"

    # If we never found the closing ---, the file has no valid frontmatter
    if [[ $in_frontmatter -eq 1 ]]; then
        # Unclosed frontmatter — output with empty fields
        type=""
        status=""
    fi

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

# Scan archive (unless --active or --archive-summary flag is set)
if [[ $INCLUDE_ARCHIVE -eq 1 && -d "$BOARD_ROOT/archive" ]]; then
    for file in "$BOARD_ROOT/archive"/*.md; do
        [[ -f "$file" ]] || continue
        parse_file "$file"
    done
fi

# Archive summary: count files by type prefix instead of parsing each one
if [[ $ARCHIVE_SUMMARY -eq 1 && -d "$BOARD_ROOT/archive" ]]; then
    printf '\n# Archive counts (type\tcount)\n'
    for prefix in TASK EPIC ADR NOTE REFE RESO; do
        count=0
        for f in "$BOARD_ROOT/archive/${prefix}"-*.md; do
            [[ -f "$f" ]] && count=$((count + 1))
        done
        [[ $count -gt 0 ]] && printf '%s\t%s\n' "$prefix" "$count"
    done
fi

exit 0
