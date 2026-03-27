---
type: task
status: backlog
priority: 2
parent: EPIC-0002
created: 2026-03-26
---

# TASK-0021: Add guards for empty, binary, symlink, frontmatter-only, and large files

The discovery and classification steps have no handling for degenerate file states. Add guards to Step 4 (classification) and Step 2 (discovery).

## Requirements

- **Empty/whitespace-only files (M11):** If the file is empty or whitespace-only after reading, skip automatically. Report as "skipped (no content)" in post-migration summary.
- **Binary files (L1):** If file content appears binary (non-UTF-8, NUL bytes, garbled output), skip and report as "skipped (binary content)."
- **Symlinks (M13):** If a candidate is a symlink, skip and note to user — symlinks require manual handling to avoid ambiguous `git rm` behavior.
- **Frontmatter-only files (M12):** If stripping frontmatter leaves zero body content, surface to the user and ask whether to skip, fold frontmatter into body as prose, or create a stub item.
- **Very large files (M14):** If a file exceeds 500 lines, warn the user and ask whether to: (a) proceed with full read, (b) classify from first 50 lines and migrate full content, or (c) skip.
- **Filename collisions (L3):** If two candidates would produce the same target filename, disambiguate by incorporating path context into the kebab title or ask the user to rename.

## Findings addressed

- M11, M12, M13, M14, L1, L3 from [[NOTE-0004]]
