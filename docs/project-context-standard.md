# Shared project context standard

Use one documentation contract across macOS and Omarchy, with project-specific privacy and runtime boundaries.
The global rules in [codex/AGENTS.md](../codex/AGENTS.md) define the required files and recording workflow.

## Core structure

- Root AGENTS.md: operating rules and required context reads.
- Root CLAUDE.md: imports or links to AGENTS.md.
- Root README.md: purpose, setup, and documentation entry point.
- docs/README.md: reading order and document index.
- docs/current-state.md: dated verified facts, sources, uncertainty, and known gaps.
- docs/structure.md: directory roles, naming, and tracking boundaries.
- docs/operations.md: commands, runtime ownership, platform prerequisites, and recovery.
- docs/decisions/README.md: decision index and required fields.
- docs/handoffs/README.md: unfinished-work recording requirements.

Create plans, reference, and history directories only when needed.
For new projects, use src/ for implementation, tests/ for checks, scripts/ for entry points, and config/ for templates.
Use assets/, inputs/, and outputs/ when needed; define their tracking boundaries before adding files.
Keep only entry documents and required framework/tool files at the root. Document stack-specific exceptions in docs/structure.md.
Keep existing application layouts and useful detailed documents; index them instead of creating duplicate sources of truth.

## Recording and delivery

Record verified facts with dates and sources. Keep old observations explicitly historical.
Update operating guidance with implementation changes and record durable decisions when the choice is made.
Use the existing issue or a dated handoff to transfer unfinished work, with branch, commit, checks, and next action.
Commit and push reviewed, non-sensitive context with code under the project workflow.
Do not synchronize complete agent home directories, credentials, or live state.

## Exceptions

Financial and website internal context stays local under their existing privacy and publication boundaries.
Their tracked READMEs provide safe clone-start instructions and explain the missing local context.
Do not widen privacy hooks or publish internal documents to meet a directory convention.
Artifact folders retain their producer boundary; they do not become separate source repositories.

## New-project acceptance

Create core documents with actual known facts and explicit unknowns.
Confirm instruction loading in both agents, relative links, Git tracking, and the documented privacy exceptions.
Verify platform-specific commands on the target platform before claiming support.
Keep runtime installation and authentication separate from documentation setup.
