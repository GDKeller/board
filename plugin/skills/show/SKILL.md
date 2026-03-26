---
name: board-show
description: "Displays a formatted project board overview grouped by status, with priority sorting, epic progress, blocking relationships, and archive statistics. Activates when the user asks to see the board, show tasks, view backlog, or check project status, or via '/board:board-show'."
disable-model-invocation: true
allowed-tools: ""
---

# Board Overview

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/board-show.sh ./board`

Display the above output to the user exactly as-is. Do not modify, reformat, or run any additional commands.

**Avoid redundant invocations** — if board data from this skill is already present in context and no board modifications have been made since, use that data rather than invoking this skill again.
