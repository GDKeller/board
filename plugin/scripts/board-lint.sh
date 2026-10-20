#!/usr/bin/env bash
# board-lint.sh — Validate all board files for structural and data issues.
# Usage: board-lint.sh [--hook|--no-fail] [board_root]
#   board_root defaults to ./board
#   --hook / --no-fail: always exit 0, and stay silent when the board is clean or
#                       there is no board/ directory (for SessionStart hook use)
#
# Compatible with bash 3.2+ (macOS default).
#
# Exit codes:
#   0 — no issues (or no board/ directory found, or --hook mode)
#   1 — errors found (strict mode only)
#
# Output:
#   stdout — summary lines ("Board lint: ...")
#   stderr — per-file ERROR/WARN findings

set -euo pipefail

NO_FAIL=0
BOARD_ROOT=""
for arg in "$@"; do
    case "$arg" in
        --hook|--no-fail) NO_FAIL=1 ;;
        -*) echo "Unknown flag: $arg" >&2; exit 2 ;;
        *)  BOARD_ROOT="$arg" ;;
    esac
done
BOARD_ROOT="${BOARD_ROOT:-./board}"

# If no board directory exists, exit clean (not every project uses board).
# Hook mode stays silent so projects without a board get no session noise.
if [[ ! -d "$BOARD_ROOT" ]]; then
    [[ $NO_FAIL -eq 1 ]] || echo "Board lint: no board/ directory found at $BOARD_ROOT — skipping."
    exit 0
fi

errors=0
warnings=0

# Temp files for tracking (avoids bash 4 associative arrays)
ID_TRACKER=$(mktemp)
EXISTING_IDS=$(mktemp)
trap 'rm -f "$ID_TRACKER" "$EXISTING_IDS"' EXIT INT TERM HUP

error() {
    echo "ERROR: $1: $2" >&2
    errors=$((errors + 1))
}

warn() {
    echo "WARN:  $1: $2" >&2
    warnings=$((warnings + 1))
}

# --- Helpers ---

