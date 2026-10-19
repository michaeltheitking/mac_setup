# Current state

## Evidence boundary

Documentation baseline: 2026-09-05. Source: local file layout, project instructions, and README.
This records repository context, not a new live-system verification.

## Purpose and maintained sources

Maintain shared configuration and platform setup for macOS and Omarchy.
See [the overview](../README.md), [project instructions](../AGENTS.md), and [the document index](README.md).
Accepted [decisions](decisions/README.md) govern architecture. Existing detailed references retain their evidence dates.

## Runtime and data boundary

Use the README for bootstrap and setup. Follow AGENTS.md for the checks required by each changed file.
Keep credentials, private source records, live databases, and generated state outside shared context.
Use separate development checkouts. Do not install production schedules merely because a checkout exists.

## Known gaps and next work

- 2026-10-19: Added Sill for Mac through the official `saffsanity/sill/sill` Homebrew cask.
  The [vendor download page](https://getsill.app/download.html) links the tap;
  its [cask](https://github.com/Saffsanity/homebrew-sill/blob/main/Casks/sill.rb) declares
  version 0.5.1, a SHA-256-checked official DMG, Apple silicon, and macOS 14 or later.
  Read-only Info.plist checks confirm `/Applications/Sill.app` is 0.5.1 build 563 on the mini.
  Shell syntax checks and `tests/test-mac-bootstrap.sh` pass.
  No app installation, full bootstrap, permissions changes, or desktop interaction ran.
  Confluence synchronization remains pending under the task's filesystem/shell-only restriction;
  see the [handoff](handoffs/2026-10-19-sill-confluence-sync.md).

- 2026-10-09, new-device walkthrough: README and Confluence now document browser authorization and automatic confirmation.
  The Mac bootstrap supports a standalone download before the first Git clone.
  It confirms working developer-tool Git and preserves conflicting clone targets.
  Isolated fixtures pass installation, stale selection, GUI fallback, failure, reuse, and target-preservation checks.
  These fixtures do not verify Apple's live installer or a complete fresh-device bootstrap.

- 2026-10-09, GitHub policy update: Both bootstraps now select HTTPS through a shared CLI authentication helper.
  They no longer generate or enroll GitHub SSH keys, start agents, or change repository remotes.
  This supersedes the mandatory SSH health-check claim in the earlier 2026-10-09 entry below.
  The Mac mini's API identity and private HTTPS Git read pass under existing credentials.
  The updated health check reports no failures and one legacy credential-storage warning.
  Existing credentials, keys, remote URLs, and launchd jobs remain unchanged.
  See [GitHub authentication](github-authentication.md) for setup, evidence, and remaining platform gaps.

- 2026-10-09: The Mac bootstrap includes Edge Beta and Windows App. Microsoft Office supplies OneDrive.
  `pngpaste` 0.2.3 and `btop` 1.4.7 installed locally through Homebrew.
  Verification now requires these tools, `fastfetch`, Microsoft app bundles, and managed Git ignore wiring.
  It checks the active SSH config and host key. Bootstrap stops when verification fails or cannot run.
  Shell syntax checks and both isolated test suites pass.
  The local read-only check finds a missing `~/.ssh/github-known-hosts` link and failed GitHub SSH authentication.
  The SSH helper reports `Host key verification failed`. No trust repair or full bootstrap ran.
  The [manual settings guide](manual-settings.md) documents private exports, account setup, and restore checks.
  Export and restore workflows remain unverified. Native Omarchy behavior remains unverified.

- 2026-09-25: Added the reviewed [iStat Menus 7 export](../istat-menus/README.md) from the local Documents file.
  The source file modification date is 2026-05-23. License and device fields are excluded.
  Plist validation and comparison confirm that all other settings match the source.
  Import of the sanitized copy remains unverified; current app settings were not changed.

- Native Omarchy behavior and the other Macs were not verified during this documentation baseline.
- Check current code, relevant issues, and live evidence before reusing historical claims.
- Record active task details in the existing issue or a [handoff](handoffs/README.md).
- Update this file when verified operating facts change; cite the check and its date.
