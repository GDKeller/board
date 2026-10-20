#!/usr/bin/env bash
# board-scan.sh — Parse all active board files and output structured data.
# Usage: board-scan.sh [board_root] [--active] [--archive-summary]
#   board_root defaults to ./board (flags and path may appear in any order)
#   --active            skip archive/ directory (smaller output for most operations)
#   --archive-summary   output ONLY per-type archive counts (e.g., "TASK	12"), no file rows
#
# Output format (tab-separated, one line per board item, "-" for empty fields):
#   filepath	type	status	priority	blocked_by	parent	title
#
# Only files named TYPE-NNNN_*.md are rows. Files with missing or unclosed
# frontmatter are skipped with a warning on stderr (board-lint.sh reports them).
# Without --active, files from board/archive/ are included alongside active files.

set -euo pipefail

BOARD_ROOT=""
INCLUDE_ARCHIVE=1
ARCHIVE_SUMMARY=0
for arg in "$@"; do
    case "$arg" in
        --active) INCLUDE_ARCHIVE=0 ;;
        --archive-summary) ARCHIVE_SUMMARY=1; INCLUDE_ARCHIVE=0 ;;
        -*) echo "Unknown flag: $arg" >&2; exit 2 ;;
        *)  BOARD_ROOT="$arg" ;;
    esac
done
BOARD_ROOT="${BOARD_ROOT:-./board}"

# Guard: if no board directory exists, fail loudly
if [[ ! -d "$BOARD_ROOT" ]]; then
    echo "Error: No board directory found at $BOARD_ROOT. Run /board:board-init to set up." >&2
    exit 1
fi

# Strip surrounding quotes, [[wikilink]] brackets, and trailing whitespace (incl. CR).
clean_value() {
    local val="$1"
    val="${val//\"/}"
    val="${val//\'/}"
    val="${val//\[\[/}"
    val="${val//\]\]/}"
    val="${val%"${val##*[![:space:]]}"}"
    printf '%s' "$val"
}

parse_file() {
    local file="$1"
    local name="${file##*/}"
    # Only board items are rows; README.md or stray notes in a board directory are not
    [[ "$name" =~ ^(TASK|EPIC|ADR|REFE|RESO|NOTE)-[0-9]{4}_.+\.md$ ]] || return 0
    local in_frontmatter=0
    local past_frontmatter=0
    local in_multiline_key=""
    local type="" status="" priority="" blocked_by="" parent="" title="" fm_title=""
    local line_num=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$((line_num + 1))

        # Safety: stop scanning after 50 lines (frontmatter + title should be well within this)
        if [[ $line_num -gt 50 ]]; then
            break
        fi

        # Detect frontmatter boundaries: exactly "---" plus optional trailing whitespace/CR
        if [[ "$line" =~ ^---[[:space:]]*$ ]]; then
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
                local item
                item="$(clean_value "${line#*- }")"
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
            if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*):[[:space:]]*(.*) ]]; then
                local key="${BASH_REMATCH[1]}"
                local val
                val="$(clean_value "${BASH_REMATCH[2]}")"

                case "$key" in
                    type)       type="$val" ;;
                    status)     status="$val" ;;
                    priority)   priority="$val" ;;
                    parent)     parent="$val" ;;
                    title)      fm_title="$val" ;;
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
            title="${title%"${title##*[![:space:]]}"}"
            break
        fi
    done < "$file"

    # Missing or unclosed frontmatter: warn and skip the row (board-lint.sh reports it as an error)
    if [[ $in_frontmatter -eq 1 || $past_frontmatter -eq 0 ]]; then
        echo "Warning: $file has missing or unclosed frontmatter — skipped" >&2
        return 0
    fi

    # Title fallback: frontmatter title:, then the filename slug
    if [[ -z "$title" ]]; then
        title="$fm_title"
    fi
    if [[ -z "$title" ]]; then
        title="${name#*_}"; title="${title%.md}"; title="${title//-/ }"
    fi
    # A tab in a title would corrupt the TSV row
    title="${title//$'\t'/ }"

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$file" "${type:--}" "${status:--}" "${priority:--}" "${blocked_by:--}" "${parent:--}" "$title"
}

# Archive summary: only per-type counts, no per-file rows (keeps injected context small)
if [[ $ARCHIVE_SUMMARY -eq 1 ]]; then
    printf '# Archive counts (type\tcount)\n'
    for prefix in TASK EPIC ADR NOTE REFE RESO; do
        count=0
        for f in "$BOARD_ROOT/archive/${prefix}"-*.md; do
            [[ -f "$f" ]] && count=$((count + 1))
        done
        [[ $count -gt 0 ]] && printf '%s\t%s\n' "$prefix" "$count"
    done
    exit 0
fi

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

# Scan archive (unless --active flag is set)
if [[ $INCLUDE_ARCHIVE -eq 1 && -d "$BOARD_ROOT/archive" ]]; then
    for file in "$BOARD_ROOT/archive"/*.md; do
        [[ -f "$file" ]] || continue
        parse_file "$file"
    done
fi

exit 0
