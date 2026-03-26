---
type: note
status: inbox
created: 2026-03-11
---

# NOTE-0002: External tool integrations

Add integration layers, translation scripts, or adapters to work with external project management tools and agile platforms. Potential targets include:

- **GitHub Projects** — sync board items to/from GitHub project boards
- **JIRA** — import/export tasks and epics in JIRA-compatible formats
- **Linear, Trello, Asana** — other popular agile/PM tools
- **Generic formats** — CSV/JSON export for interoperability

---

## GitHub Projects Integration — Brainstorm

### Core question

BoardPM is plain Markdown with YAML frontmatter. GitHub Projects (v2) is a GraphQL-backed database with custom fields, views, and automations. The integration needs to bridge these two models without making either one "primary" — users should be able to work in whichever surface they prefer.

### Rough exploration steps

1. **Map the data model** — Figure out which BoardPM concepts translate cleanly to GitHub Projects and which don't:
   - TASK → Issue (natural fit, but issues live in a repo, not just a project)
   - EPIC → Issue with sub-issues, or a Project view/grouping?
   - ADR → Issue? Discussion? Doesn't map well — may be export-only
   - NOTE/RESO — no natural GitHub equivalent; may stay board-only
   - Frontmatter fields (status, priority, blocked_by, parent) → custom Project fields

2. **Decide on sync direction** — Three options with very different complexity:
   - **Export-only** (board → GitHub): simplest, one-way push, no conflict resolution
   - **Import-only** (GitHub → board): pull issues into board format for AI-assisted work
   - **Bidirectional sync**: most useful but introduces conflict resolution, staleness detection, and "source of truth" questions

3. **Prototype the GitHub API surface** — GitHub Projects v2 uses the GraphQL API exclusively:
   - `gh project` CLI commands exist but are limited
   - Full control requires GraphQL mutations (addProjectV2Item, updateFieldValue, etc.)
   - Authentication: `gh auth token` or PAT with `project` scope
   - Rate limits and pagination for large boards

4. **Design the field mapping config** — Users will need to define how their board maps to their project:
   - Which GitHub Project to target (org/user, project number)
   - Custom field mappings (e.g., board `priority` → GitHub "Priority" single-select)
   - Status field mapping (board statuses → GitHub column/status values)
   - Could live in a `.board-sync.yml` or similar config file

5. **Build a minimal export script** — Start with the simplest useful thing:
   - Read `board-scan.sh --active` TSV output
   - For each TASK: create or update a GitHub Issue + add to Project
   - Map frontmatter fields to Project custom fields
   - Store the GitHub issue URL back in the board file (new frontmatter field like `github_issue:`)
   - Idempotent: re-running updates existing issues rather than creating duplicates

6. **Handle the identity problem** — How to link a board item to its GitHub counterpart:
   - Option A: store GitHub issue number/URL in frontmatter (`github_issue: 42`)
   - Option B: store board ID in the GitHub issue body or a custom field
   - Option C: both (belt and suspenders for bidirectional sync)

7. **Consider what NOT to sync** — Some things are better left platform-specific:
   - ADRs are immutable and don't fit the issue lifecycle
   - NOTEs are ephemeral scratch — syncing them adds noise
   - `blocked_by` relationships → GitHub sub-issues or "tracked by" links? Lossy either way

### Open questions

- Should this be a plugin script (`plugin/scripts/board-gh-sync.sh`) or a standalone CLI tool?
- Does it need to run automatically (hook on commit? scheduled?) or is manual invocation enough?
- How to handle board items that were archived — close the GitHub issue?
- Should the sync create GitHub Issues, or just Project items (draft items have no issue backing)?
- What about teams that use GitHub Projects as primary and want to *generate* board files from it?
