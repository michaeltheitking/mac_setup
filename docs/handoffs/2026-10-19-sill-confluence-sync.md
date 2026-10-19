# Sill runbook synchronization

Status: blocked, 2026-10-19.

## Goal and completed work

Add Sill for Mac to reproducible setup in `/Users/michael/dotfiles`, branch `main`.
The preceding commit is `f0576a9`; this handoff is committed with the Sill change.
The official `saffsanity/sill/sill` cask is declared in
[the Mac bootstrap](../../bootstrap_new_mac.sh), with installation requirements in
[the README](../../README.md#macos-install-inventory) and manual permissions/pairing in
[the settings guide](../manual-settings.md).
The unrelated local `claude/settings.json` edit is excluded from this change.

The vendor's [download page](https://getsill.app/download.html) links its
[Homebrew tap](https://github.com/Saffsanity/homebrew-sill).
The cask verifies the official DMG's SHA-256 and requires Apple silicon/macOS 14 or later.
The existing app was confirmed as 0.5.1 build 563 via Info.plist reads only.
No new architecture decision is needed for this routine package addition.

## Remaining action and restriction

Update the [Cross-Platform Dotfiles Runbook](https://michael-kingdocs.atlassian.net/wiki/spaces/~5570583e46f7b02769468785802b45c5e986a5/pages/61341700/Cross-Platform+Dotfiles+Runbook)
to include the official cask, hardware/OS requirements, and manual permissions/pairing follow-ups.
This external write was not attempted: the task restricts this session to filesystem
and shell tools and excludes desktop interaction. A session authorized to use the
Confluence connector can finish the synchronization. No action was denied or has an
uncertain outcome. No push is authorized by this task.

## Validation

Passed `bash -n bootstrap_new_mac.sh`, `zsh -n .zshrc`,
`bash tests/test-mac-bootstrap.sh`, and `git diff --check` on 2026-10-19.
These checks do not install Sill or exercise a fresh Mac bootstrap. The existing app,
permissions, and pairing remain untouched.
