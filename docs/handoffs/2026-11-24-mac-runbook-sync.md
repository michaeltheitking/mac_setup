# Mac setup runbook update

Status: completed, 2026-11-24.

The Mac setup changes are on `main` in commit `9dfe784`.
The [current state](../current-state.md) records the Mini checks. All implementation changes are in Git.
Confluence version 37 includes the update to the [Cross-Platform Dotfiles Runbook](https://michael-kingdocs.atlassian.net/wiki/spaces/~5570583e46f7b02769468785802b45c5e986a5/pages/61341700/Cross-Platform+Dotfiles+Runbook).

## Published changes

- Use the [bootstrap inventory and sequence](../../README.md) for checkout validation, link conflicts, core verification, app failures, and retries.
- Add Screens 5 from the Mac App Store and the AWS CLI. Update the Linear and Screens verification steps.
- Remove Workbench installation instructions. Record retirement of the Mini's scheduled updater using the [updater guide](../daily-app-updates.md).
- Correct Sill's Intel support and update the website sync and clipboard transfer instructions from the repository.
- Add the native Table of Contents macro below the introduction.

## Verification

The connector preview passed, but publication returned `internal_error`.
The signed-in Confluence editor published version 37 after a check of the draft.
A read of the published page confirmed the content changes and the native macro.
The macro displayed 31 heading links. The Screens 5 link opened its section.
Version 36 is the rollback point in Confluence page history.
