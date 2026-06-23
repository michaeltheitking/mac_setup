---
name: file-issues
description: >-
  File well-structured new issues in Linear for any repo. First resolve which
  Linear team/project the work belongs to (and create the project if none exists
  yet), check for duplicates, then create the issue using the standard template
  (Goal / Context / Non-goals / Acceptance Criteria / Design Required) with a
  clear title, priority, labels, and links. Use this whenever the user wants to
  file or open a Linear issue/ticket/bug/task, log a follow-up or TODO as a
  ticket, turn a finding, idea, or review residual into a tracked issue, or "add
  this to the backlog". Works for any repo, not a specific one.
---

# File new Linear issues

## What this does and why it matters

Turn a request, finding, or follow-up into a Linear issue that's actually
actionable later — clear outcome, enough context to start cold, explicit scope
boundaries, and checkable acceptance criteria. A good issue is one someone (human
or agent) can pick up weeks later without re-deriving the intent. Avoid vague
one-liners and avoid duplicates.

## Step 0 — Resolve the Linear team and project for this repo

Determine *which* Linear project the issue belongs in before creating anything.

1. **Prefer an explicit pointer.** Check the repo's `CLAUDE.md` / `AGENTS.md` /
   `README` for a recorded Linear team and project. Use it if present.
2. **Otherwise infer.** Use `list_projects` (and `list_teams` if needed) and match
   against the repo: directory name, git remote URL, or README title.
3. **Disambiguate.** If several match or none clearly does, ask the user.
4. **Create if missing.** If no suitable project exists, offer to create one with
   `save_project` under the correct team — confirm the name and team first, since
   it's a real, shared change.
5. **Persist the decision.** Reuse that team/project for everything in this run; if
   the repo didn't record the pointer, offer to add it to `CLAUDE.md` / `AGENTS.md`.

## Step 1 — Gather and fill the content (don't leave placeholders)

Capture the issue from the user's request plus the repo context. Investigate
enough to fill each section meaningfully — read the relevant files, check git
history, follow links. Ask the user only for genuinely missing *decisions* (scope
calls, priority, target outcome), not for things you can determine yourself.

Use this exact body template, and replace every prompt with real content:

```
## Goal
What user/business outcome this solves.

## Context
Relevant links, files, constraints, prior decisions.

## Non-goals
What should not be changed.

## Acceptance Criteria
- [ ] Behavior A
- [ ] Behavior B
- [ ] Tests updated
- [ ] No unrelated refactors

## Design Required?
Yes / No and whatever other details you think may be important
```

Section guidance:
- **Goal** — the outcome, not the implementation. One or two sentences.
- **Context** — concrete `file:line` references, commit SHAs, linked issues, the
  constraint or prior decision that motivates this. Enough to start cold.
- **Non-goals** — the scope fence. What this deliberately does *not* touch. This is
  what keeps the work from sprawling; don't skip it.
- **Acceptance Criteria** — objectively checkable boxes. Tailor them to the work;
  the example lines (tests updated / no unrelated refactors) are sensible defaults,
  not mandatory. For a bug, include the repro that must pass.
- **Design Required?** — "Yes" if it needs an approach decision, schema, API
  contract, or UX before coding; "No" if it's mechanical. Add a one-line why.

## Step 2 — Check for duplicates first

Before creating, search the project for an existing issue covering this
(`list_issues` with a `query`, or `search`). If a near-duplicate exists, surface it
and ask whether to comment on / reopen the existing one instead of filing a new
one. Filing a duplicate is worse than not filing.

## Step 3 — Set the metadata

- **Title** — concise and scannable. Action/outcome-oriented for features
  ("Add X so Y"); symptom-oriented for bugs ("X fails when Y"). No trailing period.
- **Priority** — `1` Urgent (broken in production / safety now), `2` High
  (important, blocking soon), `3` Medium (normal), `4` Low (nice-to-have /
  deferred), `0` None if genuinely unsure.
- **Labels** — reuse the project's existing labels (`list_issue_labels`); match
  type (Bug/Feature/Improvement) and any status labels the project uses. Only
  create a new label (`create_issue_label`) when a clearly-needed one is missing —
  confirm with the user first. Note: `save_issue`'s `labels` field *replaces* the
  set, so pass the full intended list.
- **Links** — connect the issue: `relatedTo`, `blockedBy` / `blocks`, or
  `parentId` for sub-issues. Reference the source (a review finding, a commit, an
  ADR) in Context.
- **State** — leave it in the team's initial/backlog state. Don't start or assign
  it unless the user asks.

## Step 4 — Create and report

- Create with `save_issue(team=..., project=..., title=..., description=...,
  priority=..., labels=[...], ...)`.
- **End every issue description (and any comment) you author with `--claude`** on
  its own final line, so the authorship is always explicit.
- Report back the created issue identifier and URL. If you filed several, list them.

## Filing several at once

When capturing a batch (e.g., review residuals or a list of TODOs), file each as
its own focused issue rather than one mega-issue — one outcome per issue keeps
acceptance criteria checkable and lets them be prioritized independently. Link
related ones together.

## Safety boundaries

- Never put secrets, tokens, credentials, or sensitive data into an issue.
- Respect the project's documented conventions (its `CLAUDE.md` / `AGENTS.md`).
- Creating a Linear project or a new label is a shared, outward change — confirm
  before doing it.
