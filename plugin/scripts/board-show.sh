#!/usr/bin/env bash
# board-show.sh — Output a fully formatted board overview as markdown.
# Usage: board-show.sh [board_root]
#   board_root defaults to ./board
#
# Produces a complete markdown board view with:
#   - Current items (in progress)
#   - Backlog items (ready), sorted by priority
#   - Backlog items (blocked), with blocker info
#   - Epics with child task progress
#   - Planning items (ADRs, NOTEs)
#   - Resource inbox
#   - Stats summary with archive counts
#
# This script is designed for deterministic output — the LLM should
# display it verbatim with no additional reasoning or commands.

set -euo pipefail

BOARD_ROOT="${1:-./board}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Guard: board directory must exist
if [[ ! -d "$BOARD_ROOT" ]]; then
    printf '## Project Board\n\nNo board directory found at `%s`. Run `/board:board-init` to set up.\n' "$BOARD_ROOT"
    exit 0
fi

# --- Collect raw TSV data ---

# Active items (skip header line)
tsv_active="$("$SCRIPT_DIR/board-scan.sh" "$BOARD_ROOT" --active | tail -n +2)"

# Archive counts (skip header + blank lines, get only count lines)
tsv_archive="$("$SCRIPT_DIR/board-scan.sh" "$BOARD_ROOT" --archive-summary 2>/dev/null)"
archive_counts=""
if printf '%s' "$tsv_archive" | grep -q '^# Archive counts'; then
    archive_counts="$(printf '%s' "$tsv_archive" | sed -n '/^# Archive counts/,$ { /^# Archive/d; /^$/d; p; }')"
fi

# --- Helper: check if a blocker ID is resolved (status=done) ---
# Returns 0 if resolved, 1 if not
is_resolved() {
    local blocker_id="$1"
    local blocker_line
    # Match on filepath column (column 1) which contains the ID in the filename
    blocker_line="$(printf '%s\n' "$tsv_active" | grep "/${blocker_id}_" || true)"
    if [[ -z "$blocker_line" ]]; then
        # Blocker not in active items — might be archived (done) or missing
        if [[ -d "$BOARD_ROOT/archive" ]]; then
            for f in "$BOARD_ROOT/archive/${blocker_id}_"*.md; do
                [[ -f "$f" ]] && return 0
            done
        fi
        return 1
    fi
    local blocker_status
    blocker_status="$(printf '%s' "$blocker_line" | cut -f3)"
    [[ "$blocker_status" == "done" ]]
}

# --- Helper: check if an item is blocked (any unresolved blocker) ---
# Input: comma-separated blocker IDs or "-"
# Returns 0 if blocked, 1 if not blocked
is_blocked() {
    local blocked_by="$1"
    [[ "$blocked_by" == "-" || -z "$blocked_by" ]] && return 1

    local IFS=','
    for bid in $blocked_by; do
        # Trim whitespace
        bid="$(printf '%s' "$bid" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        if ! is_resolved "$bid"; then
            return 0
        fi
    done
    return 1
}

# --- Helper: get archive count for a type ---
get_archive_count() {
    local type_upper="$1"
    local result="0"
    if [[ -n "$archive_counts" ]]; then
        while IFS=$'\t' read -r atype acount; do
            if [[ "$atype" == "$type_upper" ]]; then
                result="$acount"
                break
            fi
        done <<< "$archive_counts"
    fi
    printf '%s' "$result"
}

# --- Helper: strip ID prefix from title (e.g., "TASK-0001: Foo" → "Foo") ---
strip_id_prefix() {
    local title="$1"
    printf '%s' "$title" | sed 's/^[A-Z]*-[0-9]*:[[:space:]]*//'
}

# --- Helper: extract ID from filepath ---
extract_id() {
    local filepath="$1"
    basename "$filepath" | sed 's/_.*//; s/\.md$//'
}

# --- Categorize items ---

# Parallel arrays for each category
current_tasks=""
backlog_ready=""
backlog_blocked=""
epics=""
adrs=""
notes_inbox=""
resource_inbox=""

# Task counters
task_current=0
task_backlog_ready=0
task_backlog_blocked=0
epic_current=0
epic_planning=0

while IFS=$'\t' read -r filepath type status priority blocked_by parent title; do
    [[ -z "$filepath" ]] && continue

    item_id="$(extract_id "$filepath")"
    clean_title="$(strip_id_prefix "$title")"

    case "$type" in
        task)
            case "$status" in
                current)
                    current_tasks="${current_tasks}${item_id}	${clean_title}	${priority}	${blocked_by}
"
                    task_current=$((task_current + 1))
                    ;;
                backlog)
                    if is_blocked "$blocked_by"; then
                        backlog_blocked="${backlog_blocked}${item_id}	${clean_title}	${priority}	${blocked_by}
"
                        task_backlog_blocked=$((task_backlog_blocked + 1))
                    else
                        backlog_ready="${backlog_ready}${item_id}	${clean_title}	${priority}	${blocked_by}
"
                        task_backlog_ready=$((task_backlog_ready + 1))
                    fi
                    ;;
            esac
            ;;
        epic)
            epics="${epics}${item_id}	${clean_title}	${status}
"
            case "$status" in
                current) epic_current=$((epic_current + 1)) ;;
                planning) epic_planning=$((epic_planning + 1)) ;;
            esac
            ;;
        adr)
            adrs="${adrs}${item_id}	${clean_title}	${status}
