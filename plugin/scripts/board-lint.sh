#!/usr/bin/env bash
# board-lint.sh — Validate all board files for structural and data issues.
# Usage: board-lint.sh [board_root]
#   board_root defaults to ./board
#
# Compatible with bash 3.2+ (macOS default).
#
# Exit codes:
#   0 — no issues (or no board/ directory found)
#   1 — errors found
#
# Output format:
#   ERROR: <file>: <message>
#   WARN:  <file>: <message>

set -euo pipefail

BOARD_ROOT="${1:-./board}"

# If no board directory exists, report and exit clean (not every project uses board)
if [[ ! -d "$BOARD_ROOT" ]]; then
    echo "Board lint: no board/ directory found at $BOARD_ROOT — skipping."
    exit 0
fi

errors=0
warnings=0

# Temp files for tracking (avoids bash 4 associative arrays)
ID_TRACKER=$(mktemp)
EXISTING_IDS=$(mktemp)
trap 'rm -f "$ID_TRACKER" "$EXISTING_IDS"' EXIT

error() {
    echo "ERROR: $1: $2"
    errors=$((errors + 1))
}

warn() {
    echo "WARN:  $1: $2"
    warnings=$((warnings + 1))
}

# --- Helpers ---

# Extract a frontmatter field value from a file (first 30 lines)
get_field() {
    local file="$1" key="$2"
    local match
    match=$(head -30 "$file" | sed -n '/^---$/,/^---$/p' | grep "^${key}:" | head -1 || true)
    if [[ -z "$match" ]]; then
        echo ""
        return
    fi
    echo "$match" | sed "s/^${key}:[[:space:]]*//" | sed "s/^[\"']//" | sed "s/[\"']$//" | tr -d ' '
}

# Check if frontmatter exists
has_frontmatter() {
    head -1 "$1" | grep -q '^---$'
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

    # Check frontmatter exists
    if ! has_frontmatter "$file"; then
        error "$file" "Missing YAML frontmatter (no opening ---)"
        return
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

    # Check created field
    local created
    created="$(get_field "$file" "created")"
    if [[ -z "$created" ]]; then
        warn "$file" "Missing field: created"
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
                warn "$file" "Missing field: context_date"
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
                warn "$file" "Missing field: url"
            fi

            if [[ "$dir" != "resources" && "$dir" != "archive" ]]; then
                error "$file" "Resource is in wrong directory '$dir' (should be resources/ or archive/)"
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
            ;;
    esac
}

# --- Validate blocked_by references ---

validate_references() {
    for dir in tasks archive; do
        local dirpath="$BOARD_ROOT/$dir"
        [[ -d "$dirpath" ]] || continue
        for file in "$dirpath"/TASK-*.md; do
            [[ -f "$file" ]] || continue

            # Extract blocked_by content from frontmatter
            local blocked_by=""
            local in_fm=0 in_bb=0
            while IFS= read -r line; do
                if [[ "$line" == "---" ]]; then
                    if [[ $in_fm -eq 1 ]]; then break; fi
                    in_fm=1; continue
                fi
                if [[ $in_fm -eq 1 ]]; then
                    if [[ "$line" == blocked_by:* ]]; then
                        local val="${line#blocked_by:}"
                        val="${val#"${val%%[![:space:]]*}"}"
                        if [[ -n "$val" ]]; then
                            blocked_by="$val"
                        else
                            in_bb=1
                        fi
                    elif [[ $in_bb -eq 1 && "$line" =~ ^[[:space:]]+-[[:space:]] ]]; then
                        blocked_by="$blocked_by ${line#*- }"
                    elif [[ $in_bb -eq 1 ]]; then
                        in_bb=0
                    fi
                fi
            done < "$file"

            # Parse TASK-NNNN references and check they exist
            if [[ -n "$blocked_by" ]]; then
                local refs
                refs=$(echo "$blocked_by" | grep -oE 'TASK-[0-9]{4}' || true)
                for ref in $refs; do
                    if ! grep -q "^${ref}$" "$EXISTING_IDS" 2>/dev/null; then
                        warn "$file" "blocked_by references $ref which does not exist"
                    fi
                done
            fi
        done
    done
}

# --- Main ---

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
    echo "Board lint: all files valid."
    exit 0
elif [[ $errors -eq 0 ]]; then
    echo ""
    echo "Board lint: $warnings warning(s), 0 errors."
    exit 0
else
    echo ""
    echo "Board lint: $errors error(s), $warnings warning(s)."
    exit 1
fi
