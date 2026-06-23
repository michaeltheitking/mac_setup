---
name: implement-issues
description: End-to-end Linear issue implementation workflow. Use when Codex is asked to look at, triage, fix, implement, or take open/new Linear issues for the current project/repository, including requests like "new issue, take a look", "implement the Linear issues", "fix open project issues", or "work through the backlog". Reads the relevant Linear project, implements issue requirements in the local codebase, verifies tests/lint/typecheck/format, updates Linear with a signed summary, and moves finished work to Ready for Review.
---

# Implement Issues

## Core Workflow

1. Establish scope from local context before editing:
   - Read repo guidance such as `AGENTS.md`, `CLAUDE.md`, or equivalent.
   - Check `git status --short` and treat existing changes as user-owned unless they are clearly part of the current work.
   - Identify the relevant Linear team/project from repo guidance, issue references, branch names, or user context. If ambiguous, inspect available Linear projects/teams and choose the project matching the repository.

2. Read Linear before deciding:
   - Use Linear tools to list recent/open issues for the relevant project.
   - For each candidate issue, read the full issue body, labels, priority, comments, relations, and current status.
   - Prefer newest or highest-priority actionable issues when the user says "new issue" or gives no issue ID.
   - Do not reopen or change closed issues unless the issue has new required fixes or the user explicitly asks.
   - Move the issue to `In Progress` before implementation when it is not already started.

3. Implement the issue, not a drive-by refactor:
   - Translate acceptance criteria and stated goals into code/docs/tests.
   - Read the relevant modules before choosing an approach.
   - Keep edits focused and consistent with local architecture.
   - Add or update ADRs/design docs only when the issue asks for a decision or changes architecture/design policy.
   - Do not weaken safety, auth, validation, settlement, account-boundary, or execution-integrity gates to satisfy a feature.

4. Add and update tests:
   - Add targeted tests for every meaningful acceptance criterion, bug reproduction, boundary condition, and regression path.
   - Update stale tests only when behavior intentionally changed or configuration changed.
   - Keep tests hermetic: use fakes/fixtures for network, broker, LLM, calendar, filesystem, and credentials unless the issue explicitly requires a live smoke.

5. Verify with the project’s own tooling:
   - First run the narrowest relevant tests.
   - Then run the full relevant suite before marking done.
   - Detect and run applicable commands, such as:
     - Python: `pytest`, `ruff format`, `ruff check`, `mypy` or `pyright` when configured.
     - Node: `npm test`, `npm run lint`, `npm run typecheck`, `npm run format` or `npm run format:check` when configured.
     - .NET: `dotnet test`, `dotnet format --verify-no-changes` when configured.
     - Go/Rust/Java/etc.: use repo-declared test, lint, typecheck, and format commands.
   - If a tool is unavailable, install only through the project’s declared environment/dependency path or report exactly what could not be verified.

6. Update Linear when implementation is genuinely ready:
   - Add a concise implementation comment to the issue.
   - Start the comment with `Codex update:`.
   - Include changed behavior, key files/components, and exact verification commands/results.
   - Do not include secrets, tokens, raw private payloads, unrelated sensitive data, or live-trading approvals.
   - End the comment with `--codex`.
   - Move the issue to `Ready for Review`, not `Done`/`Completed`, unless an explicit review sign-off comment already authorizes completion.

## Selection Rules

- If the user names an issue ID, implement that issue.
- If the user says "new issue", pick the newest open issue in the relevant project unless another open issue is clearly more urgent and blocking.
- If multiple open issues are requested, implement them one at a time unless they are tightly coupled. Avoid bundling unrelated changes into one diff.
- If an issue is too broad for one pass, implement a coherent initial slice that satisfies explicit acceptance criteria where possible, then leave a signed Linear comment describing what remains.
- If an issue cannot be implemented because requirements conflict, data/tool access is missing, or the local repo cannot support it, leave a signed Linear comment with the blocker and do not move it to Ready for Review.

## Git And Delivery

- Do not stage, commit, push, or create a PR unless the user asks or repo guidance requires it for the workflow.
- Before final response, report current git status, verification results, Linear status change, and any remaining risks.
- Keep unrelated existing worktree changes unstaged and mention them separately when relevant.
