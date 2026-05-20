---
type: note
status: inbox
created: 2026-05-19
---

# NOTE-0010: Use plugin manifest `userConfig` to make board path configurable

Claude Code plugins support a `userConfig` field in `plugin.json` that prompts the user once at plugin-enable time for configurable values. See https://code.claude.com/docs/en/plugins-reference#user-configuration.

Today, every script invocation and skill body hardcodes the board location as `./board` relative to the project root. This works for the common case but forecloses any other layout.

## Rationale

- A user might want their board nested somewhere else (e.g., `./.project/board/`, `./docs/board/`) for organizational or visibility reasons.
- A monorepo might have multiple boards (per-package, per-team) — currently impossible without forking the plugin.
- Centralizing the path in `userConfig` would let us reference `${user_config.board_path}` in skill bodies, hook commands, and script invocations instead of repeating `./board` everywhere.

## Open Questions

- Single `board_path` value, or also expose other knobs (default item type, default priority, archive retention)?
- How does this interact with the SessionStart auto-lint hook — does the hook need to read `${user_config.board_path}` too?
- What's the migration story for existing installations? `userConfig` is prompted at enable time; do existing users get re-prompted, or only new installs?
- Does `userConfig` substitution work inside `` !`bash ...` `` dynamic context injection in skill frontmatter?

## Next Steps (when processed)

- Inventory every hardcoded `./board` reference across `plugin/scripts/`, `plugin/skills/`, and `plugin/hooks/`
- Prototype the `userConfig` declaration in `plugin.json` with `board_path` (string, default `./board`)
- Test that `${user_config.board_path}` substitution flows correctly into script args and skill content
- Decide scope: just `board_path` first, or bundle several config knobs together
