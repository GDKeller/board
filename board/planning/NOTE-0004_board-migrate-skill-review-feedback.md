---
type: note
status: inbox
created: 2026-03-26
---

# NOTE-0004: Board-migrate skill review feedback

Consolidated review findings from four parallel agents reviewing the `board-migrate` skill (`plugin/skills/migrate/SKILL.md`) for robustness, stability, edge cases, and gotchas.

## HIGH Severity (5 findings)

### H1: ID collision from batched assignment

`next-id.sh` scans disk for the highest existing ID. The skill says "run sequentially" but does not explicitly require writing the file to disk before calling `next-id.sh` again. If the LLM batches all ID assignments first (five calls) then all writes, every call returns the same ID — producing duplicate filenames and data loss.

**Fix:** Make the interleave constraint explicit and unmissable: "CRITICAL: Assign ID → Write file to disk → Assign next ID → Write next file. Never batch ID assignments. Each file must exist on disk before the next ID is requested."

- Source: Git ops review, Edge case review

### H2: `context_date` defaults to today for migrated ADRs

The spec defines `context_date` as "when this decision was made." For a decision documented in an existing file being migrated, the decision date is almost certainly NOT today — it was made whenever the source file was written. Setting `context_date` to today misrepresents the historical record. This is particularly severe because ADRs are immutable once created — there is no correcting a wrong `context_date` later without creating an entirely new ADR.

**Fix:** Change the instruction to: "ADRs get `status: active` and `context_date` set to the decision date — infer from file content, git history (`git log --follow <file>`), or ask the user if unclear. Do NOT default to today."

- Source: Spec consistency review

### H3: Too many blocking prompts

The flow requires at least 3 sequential user interactions before any files are touched: (a) "any additional directories?", (b) >15 files scope confirmation, (c) plan review/approval. For a typical 5-file migration this is two unnecessary gates. The `board-update` skill achieves a similar "plan then execute" flow with a single approval gate.

**Fix:** Remove the upfront directory prompt. Instead, scan defaults plus any path provided in `$ARGUMENTS`. In the discovery results step, note: "If there are files in other locations you'd like to include, tell me and I'll re-scan." This converts the upfront gate into an inline escape hatch. Remove the >15 files confirmation — let the user trim in the plan review step instead.

- Source: UX flow review

### H4: No partial completion / abort recovery

If the user says "stop" or closes the session after 3 of 5 files are migrated, originals for those 3 are already `git rm`'d and new board files exist. There is no instruction explaining what state the board is in, how to detect partial completion, or how to resume. The existing `TYPE-NNNN_*.md` exclusion filter means already-migrated files won't be re-discovered on a second run, but this implicit safety net is not documented.

**Fix:** Add a note in the execution step: "If execution is interrupted, the next invocation will automatically skip already-migrated files (the `TYPE-NNNN_*.md` exclusion filter prevents re-discovery). Report partial completion at the top of the post-migration report if `--active` board data shows newly created items that weren't in the original plan. Suggest the user run `board-lint` to verify migrated files are valid."

- Source: UX flow review

### H5: User-supplied path not validated

The `[path]` argument-hint implies the user can pass a custom path, and the skill says "scan those recursively" but gives no instruction to validate the path exists and is a directory before scanning. A typo or nonexistent path would silently produce zero candidates with no explanation.

**Fix:** Add to the discovery step: "Before scanning a user-supplied path, verify it exists and is a directory. If not, report the specific invalid path and ask the user to correct it before continuing."

- Source: Edge case review

## MEDIUM Severity (14 findings)

### M1: No explicit frontmatter templates in Step 6

Step 6 describes what fields to set per type in prose ("Tasks get `status: backlog`, `priority: 2`") but provides no YAML template blocks. The `board-add` skill provides explicit YAML template blocks for all six types showing exact structure. Without templates, the LLM must reconstruct correct frontmatter from memory during execution, increasing the risk of field omissions or ordering inconsistencies.

**Fix:** Add inline YAML template blocks in Step 6 for all six types, matching the canonical forms in `board-system-quickref.md` and `board-add`.

- Source: Spec consistency review

### M2: ADR body structure not enforced

The spec mandates ADR bodies include specific sections: Context, Considered Approaches, Decision, Consequences, and Spawned Items. `board-lint.sh` validates the presence of "Spawned Items" at minimum. Step 6 says to carry over body content from the original file, but a migrated ADR whose source document doesn't have these sections will immediately fail lint. The skill does not scaffold missing sections or warn the user.

**Fix:** Add a note in Step 6 for ADR migration: "ADR body must include the required sections: Context, Considered Approaches, Decision, Consequences, and Spawned Items. If the source file lacks these, scaffold the section headers and populate from available content. Always include `## Spawned Items` — use 'No follow-up needed' if nothing applies."

- Source: Spec consistency review

### M3: RESO `url` treated as optional, but spec says required

