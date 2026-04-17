---
type: note
status: inbox
created: 2026-04-06
---

# NOTE-0007: Board automation via CI, git hooks, and Claude hooks

Ideas for automating board operations beyond manual invocation. Three layers, each with different guarantees, costs, and failure modes.

---

## 1. GitHub Actions (CI)

### What to automate

- **board-lint** — the clearest fit. Run `board-lint.sh` on every PR that touches `board/**` files. Fail the check if lint errors are found, preventing malformed board items from merging.
- **board-scan summary** — post a PR comment with a snapshot of board state (active item count, any items affected by the PR). Informational, not blocking.

### Potential approach

```yaml
# .github/workflows/board-lint.yml
on:
  pull_request:
    paths: ['board/**']
jobs:
  board-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash plugin/scripts/board-lint.sh ./board
```

### Tradeoffs

- **Pro**: enforces quality at the merge gate — no invalid board files reach `main`
- **Pro**: runs in a clean environment, no local setup required
- **Pro**: visible to all contributors, not just the person who set up their local hooks
- **Con**: only catches issues at PR time, not at authoring time — longer feedback loop
- **Con**: requires the repo to use GitHub (or adapt for other CI systems)
- **Risk**: lint rules that are too strict could block unrelated PRs if `board/` files happen to have pre-existing issues. Would need a clean baseline first.

### Open questions

- Should board-update or board-archive also run in CI? Probably not — these modify files, which means the CI job would need to push commits back to the branch (messy, permission-heavy).
- Should lint run on _all_ PRs or only those touching `board/`? Path filtering keeps it fast but misses cases where code changes should have had a corresponding board update.

---

## 2. Pre-commit git hooks

### What to automate

- **board-lint** — validate board files before they're committed. Fast, local, immediate feedback.
- **board-archive** — auto-archive `done` items on commit. Tempting but risky (see below).
- **board-update** — reconcile board with code state. Too slow/complex for a pre-commit hook.

### Potential approach

Use a framework like [pre-commit](https://pre-commit.com/) or a simple `.git/hooks/pre-commit` script:

```bash
#!/usr/bin/env bash
# Only lint if board files are staged
if git diff --cached --name-only | grep -q '^board/'; then
  bash plugin/scripts/board-lint.sh ./board
fi
```

### Tradeoffs

- **Pro**: catches issues before they enter history — fastest feedback loop
- **Pro**: works offline, no CI dependency
- **Con**: git hooks are not version-controlled by default — each contributor must install them (or use a framework like `pre-commit`, `husky`, or `lefthook`)
- **Con**: developers can skip with `--no-verify` when frustrated
- **Risk (board-archive in pre-commit)**: auto-archiving items on commit is dangerous. If a task is marked `done` but the commit is later reverted or the branch is abandoned, the archived item is orphaned. Archive should remain intentional.
- **Risk (board-update in pre-commit)**: `board-update` requires reading git history and possibly making judgment calls about task status. It's inherently interactive/LLM-driven and not suitable for a synchronous git hook.

### Recommendation

Only **board-lint** belongs in pre-commit. Archive and update are better suited to explicit skill invocation or Claude hooks.

---

## 3. Claude Code hooks

### Current state

The plugin already has a `SessionStart` hook that runs `board-lint.sh` (see `plugin/hooks/hooks.json`). This gives a health check at the start of every session.

### What else could be automated

| Hook event | Operation | Rationale |
|------------|-----------|-----------|
| `SessionStart` | board-lint | Already implemented. Surfaces issues immediately. |
| `Stop` | board-lint | Re-validate after a session that touched board files. Catch anything introduced during the session. |
| `Stop` | board-update (prompt-based) | After a work session, prompt the user: "Board items may need updating based on this session. Run /board:update?" This is a nudge, not an automatic action. |
| `PostToolUse` (on `Write`/`Edit` to `board/**`) | board-lint (targeted) | Lint only the file just written/edited. Immediate feedback without waiting for session end. |

### Tradeoffs

- **Pro**: deeply integrated into the AI-assisted workflow — no separate tooling to install
- **Pro**: can be prompt-based (nudges) rather than hard gates, which fits the collaborative nature of BoardPM
- **Pro**: `Stop` hooks can summarize board drift without blocking the user
- **Con**: only works when using Claude Code — no protection for manual edits outside a session
- **Con**: hook timeouts can slow down the workflow if scripts are slow
- **Risk (auto-archive on Stop)**: same risk as pre-commit — auto-archiving without explicit intent can lose track of items. A prompt/nudge is safer than silent action.
- **Risk (PostToolUse lint)**: running lint on every single board file write could be noisy if the user is making multiple edits in sequence. Debouncing isn't available in hooks.

### Recommendation

- Keep `SessionStart` lint as-is
- Add a `Stop` hook that runs lint and, if board files were touched, suggests running `/board:update`
- `PostToolUse` lint is nice in theory but may be too chatty — defer unless users report wanting it

---

## Layered strategy

The three approaches are complementary, not competing:

| Layer | Catches | Feedback speed | Requires setup | Skippable? |
|-------|---------|----------------|----------------|------------|
| Claude hooks | Issues during AI sessions | Immediate | Plugin install | Only by uninstalling |
| Pre-commit hook | Issues at commit time | Fast (local) | Hook install | `--no-verify` |
| GitHub Actions | Issues at merge time | Slow (CI) | Repo config | Needs admin override |

Recommended rollout order:
1. **Claude hooks** — already partially in place, extend with `Stop` hook
2. **GitHub Actions** — add `board-lint` CI check for merge-gate protection
3. **Pre-commit hook** — optional local enhancement, document in setup guide

---

## Risks common to all approaches

- **False positives blocking real work**: if lint rules are too aggressive, any automation layer becomes an obstacle. Keep lint focused on structural validity (frontmatter shape, ID uniqueness, valid statuses), not style opinions.
- **Stale automation**: if board-lint.sh changes, all three layers need to work with the new version. CI pins to the repo so it's fine; git hooks and Claude hooks reference the plugin root, so they track updates naturally.
- **Board-update is not automatable**: it requires LLM judgment (reading code changes, inferring task status). It should always be skill-invoked, never a silent hook. At most, suggest running it.
