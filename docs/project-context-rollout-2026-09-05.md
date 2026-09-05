# Project context rollout — 5 September 2026

## Scope

Applied the [shared context standard](project-context-standard.md) to 16 distinct local project or artifact folders.
The intune_config compatibility path resolves to dixondale and was handled once.
Existing source layouts, private data, runtime services, and unrelated local edits were preserved.

| Folder                 | Delivery boundary                              |
| ---------------------- | ---------------------------------------------- |
| letterboxd             | Reviewed context tracked with code             |
| entertainment_calendar | Reviewed context tracked with code             |
| health_dash            | Reviewed context tracked with code             |
| code_flow              | Reviewed context tracked with code             |
| dixondale              | Reviewed context tracked with code             |
| smarthome              | Reviewed context tracked with code             |
| financial              | README tracked; internal context remains local |
| website                | README tracked; internal context remains local |
| bootstrap_windows      | Local documentation; no Git repository         |
| network_config         | Reviewed context tracked with code             |
| emailbriefing          | Local documentation; no Git repository         |
| robinhood_dash         | Local documentation; no Git repository         |
| family_manager         | Reviewed context tracked with code             |
| space-invaders         | Reviewed context tracked with code             |
| dotfiles               | Reviewed context tracked with code             |
| robinhood_trading      | Reviewed context tracked with code             |

## Changes

- Added consistent startup navigation to root agent instructions.
- Added or reused document indexes, current state, structure rules, operations, decision indexes, and handoff guidance.
- Added global creation and recording rules in codex/AGENTS.md.
- Preserved existing detailed references, decisions, dated evidence, and private tracking rules.
- Moved trading reporting requirements into a linked reference to keep root instruction loading within the default budget.
- Added a shared-context section to 13 existing Confluence runbooks and verified the resulting page bodies.

## Verification

- All core files exist in the 16 local folders.
- Claude imports or relative symlinks resolve to each project's AGENTS.md.
- Links in the changed Markdown resolve locally.
- Combined global and root project instructions fit a conservative 32 KiB budget.
- Formatting and task-scoped whitespace checks pass.
- Network and smart-home make validate checks pass; smart-home runs 83 tests.
- Family-manager tests pass (18 tests), and code-flow entrypoint syntax checks pass.
- Dixondale repository layout tests pass. PowerShell path checks remain unavailable because pwsh is not installed here.
- Confluence verification confirms the full prior page content and the intended appended sections.
- Financial and website internal context remains excluded from Git, as intended.

## Remaining boundaries

Git delivers only tracked files on the selected branch; fetch the relevant branch before starting on another device.
Financial and website need approved local context for work beyond their tracked clone-start instructions.
Windows bootstrap, briefing artifacts, and published trading outputs have no independent Git delivery.
The briefing artifact producer remains unidentified.
Native Omarchy behavior and files on the other Macs were not checked.
Space Invaders has unrelated existing source and dependency edits, including whitespace errors outside this task's files.
Do not include those edits in documentation commits.

## Ongoing use

### Git destinations

Existing upstream branches are preserved:

- dixondale: `feat/ap2-default-wallpaper`.
- smarthome: `feat/smart-home-foundation`.
- network_config: `codex/dachstopia-iot-wan-review`.
- family_manager: `skylight-api-client`.
- All other Git repositories: `main`, including health_dash's configured upstream.

These documentation changes do not merge existing feature branches into main.

Start through docs/README.md. Record verified facts and decisions as work proceeds.
Use a dated handoff for unfinished work; include its branch, commit, checks, and next action.
New projects use the same core documents. Optional directories are created only when they contain useful records.
