---
type: task
status: backlog
priority: 1
parent: EPIC-0001
created: 2026-02-24
---

# TASK-0003: Capture stderr in archive-batch.sh error handling

## Description

`archive-batch.sh` redirects all `git mv` and `mv` stderr to `/dev/null` (lines 68 and 73). When archiving fails, the user gets a generic "git mv failed — check for uncommitted changes" with no actual error message. Real errors (permission denied, disk full, cross-device move, git index lock) are silently discarded.

## Changes Required

Replace `2>/dev/null` with stderr capture:

```bash
if $use_git; then
    err_output=$(git mv "$file" "$dest" 2>&1) || {
        skipped+=("$file (git mv failed: $err_output)")
        continue
    }
else
    err_output=$(mv "$file" "$dest" 2>&1) || {
        skipped+=("$file (mv failed: $err_output)")
        continue
    }
fi
```
