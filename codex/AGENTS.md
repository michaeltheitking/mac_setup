# Global Assistant Instructions

These instructions apply across all projects and coding tools (Claude Code, Codex, etc.). Project-specific instruction files (`CLAUDE.md`, `AGENTS.md`) may add or override guidance for a particular repository.

## Working Style

- Be direct, pragmatic, and concise.
- When the request is implementation-oriented, make the change instead of stopping at advice.
- Read the relevant code before deciding on an approach.
- Prefer small, focused edits that match the existing project structure.
- Explain important tradeoffs and assumptions when they affect the result.

## Code Changes

- Preserve existing conventions, names, formatting, and architecture unless there is a clear reason to change them.
- Avoid unrelated refactors.
- Do not add dependencies unless they clearly reduce complexity or match the existing stack.
- Prefer existing helpers, libraries, components, and patterns already present in the repository.
- Add comments only where they clarify non-obvious logic.
- Keep generated or mechanical changes out of source files unless they are required.

## Searching and Editing

- Use `rg` or `rg --files` for searching when available.
- Use structured tools or parsers for structured data instead of ad hoc string manipulation when practical.
- Use the harness's dedicated edit/patch tools for source changes, not shell `echo`/heredoc rewrites.
- Do not use destructive commands such as `git reset --hard`, `git checkout --`, or broad deletes unless explicitly requested.

## Lint and Format

- Globally installed (Homebrew): `ruff` for Python and `prettier` for JS/TS/JSON/CSS/Markdown/YAML.
- Prefer a project's own configured lint/format tools when they exist; fall back to the global tools when the project configures none.
- For Python fallback: run `ruff check` (lint, includes flake8-simplify rules) and `ruff format` on the files you changed before committing.
- For web/docs fallback: run `prettier --write` on the files you changed before committing.
- When falling back to global tools, lint/format only the files touched by the current task — do not reformat the whole repository or commit tool config into the project unless asked.

## Git Safety

- Treat the worktree as shared with the user.
- Never revert or overwrite changes that were not made for the current task unless explicitly requested.
- If unexpected changes affect the task, inspect them and work with them.
- Before committing, check `git status` and include only relevant changes.
- Commit/push durable, reviewed repo changes; avoid commits or pushes for exploratory, partial, or user-local work unless explicitly requested.
- Before committing or pushing, ensure code is: reviewed, linted, formatted with project (or global fallback) tools, simplified where practical, commented where helpful, and validated with the relevant tests.

## Testing and Verification

- Run the narrowest relevant tests first.
- Broaden testing when changes touch shared behavior, public APIs, user-facing flows, or cross-module contracts.
- If tests cannot be run, state exactly what was not verified and why.
- For frontend changes, verify the app visually when practical.

## Frontend Preferences

- Build the actual usable experience, not a marketing page, unless the request specifically calls for one.
- Match the project's design system and component patterns.
- Favor dense, scannable, task-focused interfaces for internal tools and dashboards.
- Keep text readable and ensure controls do not overlap or resize unpredictably.
- Use familiar controls and icons where appropriate.

## Decision Logging

- Log only ADR, architecture, or design decisions in `docs/decisions/`.
- ADR-worthy decisions include provider, vendor, or API choices; architecture or module boundaries; data model or schema choices; auth or security approach; testing or CI policy; and deployment or runtime assumptions.
- For each ADR-worthy decision, create a new ADR if none exists or update the existing ADR if the decision changes.
- ADRs should include status, context, decision, rationale, consequences, and revisit triggers.
- Do not create ADRs for tiny bug fixes, formatting changes, routine implementation details, or other non-architecture/non-design decisions.

## Communication

- Keep progress updates short and concrete.
- Final responses should summarize what changed, what was verified, and any remaining risks.
- Use clickable file references when pointing to local files.
- Avoid unnecessary praise, filler, or restating the obvious.

## Project Tracking & Documentation

When a project uses Linear:

- Log code review findings in Linear at the appropriate project or issue level.
- Move implemented tasks to `Ready for Review` first; move to `Completed` only after a Linear comment explicitly notes the work was reviewed and signed off.
- If a closed issue gets new required fixes or follow-up comments, reopen it and move it back to the backlog.

When a project uses Confluence for documentation (the default unless the user names another destination):

- Focus on high-level design, a plain-English overview, and how to operate the tool; avoid low-level implementation detail unless needed for operation or support.
- Set an appropriate emoji page icon, and don't repeat the page title as the first heading or line — Confluence renders it separately.

## Codex Pipeline (Linear team "personal pets")

- A launchd pipeline on the Mac mini (repo `~/Documents/projects/code_flow`; its README/AGENTS.md are authoritative) automates Linear issues: a **Todo** issue labeled **`codex`** → headless Codex implements on a local branch → Ready for Review → headless Claude reviews → approve merges directly to `main` and pushes. **No PRs anywhere in this workflow.**
- Only Linear projects enrolled in `REPO_MAP` (`~/.config/codex-pipeline/env`) are dispatched; enrollment is manual and deliberate.
- To hand an issue to the pipeline: make sure it has a full spec (Goal / Context / Non-goals / Acceptance Criteria). If an issue is underspecified, write the spec into the description, park it `needs-human` for Michael's review, and only after his sign-off apply `codex`, remove `needs-human`, and set state to Todo.
- `needs-human` means Michael's input is genuinely required — it is applied only after a Claude triage pass has vetted the blocker. To resume a `needs-human` issue after Michael answers: remove `needs-human`, re-apply `codex`, state Todo.
- Sign every Linear comment you write with an agent trailer on its own final line: `--claude` (or `--codex` for Codex). Pipeline machinery signs `--codex-pipeline`. Comments post under Michael's API identity, so the trailer is the only attribution.

## Boundaries

- Do not store secrets, tokens, credentials, or private keys in files.
- Ask before taking actions that are destructive, expensive, or require external services when the user has not clearly requested them.
- Prefer local context over web search unless current information, external docs, or user instructions require browsing.
