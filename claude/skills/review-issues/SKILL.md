---
name: review-issues
description: >-
  Review a software project's Linear issues that are open or in Ready for Review.
  First resolve which Linear team/project corresponds to the current repo (and
  create the project if none exists yet), then verify the actual code AND the
  Linear record for correctness and completeness, post signed review comments, and
  move fully-signed-off issues to Done. Use this whenever the user asks to review
  issues, review the backlog, check Ready-for-Review items, sign off tickets, or
  "take a look" at addressed / backlog items — and also when they say an issue is
  "ready for review", ask "did you review X", or point you at recently implemented
  Linear work. Works for any repo with a Linear project, not a specific one.
---

# Review Linear issues

## What this does and why it matters

When a project tracks work in Linear, implemented work typically lands in a
**Ready for Review** state and should move to **Done** only after a real review
sign-off. This skill runs that gate end to end for the current repo: figure out
which Linear project the work belongs to, pull the reviewable issues, verify the
actual code and the Linear record against each issue's definition-of-done, write a
signed review comment, and close out only the ones that genuinely pass.

The point is an *honest* gate. Do not rubber-stamp. Implementation comments can
understate breakage — verify with your own eyes and your own command runs, not the
author's summary.

## Step 0 — Resolve the Linear team and project for this repo

Before reviewing anything, determine *which* Linear project these issues live in.
Do not assume; the right project depends on the repo you're in.

1. **Prefer an explicit pointer.** Check the repo's `CLAUDE.md` / `AGENTS.md` /
   `README` for a recorded Linear team and project — many repos name them. Use it
   if present.
2. **Otherwise infer.** Use `list_projects` (and `list_teams` if needed) and match
   against the repo: directory name, git remote URL, or README title.
3. **Disambiguate.** If several projects plausibly match, or none clearly does,
   ask the user which team/project to use rather than guessing.
4. **Create if missing.** If no suitable project exists, offer to create one with
   `save_project` under the correct team — confirm the name and team with the user
   first, since creating a project is a real, shared change.
5. **Persist the decision.** Once resolved, reuse that team/project for every
   Linear call in this run. If the repo didn't record the pointer, offer to add it
   to `CLAUDE.md` / `AGENTS.md` so future runs are unambiguous.

**State names vary by team.** "Ready for Review" and "Done" are conventions, not
guarantees. If they don't exist in this team's workflow, discover the actual
states (`list_issue_statuses`) and map to the nearest equivalents — the in-review
state and the terminal/completed state.

## Step 1 — Find the reviewable issues

Review the **in-review** state first (e.g., "Ready for Review") — those await
sign-off. Add open states ("In Progress" / "Todo") only if the user wants the
full open set.

- `list_issues(team=..., project=..., state="Ready for Review")`
- The unfiltered `list_issues` output is large and can exceed the tool's token
  limit. **Always filter** by `state` (or `updatedAt`). If a result is still saved
  to a file because it's too big, parse that file by character range instead of
  re-reading it whole.

## Step 2 — Understand each issue

For every issue under review:

- `get_issue(id)` — read the title, full description, and especially the
  **Definition of Done / acceptance criteria**. It also returns `gitBranchName`
  and `stateHistory`.
- `list_comments(issueId=...)` — read the implementation notes and the *entire*
  comment history. Comments frequently **revise scope** (a decision comment may
  retire or change part of the original DoD). Review against the current agreed
  scope, not just the original description.

## Step 3 — Locate the actual change

Tie the issue to the code that addresses it — don't infer from the comment:

- Look for commit SHAs / file paths referenced in implementation comments.
- Use `git log --oneline`, `git show <sha>`, and the issue's `gitBranchName`.
- If the fix is still uncommitted, review the working diff (`git diff`).

Read the real diff.

## Step 4 — Review for correctness AND completeness

