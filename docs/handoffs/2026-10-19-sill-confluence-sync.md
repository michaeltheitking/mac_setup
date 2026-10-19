# Sill runbook synchronization

Status: completed, 2026-10-19.

## Goal and completed work

Add Sill for Mac to reproducible setup in `/Users/michael/dotfiles`, branch `main`.
The implementation commit is `208cf1b`; this handoff was committed with the Sill change.
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

## Synchronization result

Updated the [Cross-Platform Dotfiles Runbook](https://michael-kingdocs.atlassian.net/wiki/spaces/~5570583e46f7b02769468785802b45c5e986a5/pages/61341700/Cross-Platform+Dotfiles+Runbook)
from version 34 to version 35 through the connector on 2026-10-19.
Three targeted insertions add the official cask to the software table, explain
SHA-256 verification and hardware/OS requirements, and document manual permissions/pairing.

The first pass deferred this write under the filesystem/shell-only task restriction.
Michael explicitly requested a retry and clarified that connector/API tools were permitted;
the restriction concerned shared desktop UI conflicts. The retry succeeded without desktop
or browser interaction. No page permissions were changed and no push was performed.
No further synchronization action remains.

## Validation

Passed `bash -n bootstrap_new_mac.sh`, `zsh -n .zshrc`,
`bash tests/test-mac-bootstrap.sh`, and `git diff --check` on 2026-10-19.
These checks do not install Sill or exercise a fresh Mac bootstrap. The existing app,
permissions, and pairing remain untouched.

Connector dry-run validation succeeded before publishing. A full HTML read-back of
version 35 confirms the cask, checksum verification, requirements, permissions, and
pairing instructions. All 940 original node IDs remain, and all 499 original paragraph,
heading, and code blocks retain their text and markup after HTML entity normalization.
