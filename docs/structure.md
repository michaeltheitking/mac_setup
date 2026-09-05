# Directory and file organization

## Common documentation contract

Keep `AGENTS.md`, `CLAUDE.md`, and `README.md` as root entry points.
Use `docs/README.md`, `docs/current-state.md`, `docs/structure.md`, and `docs/operations.md` for maintained guidance.
Use `docs/decisions/` for architecture decisions and `docs/handoffs/` for unfinished-work continuation.
Create `docs/plans/`, `docs/reference/`, and `docs/history/` only when needed.
Existing guides can retain their names; link them from the index instead of creating competing copies.

Keep established code layouts and tool-required root files in place.
Do not move runtime source, supplied artifacts, or deployment payloads solely to match a generic layout.
Use lowercase, hyphen-separated names for new documents, dates for snapshots, and stable names for current guidance.
Before a move, inspect callers, imports, packaging, links, tests, and runtime paths; update and verify them together.

### Shared and local material

Track reviewed source and non-sensitive documentation under the existing repository policy.
Keep credentials, caches, live databases, private exports, and raw tool history local.
Document data requirements without embedding private values. Do not synchronize whole agent configuration directories.

### Existing directory roles

- `claude/`: Shared Claude configuration and skills.
- `codex/`: Shared agent instructions and Codex skills.
- `tests/`: Automated checks and fixtures.
- `ssh/`: Managed SSH configuration and pinned host keys.
- `scripts/`: Command entry points and maintenance helpers.
- `ghostty/`: Managed terminal configuration.