The spec marks `url` as a **required** field for resource frontmatter. The skill says "ask user for `url` if not evident from content" — treating it as optional in practice. Execution could proceed with a resource missing the `url` field if the user is non-responsive. Additionally, the URL prompt happens during Step 6 (execution), not during plan review — meaning migration can stall mid-run waiting for a URL the user doesn't have handy.

**Fix:** (1) Strengthen to: "Resources require `url` (required field). Do not create a resource without a URL." (2) Move the URL prompt to the plan presentation step: "Item #5 is classified as a resource — do you have a URL? (You can reclassify as a note if no URL is available.)" This surfaces the dependency before execution begins.

- Source: Spec consistency review, UX flow review

### M4: `git rm` on untracked files will fail

The skill targets arbitrary `.md` files from the project root and `docs/`. These files may not be tracked by git (e.g., newly created files, files in a freshly cloned repo with unstaged additions). Running `git rm` on an untracked file errors with "pathspec did not match any files." The board file would already have been written at this point, leaving an orphaned original and a broken migration step.

**Fix:** Before removing each source file, check if it's git-tracked: `git ls-files --error-unmatch "<path>" 2>/dev/null`. If tracked, use `git rm`. If untracked, use plain `rm`. Note the distinction in the post-migration report.

- Source: Edge case review, Git ops review, Spec consistency review

### M5: No dirty working tree pre-flight

If the working tree has staged or unstaged changes before migration starts, `git rm` calls intermingle migration operations with pre-existing work. This makes partial-failure recovery difficult — you can't cleanly `git checkout -- .` to undo just the migration. Additionally, if a candidate file has staged (but uncommitted) changes, `git rm` will fail with "staged content different from HEAD."

**Fix:** Add a pre-flight step after "Confirm Board Exists": run `git status --porcelain` and warn the user if there are staged or unstaged changes. Recommend committing or stashing before proceeding. This is advisory, not blocking — the user can choose to continue.

- Source: Git ops review

### M6: Rename detection overconfidence

The skill states "Git's rename detection will still link the history" as fact. Git's rename detection relies on content similarity (default 50% threshold). When a file gains new frontmatter, a restructured body, and a completely different filename, the similarity score may fall below the threshold and history appears broken — the old file shows as deleted and the new one as added with no connection.

**Fix:** Replace the guarantee with a best-effort note: "Git may detect this as a rename and preserve history linkage, but this is not guaranteed when content changes significantly. If history continuity is important, the user can verify with `git log --follow <new-path>` after migration."

- Source: Git ops review

### M7: No mid-run failure recovery

If `git rm` or file creation fails on file 3 of 5, files 1 and 2 are already migrated with originals removed. The skill provides no guidance on whether to stop, continue with remaining files, or how to report the partial state. A crash between Write and `git rm` also leaves duplicates — the original survives and may be re-discovered on the next migration run.

**Fix:** Add failure-handling guidance: "If any single file fails during execution, log it as 'failed' in the post-migration summary, continue with remaining files, and report all failures at the end. Suggest running `board-lint` to verify the migrated files, and note any orphaned originals that may need manual cleanup."

- Source: Git ops review

### M8: Markdown table won't render in terminal

Claude Code's terminal output does not render markdown tables — they appear as raw pipe-delimited text, which becomes hard to scan with long file paths. The `board-update` skill avoids this with a plain bullet list structure, and `board-lint` uses grouped lists under headers.

**Fix:** Replace the table in the plan presentation with a numbered list format:
```
## Migration Plan (5 files)

1. docs/auth-design.md → ADR: "Chose JWT for session management"
   Target: board/planning/ADR-0003_chose-jwt-for-session-management.md
2. docs/api-endpoints.md → reference: "API endpoint reference"
   Target: board/reference/REFE-0004_api-endpoint-reference.md
```
This is scannable without markdown rendering and supports the "reclassify #2" shorthand naturally.

- Source: UX flow review

### M9: Accept/reclassify/skip/rename interaction underspecified

The approval prompt lists four operations but gives no examples of how to express them. Users will say things like "3 should be a note" or "skip 4 and 6" and the skill should handle these naturally. There's also no example of bulk operations or a simple "looks good, proceed" affirmation.

**Fix:** Add inline examples to the approval prompt:
> - Accept all: "looks good" or "proceed"
> - Reclassify: "#2 should be a note", "make 3 an epic"
> - Skip: "skip #4", "skip 4 and 6"
> - Rename: "#1 title should be 'Adopt JWT over sessions'"
> - Bulk: "make 2, 3, and 5 all notes"

Also add: "Handle bulk operations in the user's reply — apply all stated changes to the plan before re-presenting for final confirmation."

- Source: UX flow review

### M10: Full file read for every candidate is expensive

Step 4 instructs reading "the full file" for every candidate with no batching, prioritization, or context budget guidance. For 20+ files this will exhaust context. Compare to `board-update` Step 2 which uses progressive escalation (title scan -> read with limit:15 -> full read only when needed).

**Fix:** Restructure Step 4's read strategy: "For each candidate: (a) read with `limit: 30` to get heading + opening content — this is sufficient for most classifications. (b) Only do a full read if the classification is ambiguous after the preview or the file's purpose is unclear from the opening. If there are >10 candidates, process in batches of 5 and present partial plans as each batch completes."

