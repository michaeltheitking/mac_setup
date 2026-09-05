# Local instruction loading audit

Date: 2026-09-05

## Result

All 18 unique local project roots fit the default 32,768-byte Codex instruction budget after this audit.
Health Dashboard's startup instructions decreased from 56,669 to 6,207 bytes.
Its original text remains unchanged inside `docs/reference/health-context.md`, with a reference notice added above it.
Five projects now expose their project rules to Claude through a relative `@AGENTS.md` import.

This is a filesystem and configuration audit. It does not prove that existing sessions refreshed their context.

## Scope and method

The audit covers saved local projects, immediate project directories under `~/Documents/projects` and `~/srv`, `~/dotfiles`, and `~/Documents/Codex`.
The `intune_config` directory resolves to `dixondale`; it is one project, not a second checkout.
The four saved ChatGPT cloud projects are outside this local filesystem audit.

- Checked global entry files, symlink targets, project entry files, ancestor files, nested instruction files, and project configuration files.
- Excluded dependency, build, cache, and Git metadata directories from nested-file discovery.
- The global Codex and Claude files resolve to `~/dotfiles/codex/AGENTS.md`.
- No global `AGENTS.override.md`, explicit size override, fallback filename override, or selected profile was found in the local Codex config.
- No project `.codex/config.toml` or project `AGENTS.override.md` was found in the audited roots.
- Existing project `CLAUDE.md` symlinks all use the relative target `AGENTS.md`; they remain portable across worktrees.
- No additional ancestor project instruction file was found. Global Claude guidance still loads separately.

The table counts UTF-8 source bytes, excluding separators and tool-generated wrappers.
Combined bytes include the 11,376-byte global file and the root project file once.
Claude imports and symlinks provide equivalent project content but do not use Codex's size setting.

## Project inventory after repairs

| Local directory                               | Project bytes | Global + project bytes | Claude project entry      |
| --------------------------------------------- | ------------: | ---------------------: | ------------------------- |
| `~/dotfiles`                                  |         7,514 |                 18,890 | Added relative import     |
| `~/Documents/Codex`                           |             0 |                 11,376 | Global only               |
| `~/Documents/projects/bootstrap_windows`      |         2,228 |                 13,604 | Added relative import     |
| `~/Documents/projects/code_flow`              |         8,654 |                 20,030 | Existing relative symlink |
| `~/Documents/projects/dixondale`              |         8,636 |                 20,012 | Existing relative symlink |
| `~/Documents/projects/emailbriefing`          |             0 |                 11,376 | Global only               |
| `~/Documents/projects/entertainment_calendar` |         4,566 |                 15,942 | Existing relative symlink |
| `~/Documents/projects/family_manager`         |         5,292 |                 16,668 | Added relative import     |
| `~/Documents/projects/financial`              |        14,220 |                 25,596 | Existing relative symlink |
| `~/Documents/projects/health_dash`            |         6,207 |                 17,583 | Existing relative symlink |
| `~/Documents/projects/letterboxd`             |         6,726 |                 18,102 | Existing relative symlink |
| `~/Documents/projects/network_config`         |         2,914 |                 14,290 | Added relative import     |
| `~/Documents/projects/robinhood_dash`         |             0 |                 11,376 | Global only               |
| `~/Documents/projects/smarthome`              |         4,629 |                 16,005 | Added relative import     |
| `~/Documents/projects/space-invaders`         |             0 |                 11,376 | Global only               |
| `~/Documents/projects/website`                |         3,351 |                 14,727 | Existing relative symlink |
| `~/srv/norgate_exports`                       |             0 |                 11,376 | Global only               |
| `~/srv/robinhood_trading`                     |        17,223 |                 28,599 | Existing relative symlink |

Directories with no project instructions retain global guidance. This audit does not invent project rules for them.

## Repairs and retained boundaries

- Health Dashboard now loads a concise operating guide. It links to accepted ADRs and relevant sections of the preserved context.
- The guide separates current operating rules from dated health observations, former targets, seed data, and historical issue status.
- Added Claude imports in dotfiles, bootstrap_windows, family_manager, network_config, and smarthome.
- Corrected stale network instructions to use the existing Makefile checks.
- Added a global rule to check loading paths, links, overrides, and limits after instruction edits.
- Preserved the intentional Dixondale compatibility alias and all unrelated worktree changes.

## Remaining headroom and limitations

Trading's combined root content is 28,599 bytes. Review its size before adding substantial instructions; this audit retains its operating safeguards.
Launching Codex inside `~/dotfiles/codex` can include the global source again as a nested instruction file.
That conservative chain totals 30,266 source bytes before separators. Prefer the dotfiles repository root for instruction maintenance.

No new model session, remote host, cloud project, or plugin skill corpus was audited.
Managed settings and caller-supplied runtime overrides can change discovery; this report describes local files and the default budget.
Do not interpret an existing session's claim of compliance as proof of startup loading.

## Verification and reload

- Verified preservation of the full former Health Dashboard instruction text before formatting; Prettier left the reference unchanged.
- Checked formatting, whitespace, relative import targets, and instruction sizes.
- Smart Home `make validate` passed, including 83 tests.
- Network `make validate` passed, including fixture-based API wrapper tests.
- Family Manager's 18 unit tests passed.

Start a new task or session in the target project after changing instructions.
For Codex, ask the new session to identify its instruction sources and summarize one newly added rule.
For Claude, inspect `/context` and confirm the global and project files appear under Memory files.
On another machine, update its dotfiles checkout first. Existing symlinks do not update a remote checkout.

## Sources

- [Codex instruction discovery and limits](https://developers.openai.com/codex/guides/agents-md)
- [Claude instruction files and imports](https://code.claude.com/docs/en/memory)
