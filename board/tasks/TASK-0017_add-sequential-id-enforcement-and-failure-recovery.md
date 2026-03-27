---
type: task
status: backlog
priority: 1
parent: EPIC-0002
created: 2026-03-26
---

# TASK-0017: Add sequential ID assignment enforcement and mid-run failure recovery

## ID assignment (H1)

The LLM may parallelize `next-id.sh` calls, causing every call to return the same ID. Make the interleave constraint explicit and unmissable:

> **CRITICAL:** Assign ID → Write file to disk → Assign next ID → Write next file. Never batch ID assignments. Each file must exist on disk before the next ID is requested.

## Mid-run failure recovery (M7, H4, L5)

- If any single file fails during execution, log it as "failed" in the post-migration summary, continue with remaining files, and report all failures at the end
- Document that interrupted migrations are safe to re-run: the `TYPE-NNNN_*.md` exclusion filter prevents re-discovery of already-migrated files
- Note in recovery guidance: check for orphaned originals that duplicate content of existing board items (crash between Write and `git rm`)
- Suggest running `board-lint` to verify migrated files after any partial completion

## Findings addressed

- H1, H4, M7, L5 from [[NOTE-0004]]