Note: The original skill was written with full reads because the user noted "the first 20 lines may not be sufficient." The limit:30 approach is a middle ground — enough to capture most document structure without the context cost of full reads on every file.

- Source: UX flow review

### M11: Empty / whitespace-only files not handled

Step 4 instructs "Read the full file" with no fallback for files that have no classifiable content. The LLM will likely hallucinate a classification for empty or whitespace-only files.

**Fix:** Add a guard in Step 4: "If the file is empty or contains only whitespace after reading, skip it automatically and report it in the post-migration summary as 'skipped (no content).'"

- Source: Edge case review

### M12: Frontmatter-only files leave empty body

Step 4 says to strip existing frontmatter and fold useful context into the body. If the entire file IS frontmatter (e.g., a YAML config file with `.md` extension, or a document that's all metadata), the resulting board item would have an empty body.

**Fix:** Add: "If stripping frontmatter leaves zero body content, surface this to the user and ask whether to skip the file, fold the frontmatter key-value pairs into the body as prose, or create a stub board item."

- Source: Edge case review

### M13: Symlinks can cause double-processing or ambiguous git rm

Glob may resolve symlinks, potentially discovering the same file twice (once via the symlink, once via the real path). More critically, `git rm` on a symlink removes only the symlink, not the target — the target file remains unmodified while a new board file was created from its content, resulting in silent duplication.

**Fix:** Add to the discovery step: "If a candidate appears to be a symlink, skip it and note it to the user — symlinks require manual handling to avoid ambiguous `git rm` behavior."

- Source: Edge case review

### M14: Very large files (>500 lines) blow context budget

Step 4 says "Read the full file" with no size guidance. A very large file (e.g., a 10,000-line generated API doc) consumes substantial context budget during classification. Step 6's "preserve content faithfully" means the Write call will also be very large, potentially exceeding tool limits or degrading performance.

**Fix:** Add a size threshold: "If a file exceeds 500 lines, warn the user and ask whether to: (a) proceed with full read and migration, (b) read only the first 50 lines for classification and migrate the full content without reading it all, or (c) skip the file."

- Source: Edge case review

## LOW Severity (7 findings)

### L1: Binary files with .md extension

Glob patterns match on extension only. A binary file read via the Read tool will produce garbled output that the LLM will attempt to classify.

**Fix:** Add to Step 4: "If the file content appears to be binary (non-UTF-8, NUL bytes, garbled output), skip it and report as 'skipped (binary content).'"

- Source: Edge case review

### L2: `docs/` not existing should be silently skipped

`docs/` is a default scan location. If it doesn't exist, Glob returns empty results silently, which is fine — but there's no instruction confirming this is expected behavior, leaving room for the LLM to treat it as an error.

**Fix:** Add: "If `docs/` does not exist, skip it silently — do not treat it as an error."

- Source: Edge case review

### L3: Same filename in different dirs causes target collision

If `docs/notes.md` and `planning/notes.md` both exist, the kebab-case filename derivation would produce the same target slug, causing a collision in the board subdirectory.

**Fix:** Add to the plan presentation step: "If two candidate files would produce the same target filename, disambiguate by incorporating path context into the kebab title (e.g., `docs-notes` vs `planning-notes`) or ask the user to rename one."

- Source: Edge case review

### L4: Cross-reference grep scope unbounded on large repos

Step 6 says "use Grep to find any references to the original filename across the codebase." On large projects this could produce hundreds of matches consuming significant context.

**Fix:** Scope the grep to doc-referencing file types (`*.md`, `*.txt`, `*.rst`). Add "limit results to 20 and summarize if more are found."

- Source: Edge case review

### L5: Crash between Write and git rm leaves duplicates

If execution crashes after writing the board file but before `git rm`, the original source file survives and may be re-discovered as a candidate on the next migration run (creating a second board entry with a new ID). The `TYPE-NNNN_*.md` exclusion filter protects the new file but not the original.

**Fix:** Covered by H4 (partial completion recovery). Additionally note in recovery guidance: "Check for orphaned originals that duplicate content of existing board items."

- Source: Git ops review

### L6: Paths with spaces need quoting in shell commands

Shell invocations of `git rm` and `git ls-files` with paths containing spaces or special characters will break if unquoted.

**Fix:** Add to the guidelines: "Always double-quote file paths in all Bash calls: `git rm \"path/to/file with spaces.md\"`."

- Source: Git ops review

### L7: Post-migration output is overloaded — consolidate

After execution (itself verbose), the skill presents: a migration summary, a "References to Update" section, lint output, and 3 follow-up prompts. This is four distinct outputs with user-actionable items after an already long interaction.

**Fix:** Consolidate. Keep the summary + references in one block. Reduce lint to a one-liner: "Board lint passed." or "N lint errors found — run `/board:board-lint` to fix." Only offer follow-up suggestions when something specific warrants them (e.g., only mention splitting if a multi-item file was flagged).

- Source: UX flow review
