# Global Codex Instructions

These instructions apply across all projects. Project-specific `AGENTS.md` files may add or override guidance for a particular repository.

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
- Use `apply_patch` for manual source edits.
- Do not use destructive commands such as `git reset --hard`, `git checkout --`, or broad deletes unless explicitly requested.

## Git Safety

- Treat the worktree as shared with the user.
- Never revert or overwrite changes that were not made for the current task unless explicitly requested.
- If unexpected changes affect the task, inspect them and work with them.
- Before committing, check `git status` and include only relevant changes.

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

- When making or changing a consequential project decision, update `docs/decisions/`.
- Consequential decisions include provider, vendor, or API choices; architecture or module boundaries; data model or schema choices; auth or security approach; testing or CI policy; deployment or runtime assumptions; and anything that would be annoying to reverse later.
- For each decision, create a new ADR if none exists or update the existing ADR if the decision changes.
- ADRs should include status, context, decision, rationale, consequences, and revisit triggers.
- Do not create ADRs for tiny bug fixes, formatting changes, or obvious implementation details.

## Communication

- Keep progress updates short and concrete.
- Final responses should summarize what changed, what was verified, and any remaining risks.
- Use clickable file references when pointing to local files.
- Avoid unnecessary praise, filler, or restating the obvious.
- Log code review findings in Linear at the appropriate project or issue level.
- If a closed Linear issue receives additional required fixes, review findings, or follow-up comments, reopen it and move it back to the backlog.
- Write project documentation to Confluence unless the user explicitly asks for another destination.
- When writing documentation in Confluence, set an appropriate emoji icon for the page and do not repeat the page title as the first heading or first line of the body; Confluence already renders the page title separately.

## Boundaries

- Do not store secrets, tokens, credentials, or private keys in files.
- Ask before taking actions that are destructive, expensive, or require external services when the user has not clearly requested them.
- Prefer local context over web search unless current information, external docs, or user instructions require browsing.