# Extract a frontmatter field value from a file.
# Reads the full frontmatter block (between the first two --- fences), tolerates
# CRLF line endings, preserves internal whitespace, and strips surrounding
# whitespace plus optional surrounding quotes.
get_field() {
    local file="$1" key="$2"
    [[ -r "$file" ]] || { echo ""; return; }
    local raw
    raw=$(awk -v k="$key" '
        /^---[[:space:]]*\r?$/ { if (in_fm) exit; in_fm=1; next }
        in_fm && index($0, k ":") == 1 { print; exit }
    ' "$file" 2>/dev/null)
    if [[ -z "$raw" ]]; then
        echo ""
        return
    fi
    # Trim, strip key: prefix, strip surrounding quotes. sed may legitimately
    # return the input unchanged, so we do not guard with `|| true`.
    printf '%s' "$raw" | sed -e 's/\r$//' \
                            -e "s/^${key}:[[:space:]]*//" \
                            -e 's/[[:space:]]*$//' \
                            -e 's/^"\(.*\)"$/\1/' \
                            -e "s/^'\(.*\)'\$/\1/"
}

# Check if the file opens with a valid YAML frontmatter fence (CRLF-tolerant).
has_frontmatter() {
    local first
    first=$(head -1 "$1" 2>/dev/null | tr -d '\r')
    [[ "$first" == "---" ]]
}

# Check that the file has a closing --- fence after the opening one.
# Returns 0 if both fences are present, 1 otherwise.
has_closed_frontmatter() {
    awk '/^---[[:space:]]*\r?$/ { c++; if (c >= 2) { ok=1; exit } } END { exit (ok ? 0 : 1) }' "$1"
}

# --- Per-file validation ---

validate_file() {
    local file="$1"
    local basename
    basename="$(basename "$file")"
    local dir
    dir="$(basename "$(dirname "$file")")"

    # Skip non-matching files
    if ! echo "$basename" | grep -qE '^(TASK|EPIC|ADR|REFE|RESO|NOTE)-[0-9]{4}_.+\.md$'; then
        if [[ "$basename" == *.md && "$basename" != "README.md" ]]; then
            warn "$file" "Filename does not match TYPE-NNNN_kebab-case.md pattern"
        fi
        return
    fi

    # Reject empty or unreadable files up front
    if [[ ! -s "$file" ]]; then
        error "$file" "File is empty"
        return
    fi
    if [[ ! -r "$file" ]]; then
        error "$file" "File is not readable"
        return
    fi

    # Extract type prefix and ID from filename
    local file_type="${basename%%-*}"
    local id_str="${basename#*-}"
    id_str="${id_str%%_*}"
    local id_key="${file_type}-${id_str}"

    # Check for duplicate IDs
    if grep -q "^${id_key}=" "$ID_TRACKER" 2>/dev/null; then
        local prev
        prev=$(grep "^${id_key}=" "$ID_TRACKER" | cut -d= -f2)
        error "$file" "Duplicate ID $id_key (also at $prev)"
    else
        echo "${id_key}=${file}" >> "$ID_TRACKER"
    fi

    # Track existing IDs for reference validation
    echo "$id_key" >> "$EXISTING_IDS"

    # Check frontmatter exists and is closed
    if ! has_frontmatter "$file"; then
        error "$file" "Missing YAML frontmatter (no opening ---)"
        return
    fi
    if ! has_closed_frontmatter "$file"; then
        error "$file" "Unterminated YAML frontmatter (missing closing ---)"
        return
    fi

    # Every item needs an H1 title — board-scan.sh and board-show.sh display it
    if ! grep -qE '^# ' "$file"; then
        warn "$file" "No '# Title' heading found (board views fall back to the filename)"
    fi

    # Extract frontmatter values
    local type status priority
    type="$(get_field "$file" "type")"
    status="$(get_field "$file" "status")"
    priority="$(get_field "$file" "priority")"

    # --- Required fields ---

    if [[ -z "$type" ]]; then
        error "$file" "Missing required field: type"
        return
    fi

    # Verify type matches filename prefix
    local expected_type
    case "$file_type" in
        TASK) expected_type="task" ;;
        EPIC) expected_type="epic" ;;
        ADR)  expected_type="adr" ;;
        REFE) expected_type="reference" ;;
        RESO) expected_type="resource" ;;
        NOTE) expected_type="note" ;;
    esac

    if [[ "$type" != "$expected_type" ]]; then
        error "$file" "Type mismatch: filename says $file_type but frontmatter says type: $type"
    fi

    # Check created field (required per spec)
    local created
    created="$(get_field "$file" "created")"
    if [[ -z "$created" ]]; then
        error "$file" "Missing required field: created"
    elif ! echo "$created" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        warn "$file" "Field 'created' is not in YYYY-MM-DD format: $created"
    fi

    # --- Type-specific validation ---

    case "$type" in
        task)
            if [[ -z "$status" ]]; then
                error "$file" "Missing required field: status"
            elif [[ "$status" != "backlog" && "$status" != "current" && "$status" != "done" ]]; then
                error "$file" "Invalid status '$status' for task (must be backlog|current|done)"
            fi

            if [[ -n "$priority" && "$priority" != "1" && "$priority" != "2" && "$priority" != "3" ]]; then
                error "$file" "Invalid priority '$priority' (must be 1, 2, or 3)"
            fi

            if [[ "$dir" != "tasks" && "$dir" != "archive" ]]; then
                error "$file" "Task is in wrong directory '$dir' (should be tasks/ or archive/)"
            fi

            # Status-location consistency
            if [[ "$status" == "done" && "$dir" != "archive" ]]; then
                warn "$file" "Task has status 'done' but is not in archive/"
            fi
            if [[ "$dir" == "archive" && "$status" != "done" ]]; then
                error "$file" "Task is in archive/ but status is '${status:-<missing>}' (expected done)"
            fi
            ;;

        epic)
            if [[ -z "$status" ]]; then
                error "$file" "Missing required field: status"
            elif [[ "$status" != "planning" && "$status" != "current" && "$status" != "done" ]]; then
                error "$file" "Invalid status '$status' for epic (must be planning|current|done)"
            fi

            if [[ "$dir" != "planning" && "$dir" != "archive" ]]; then
                error "$file" "Epic is in wrong directory '$dir' (should be planning/ or archive/)"
            fi

            # Status-location consistency
            if [[ "$status" == "done" && "$dir" != "archive" ]]; then
                warn "$file" "Epic has status 'done' but is not in archive/"
            fi
            if [[ "$dir" == "archive" && "$status" != "done" ]]; then
                error "$file" "Epic is in archive/ but status is '${status:-<missing>}' (expected done)"
            fi
            ;;

        adr)
            if [[ -z "$status" ]]; then
                error "$file" "Missing required field: status"
            elif [[ "$status" != "active" && "$status" != "superseded" && "$status" != "deprecated" ]]; then
                error "$file" "Invalid status '$status' for ADR (must be active|superseded|deprecated)"
            fi

            local context_date
            context_date="$(get_field "$file" "context_date")"
            if [[ -z "$context_date" ]]; then
                error "$file" "Missing required field: context_date"
            elif ! echo "$context_date" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
                warn "$file" "Field 'context_date' is not in YYYY-MM-DD format: $context_date"
            fi

            if [[ "$dir" == "archive" ]]; then
                error "$file" "ADR is in archive/ — ADRs must never be archived (move back to planning/)"
            elif [[ "$dir" != "planning" ]]; then
                error "$file" "ADR is in wrong directory '$dir' (should be planning/)"
            fi
            ;;

        reference)
            if [[ -n "$status" ]]; then
                warn "$file" "Reference docs should not have a status field"
            fi

            if [[ "$dir" != "reference" && "$dir" != "archive" ]]; then
                error "$file" "Reference is in wrong directory '$dir' (should be reference/)"
            fi
            ;;

        resource)
            if [[ -z "$status" ]]; then
                error "$file" "Missing required field: status"
            elif [[ "$status" != "inbox" && "$status" != "processing" && "$status" != "processed" ]]; then
                error "$file" "Invalid status '$status' for resource (must be inbox|processing|processed)"
            fi

            local url
            url="$(get_field "$file" "url")"
            if [[ -z "$url" ]]; then
                error "$file" "Missing required field: url"
            fi

            if [[ "$dir" != "resources" && "$dir" != "archive" ]]; then
                error "$file" "Resource is in wrong directory '$dir' (should be resources/ or archive/)"
            fi

            # Status-location consistency
            if [[ "$status" == "processed" && "$dir" != "archive" ]]; then
                warn "$file" "Resource has status 'processed' but is not in archive/"
            fi
            if [[ "$dir" == "archive" && "$status" != "processed" ]]; then
                error "$file" "Resource is in archive/ but status is '${status:-<missing>}' (expected processed)"
            fi
            ;;

        note)
            if [[ -z "$status" ]]; then
                error "$file" "Missing required field: status"
            elif [[ "$status" != "inbox" && "$status" != "processed" ]]; then
                error "$file" "Invalid status '$status' for note (must be inbox|processed)"
            fi

            if [[ "$dir" != "planning" && "$dir" != "archive" ]]; then
                error "$file" "Note is in wrong directory '$dir' (should be planning/ or archive/)"
            fi

            # Status-location consistency
            if [[ "$status" == "processed" && "$dir" != "archive" ]]; then
                warn "$file" "Note has status 'processed' but is not in archive/"
            fi
            if [[ "$dir" == "archive" && "$status" != "processed" ]]; then
                error "$file" "Note is in archive/ but status is '${status:-<missing>}' (expected processed)"
            fi
            ;;

        *)
            error "$file" "Unknown type '$type' (must be task|epic|adr|reference|resource|note)"
            ;;
    esac
}

