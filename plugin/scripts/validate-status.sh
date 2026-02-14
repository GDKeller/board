#!/usr/bin/env bash
# validate-status.sh — Validate a board item status transition.
# Usage: validate-status.sh <type> <from_status> <to_status>
#
# Exits with 0 if the transition is valid (forward).
# Exits with 1 if the transition is invalid.
# Exits with 2 if the transition is backward (valid but should confirm with user).
#
# Output: "valid", "invalid", or "backward" followed by a description.

set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: validate-status.sh <type> <from_status> <to_status>" >&2
    exit 1
fi

TYPE="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
FROM="$2"
TO="$3"

# Same status is a no-op
if [[ "$FROM" == "$TO" ]]; then
    echo "valid: no change (already $FROM)"
    exit 0
fi

check_transition() {
    local valid_forward="$1"
    local valid_backward="$2"

    # Check forward transitions
    for transition in $valid_forward; do
        local f="${transition%%>*}"
        local t="${transition##*>}"
        if [[ "$FROM" == "$f" && "$TO" == "$t" ]]; then
            echo "valid: $FROM -> $TO"
            exit 0
        fi
    done

    # Check backward transitions
    for transition in $valid_backward; do
        local f="${transition%%>*}"
        local t="${transition##*>}"
        if [[ "$FROM" == "$f" && "$TO" == "$t" ]]; then
            echo "backward: $FROM -> $TO (confirm with user — may indicate reopened item)"
            exit 2
        fi
    done

    echo "invalid: $FROM -> $TO is not a valid transition for $TYPE"
    exit 1
}

case "$TYPE" in
    task)
        # Forward: backlog -> current -> done
        # Backward: current -> backlog, done -> current, done -> backlog
        check_transition \
            "backlog>current current>done backlog>done" \
            "current>backlog done>current done>backlog"
        ;;
    epic)
        # Forward: planning -> current -> done
        # Backward: current -> planning, done -> current, done -> planning
        check_transition \
            "planning>current current>done planning>done" \
            "current>planning done>current done>planning"
        ;;
    adr)
        # Forward: active -> superseded, active -> deprecated
        # No backward transitions for ADRs
        check_transition \
            "active>superseded active>deprecated" \
            ""
        ;;
    resource)
        # Forward: inbox -> processing -> processed
        # Backward: processing -> inbox, processed -> processing, processed -> inbox
        check_transition \
            "inbox>processing processing>processed inbox>processed" \
            "processing>inbox processed>processing processed>inbox"
        ;;
    note)
        # Forward: inbox -> processed
        # Backward: processed -> inbox
        check_transition \
            "inbox>processed" \
            "processed>inbox"
        ;;
    reference)
        echo "invalid: reference documents have no status field"
        exit 1
        ;;
    *)
        echo "invalid: unknown type '$TYPE'" >&2
        exit 1
        ;;
esac