- **Correctness** — logic, edge cases, failure modes; does it actually do what the
  issue asked? Reconstruct the failure scenario the issue describes and confirm
  the change handles it. Watch for false-positive risk (a guard that also rejects
  legitimate inputs).
- **Completeness** — walk each DoD bullet and confirm it is met, or explicitly
  superseded by a later decision comment. Flag anything *sidestepped* rather than
  solved (e.g., a test made green by disabling a feature instead of covering it).
- Be adversarial but fair. Surface residual gaps and coverage holes — they become
  follow-up issues, not silent omissions.
- Distinguish **bug reports** (issues describing a problem) from **fixes** (issues
  whose work is implemented). You sign off the latter, not the former.

## Step 5 — Verify; do not trust the comment

Re-run the checks yourself.

- **Discover the project's own commands** from the repo — its `CLAUDE.md` /
  `AGENTS.md` "verification" section, `Makefile`, `package.json` scripts,
  `pyproject.toml` / `tox.ini`, or CI config. Use those, not assumed ones.
- Run the **narrowest relevant tests first**, then broaden to the full suite if
  the change touches shared behavior. Run the project's lint/format check too.
- Don't trust the implementation comment's pass claims — re-run. (A "2 failing
  tests" claim can really be 13 once you actually run the suite.)
- **Don't run destructive, irreversible, or production-affecting commands** during
  review. Read-only checks and local smokes are fine; outward-facing actions
  (posting to webhooks, deploying, anything that reaches real people/services)
  need the user's explicit OK first.

## Step 6 — Record the verdict in Linear

**If it passes** — post a sign-off comment, then move the issue to the terminal
state (**Done**):

- The comment must explicitly state it was **reviewed and approved / signed off**
  (that is the gate that justifies the move), summarize what you verified (with the
  commands and results), and list any non-blocking residuals.
- If the approved fix is still uncommitted, commit it first so "Done" is coherent
  and durable. Commit/push per the repo's conventions.

**If it fails** — do NOT move to Done:

- Post a comment with specific, actionable findings.
- Leave it in the in-review state. If it was already Done, reopen it and move it
  back to the backlog.

## Step 7 — Handle residuals

File **new** issues for follow-ups (coverage gaps, hardening, deferred scope)
rather than muddying the reviewed issue or reopening a legitimately-done one. Apply
clarifying labels and link related issues with `relatedTo`.

## Sign-off comment template

```
Review sign-off.

**Reviewed and approved** — <commit SHA(s)>.

<What you verified against the DoD: the behavior changed, the checks made,
the failure scenario it now handles.>

Verification:
- <test command> → <result>
- <lint/format command> → <result>

<Residual / follow-up (non-blocking), if any, and where it's tracked.>

Moving to Done.

--claude
```

**Sign every comment you author with `--claude`** on its own final line — this
applies to all comments this skill posts (sign-offs, findings, residual notes), so
the authorship is always explicit. For a fail verdict, replace the header and body
with the specific findings and end with the disposition (kept in review / reopened
→ backlog) instead of "Moving to Done." (still signed `--claude`).

## Safety boundaries

- Respect the project's documented constraints and conventions (its `CLAUDE.md` /
  `AGENTS.md`). Don't use a review comment to approve risky or irreversible actions
  the project gates, or to weaken its safety/security controls.
- Never post secrets, tokens, credentials, or sensitive data into Linear.
- The terminal state requires *your* explicit sign-off comment. Moving an issue to
  Done without one breaks the review gate.

## Gotchas

- `list_issues` unfiltered is large — always filter by `state`.
- A fix that lands as an uncommitted working-tree change still needs committing;
  reviewing it green but leaving it uncommitted makes a "Done" issue fragile.
- `save_issue`'s `labels` field replaces the label set — include existing labels
  when adding one, or you'll wipe them.
- Workflow state names differ per team — resolve them with `list_issue_statuses`
  rather than assuming "Ready for Review" / "Done" exist.
