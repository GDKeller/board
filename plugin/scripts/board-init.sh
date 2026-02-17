#!/usr/bin/env bash
# board-init.sh — Initialize the board system in a project directory.
# Usage: board-init.sh <plugin_root> [project_root]
#   plugin_root: path to the plugin directory (for templates)
#   project_root: project directory to initialize (defaults to current directory)
#
# Creates:
#   board/{tasks,planning,reference,resources,archive}/
#   board/.doc-ids
#
# Exits with 0 on success. Prints what was created to stdout.
# If board/ already exists, only copies missing files (safe to re-run).

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: board-init.sh <plugin_root> [project_root]" >&2
    exit 1
fi

PLUGIN_ROOT="$1"
PROJECT_ROOT="${2:-.}"
BOARD_ROOT="$PROJECT_ROOT/board"
TEMPLATES="$PLUGIN_ROOT/templates"

# Verify templates exist
if [[ ! -d "$TEMPLATES" ]]; then
    echo "Error: Templates directory not found at $TEMPLATES" >&2
    exit 1
fi

created=()
skipped=()

# Create directory structure
for dir in tasks planning reference resources archive; do
    dirpath="$BOARD_ROOT/$dir"
    if [[ ! -d "$dirpath" ]]; then
        mkdir -p "$dirpath"
        created+=("$dirpath/")
    else
        skipped+=("$dirpath/ (already exists)")
    fi
done

# Create .doc-ids tracking file
doc_ids="$BOARD_ROOT/.doc-ids"
if [[ ! -f "$doc_ids" ]]; then
    cat > "$doc_ids" << 'EOF'
TASK=0000
EPIC=0000
ADR=0000
REFE=0000
RESO=0000
NOTE=0000
EOF
    created+=("$doc_ids")
else
    skipped+=("$doc_ids (already exists)")
fi

# Report results
if [[ ${#created[@]} -gt 0 ]]; then
    echo "Created:"
    for item in "${created[@]}"; do
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
echo "Board initialized at $BOARD_ROOT"

# Output the CLAUDE.md snippet path for the caller to handle
echo "CLAUDE_SNIPPET=$TEMPLATES/claude-md-snippet.md"
