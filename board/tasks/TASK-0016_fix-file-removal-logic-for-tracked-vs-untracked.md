---
type: task
status: backlog
priority: 1
parent: EPIC-0002
created: 2026-03-26
---

# TASK-0016: Fix file removal logic for tracked vs untracked files

The skill unconditionally uses `git rm` to remove source files, but untracked files and files with staged changes will cause `git rm` to fail.

## Requirements

- Before removing each source file, check if it's git-tracked: `git ls-files --error-unmatch "<path>" 2>/dev/null`
- If tracked: use `git rm`
- If untracked: use plain `rm`
- Always double-quote file paths in all Bash calls to handle spaces and special characters (L6)
- Note the distinction (tracked vs untracked removal) in the post-migration report
- Replace the "Git's rename detection will still link the history" guarantee with a best-effort note (M6): git may detect the rename, but it's not guaranteed when content changes significantly

## Findings addressed

- M4, M6, L6 from [[NOTE-0004]]
