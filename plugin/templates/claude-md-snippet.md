## Project Board

This project uses the Board plugin for project management: tasks, epics, ADRs, notes, references, and resources live as Markdown files under `board/`. The board skills carry the rules they need; the full spec ships with the plugin.

- **Ask before creating new board files** — don't auto-create tasks, ADRs, etc.
- Use `/board:board-show` to see current board state
- Use `/board:board-check` when starting work to find related board context
- Use `/board:board-add` to create new items and `/board:board-edit` to change them
- Use `/board:board-update` after completing significant work to reconcile the board
- Use `/board:board-archive` to move done items to `board/archive/`
- Use `/board:board-lint` when the session-start lint reports errors
- Use `/board:board-migrate` to import existing Markdown docs into the board
