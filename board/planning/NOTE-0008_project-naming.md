---
type: note
status: inbox
created: 2026-04-06
---

# NOTE-0008: Project naming — renaming from BoardPM

Currently named "BoardPM." Considering a rename that adds personality and/or communicates the plaintext differentiator. The `/board/` directory and casual "board" shorthand would stay regardless of system name.

## Candidates

| Name | Clarity | Personality | Notes |
|------|---------|-------------|-------|
| BoardPM | High | None | Current name. Descriptive but forgettable. |
| BigBoard | Low | High | Snow Crash reference (Hiro's program). Fun but doesn't signal what it is. Also associated with stock exchange/election displays. |
| PlainBoard | High | Low | Immediately communicates "plain text." Clear but generic. |
| BoardMark | Medium | Medium | Board + Markdown. Clever but could be mistaken for "bookmark." |
| FlatBoard | Medium | Medium | "Flat files," no database. Punchy. |
| BoringBoard | High | High | "Boring technology" ethos — reliability through simplicity. Anti-hype positioning. Memorable, self-deprecating, builds trust. Small risk of being taken at face value. |
| BoredBoard | Medium | High | Witty variant. "Whatever, it works." More apathetic than principled — better as a mascot/tagline than a name. |
| Planar | High | Medium | "Flat, on a single plane." Elegant, professional. But too close to [Plane.so](https://plane.so) / [makeplane/plane](https://github.com/makeplane/plane) — established open-source PM tool. Would compete for search results. **Likely eliminated.** |

## Key tensions

- **Descriptive vs. personality**: dev tools benefit from clarity on what they are, but memorable names drive adoption
- **BoringBoard** currently wins on both axes — it communicates "simple on purpose" while being distinctive and fun
- **BigBoard** has the best literary reference but doesn't help someone understand what the tool is

## Prior art: Plane.so "Projects as Code"

[Plane.so blog post](https://plane.so/blog/introducing-projects-as-code-a-declarative-approach-to-project-configuration-and-governance) — Plane (open-source PM tool) introduced a "Projects as Code" feature using YAML in git to declare project configuration (workflows, permissions, automation rules). Relevant to naming because:

- Validates the "project management belongs in the repo" thesis — a funded PM company is moving toward YAML-in-git
- **But they solve a different problem**: Plane stores project *configuration* as code; the work items still live in Plane's database. BoardPM stores the *work items themselves* as files — the filesystem is the entire PM system, no external runtime
- This distinction ("configure your PM tool with code" vs. "your PM tool *is* code") is the core differentiator a good name should communicate
- Reinforces that names emphasizing **plaintext/files/simplicity** (BoringBoard, PlainBoard) are more differentiating than generic "board" names that could describe any PM tool
- Also confirms Planar/Plane naming collision is a real problem — they're close enough in space that name confusion would be constant

## Decision criteria (when ready)

- Does the name work in a README headline?
- Does it work in conversation? ("We use BoringBoard for project tracking")
- Does it survive a search engine? (Unique enough to find)
- Does the audience get it immediately?