"
            ;;
        note)
            if [[ "$status" == "inbox" ]]; then
                notes_inbox="${notes_inbox}${item_id}	${clean_title}
"
            fi
            ;;
        resource)
            if [[ "$status" == "inbox" || "$status" == "processing" ]]; then
                resource_inbox="${resource_inbox}${item_id}	${clean_title}	${status}
"
            fi
            ;;
    esac
done <<< "$tsv_active"

# --- Helper: count epic children ---
# Returns "done/total" for a given epic ID
epic_progress() {
    local epic_id="$1"
    local total=0
    local done=0
    while IFS=$'\t' read -r filepath type status priority blocked_by parent title; do
        [[ -z "$filepath" ]] && continue
        if [[ "$type" == "task" && "$parent" == "$epic_id" ]]; then
            total=$((total + 1))
            [[ "$status" == "done" ]] && done=$((done + 1))
        fi
    done <<< "$tsv_active"
    # Also check archive for done children
    if [[ -d "$BOARD_ROOT/archive" ]]; then
        for f in "$BOARD_ROOT/archive"/TASK-*.md; do
            [[ -f "$f" ]] || continue
            local file_parent=""
            file_parent="$(awk '/^---$/{fm++; next} fm==1 && /^parent:/{sub(/^parent:[[:space:]]*/,""); gsub(/[[:space:]]*$/,""); gsub(/"/,""); print; exit}' "$f")"
            if [[ "$file_parent" == "$epic_id" ]]; then
                total=$((total + 1))
                done=$((done + 1))
            fi
        done
    fi
    printf '%s/%s' "$done" "$total"
}

# --- Sort helper: sort lines by priority (field 3, numeric) then by ID (field 1) ---
sort_by_priority() {
    printf '%s' "$1" | sort -t$'\t' -k3,3n -k1,1
}

# --- Output ---

printf '## Project Board\n\n'

# Current (in progress)
printf '### Current (in progress)\n'
if [[ -n "$current_tasks" ]]; then
    sorted="$(sort_by_priority "$current_tasks")"
    while IFS=$'\t' read -r id title priority blocked_by; do
        [[ -z "$id" ]] && continue
        printf -- '- %s: %s [priority: %s]\n' "$id" "$title" "$priority"
    done <<< "$sorted"
else
    printf -- '- _(none)_\n'
fi
printf '\n'

# Backlog (ready)
printf '### Backlog (ready)\n'
if [[ -n "$backlog_ready" ]]; then
    sorted="$(sort_by_priority "$backlog_ready")"
    while IFS=$'\t' read -r id title priority blocked_by; do
        [[ -z "$id" ]] && continue
        printf -- '- %s: %s [priority: %s]\n' "$id" "$title" "$priority"
    done <<< "$sorted"
else
    printf -- '- _(none)_\n'
fi
printf '\n'

# Backlog (blocked)
printf '### Backlog (blocked)\n'
if [[ -n "$backlog_blocked" ]]; then
    sorted="$(sort_by_priority "$backlog_blocked")"
    while IFS=$'\t' read -r id title priority blocked_by; do
        [[ -z "$id" ]] && continue
        printf -- '- %s: %s [blocked by: %s]\n' "$id" "$title" "$blocked_by"
    done <<< "$sorted"
else
    printf -- '- _(none)_\n'
fi
printf '\n'

# Epics
printf '### Epics\n'
if [[ -n "$epics" ]]; then
    printf '%s' "$epics" | while IFS=$'\t' read -r id title status; do
        [[ -z "$id" ]] && continue
        progress="$(epic_progress "$id")"
        printf -- '- %s: %s [%s] — %s tasks done\n' "$id" "$title" "$status" "$progress"
    done
else
    printf -- '- _(none)_\n'
fi
printf '\n'

# Planning (ADRs + inbox NOTEs)
if [[ -n "$adrs" || -n "$notes_inbox" ]]; then
    printf '### Planning\n'
    if [[ -n "$adrs" ]]; then
        printf '%s' "$adrs" | while IFS=$'\t' read -r id title status; do
            [[ -z "$id" ]] && continue
            printf -- '- %s: %s [%s]\n' "$id" "$title" "$status"
        done
    fi
    if [[ -n "$notes_inbox" ]]; then
        printf '%s' "$notes_inbox" | while IFS=$'\t' read -r id title; do
            [[ -z "$id" ]] && continue
            printf -- '- %s: %s [inbox]\n' "$id" "$title"
        done
    fi
    printf '\n'
fi

# Resource Inbox
printf '### Resource Inbox\n'
if [[ -n "$resource_inbox" ]]; then
    printf '%s' "$resource_inbox" | while IFS=$'\t' read -r id title status; do
        [[ -z "$id" ]] && continue
        printf -- '- %s: %s [%s]\n' "$id" "$title" "$status"
    done
else
    printf -- '- _(none)_\n'
fi
printf '\n'

# Stats
task_archived="$(get_archive_count "TASK")"
epic_archived="$(get_archive_count "EPIC")"

task_total_backlog=$((task_backlog_ready + task_backlog_blocked))

printf '### Stats\n'
printf -- '- Tasks: %s current, %s backlog (%s ready, %s blocked), %s archived\n' \
    "$task_current" "$task_total_backlog" "$task_backlog_ready" "$task_backlog_blocked" "$task_archived"
printf -- '- Epics: %s current, %s planning, %s archived\n' \
    "$epic_current" "$epic_planning" "$epic_archived"

exit 0