# --- Validate cross-references ---

# Extract scalar or block-list value for a frontmatter field.
# Handles:
#   field: TASK-0001
#   field: [TASK-0001, TASK-0002]
#   field:
#     - TASK-0001
#     - TASK-0002
# CRLF-tolerant. Emits the raw field contents (may span multiple lines).
get_field_raw() {
    local file="$1" field="$2"
    awk -v f="$field" '
        /^---[[:space:]]*\r?$/ { if (in_fm) exit; in_fm=1; next }
        !in_fm { next }
        {
            if (index($0, f ":") == 1) {
                in_field = 1
                val = substr($0, length(f) + 2)
                sub(/\r$/, "", val)
                sub(/^[[:space:]]+/, "", val)
                if (val != "") print val
                next
            }
            if (in_field) {
                line = $0
                sub(/\r$/, "", line)
                if (line ~ /^[[:space:]]+-[[:space:]]/) {
                    sub(/^[[:space:]]+-[[:space:]]+/, "", line)
                    print line
                    next
                }
                # Any non-indented / non-list-item line ends this field.
                in_field = 0
            }
        }
    ' "$file" 2>/dev/null
}

# Check that every TYPE-NNNN reference in the given field exists in EXISTING_IDS.
check_refs() {
    local file="$1" field="$2"
    local raw
    raw=$(get_field_raw "$file" "$field")
    [[ -z "$raw" ]] && return
    local refs
    refs=$(printf '%s\n' "$raw" | grep -oE '(TASK|EPIC|ADR|REFE|RESO|NOTE)-[0-9]{4}' || true)
    for ref in $refs; do
        if ! grep -qx "$ref" "$EXISTING_IDS" 2>/dev/null; then
            warn "$file" "$field references $ref which does not exist"
        fi
    done
}

