# Mac setup runbook update

Status: blocked, 2026-11-24.

The Mac setup changes are on `main` in commit `9dfe784`.
The [current state](../current-state.md) records the Mini checks. All implementation changes are in Git.
Only the update to the [Cross-Platform Dotfiles Runbook](https://michael-kingdocs.atlassian.net/wiki/spaces/~5570583e46f7b02769468785802b45c5e986a5/pages/61341700/Cross-Platform+Dotfiles+Runbook) remains.

## Changes to publish

- Use the [bootstrap inventory and sequence](../../README.md) for checkout validation, link conflicts, core verification, app failures, and retries.
- Add Screens 5 from the Mac App Store and the AWS CLI. Update the Linear and Screens verification steps.
- Remove Workbench installation instructions. Record retirement of the Mini's scheduled updater using the [updater guide](../daily-app-updates.md).
- Correct Sill's Intel support and update the website sync and clipboard transfer instructions from the repository.

## Next action

Read the latest page and draft before editing.
On November 24, the connector accepted previews but returned `internal_error` on publication and `snapshot_stale` on draft saves.
The published page still showed version 36. The browser required Atlassian sign-in.
Retry the connector or use a signed-in Confluence editor. Read back the published version and verify the changes above.
