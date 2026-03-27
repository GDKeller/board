---
type: epic
status: done
priority: 1
created: 2026-03-26
---

# EPIC-0002: Harden board-migrate skill from review feedback

Apply findings from the four-agent review (NOTE-0004) to make the `board-migrate` skill robust, spec-compliant, and usable. Findings span git safety, spec compliance, edge case handling, and UX flow.

## Source

- [[NOTE-0004]] — Board-migrate skill review feedback

## Tasks

### Git safety & file operations
- [[TASK-0015]] — Add pre-flight checks to board-migrate (dirty tree, path validation, board dirs)
- [[TASK-0016]] — Fix file removal logic for tracked vs untracked files
- [[TASK-0017]] — Add sequential ID assignment enforcement and mid-run failure recovery

### Spec compliance
- [[TASK-0018]] — Add explicit frontmatter templates to board-migrate execution step
- [[TASK-0019]] — Enforce ADR structure and context_date inference for migrated ADRs
- [[TASK-0020]] — Make resource URL required and surface during plan review

### Edge case handling
- [[TASK-0021]] — Add guards for empty, binary, symlink, frontmatter-only, and large files

### UX & interaction flow
- [[TASK-0022]] — Streamline interactive flow and reduce blocking prompts
- [[TASK-0023]] — Improve plan presentation format and approval interaction
- [[TASK-0024]] — Consolidate post-migration output and add recovery guidance