# Validate every reference-bearing frontmatter field across all typed files.
validate_references() {
    local dir dirpath file basename
    for dir in tasks planning reference resources archive; do
        dirpath="$BOARD_ROOT/$dir"
        [[ -d "$dirpath" ]] || continue
        for file in "$dirpath"/*.md; do
            [[ -f "$file" ]] || continue
            basename="$(basename "$file")"
            if ! echo "$basename" | grep -qE '^(TASK|EPIC|ADR|REFE|RESO|NOTE)-[0-9]{4}_.+\.md$'; then
                continue
            fi
            check_refs "$file" "blocked_by"
            check_refs "$file" "parent"
            check_refs "$file" "spawned"
            check_refs "$file" "superseded_by"
            check_refs "$file" "supersedes"
        done
    done
}

# --- Main ---

# Check required directories exist
for dir in tasks planning reference resources archive; do
    dirpath="$BOARD_ROOT/$dir"
    if [[ ! -d "$dirpath" ]]; then
        error "$BOARD_ROOT" "Missing required directory: $dir/"
    fi
done

# Scan all active directories
for dir in tasks planning reference resources; do
    dirpath="$BOARD_ROOT/$dir"
    [[ -d "$dirpath" ]] || continue
    for file in "$dirpath"/*.md; do
        [[ -f "$file" ]] || continue
        validate_file "$file"
    done
done

# Scan archive
if [[ -d "$BOARD_ROOT/archive" ]]; then
    for file in "$BOARD_ROOT/archive"/*.md; do
        [[ -f "$file" ]] || continue
        validate_file "$file"
    done
fi

# Validate cross-references
validate_references

# --- Summary ---

if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
    [[ $NO_FAIL -eq 1 ]] || echo "Board lint: all files valid."
    exit 0
elif [[ $errors -eq 0 ]]; then
    echo "Board lint: $warnings warning(s), 0 errors."
    exit 0
elif [[ $NO_FAIL -eq 1 ]]; then
    # Findings went to stderr, which the session hook does not surface — point at the skill
    echo "Board lint: $errors error(s), $warnings warning(s) — run /board:board-lint to review."
    exit 0
else
    echo "Board lint: $errors error(s), $warnings warning(s)."
    exit 1
fi
