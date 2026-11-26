# 0007. Bundle and install the screen saver with macOS tools

- Status: Accepted
- Date: 2026-11-26

## Context

Michael's Mac is a personal Apple silicon screen saver. Its source checkout is local.
On macOS 27.2.1, System Events can discover the installed module and select it after a short delay.
The first installer read the ZIP from iCloud Drive. Fresh Macs needed to wait for iCloud sync.

## Decision

Track the reviewed release ZIP in `assets/` in the public dotfiles repository. Track its SHA-256 in the installer.
Verify the archive and signed bundle before installing it for the current user.
Select the saver with System Events and wait for macOS to report the selection.

## Rationale

The bootstrap checkout supplies the ZIP. The checksum pins the tested build.
macOS provides the tools for installation and selection.

## Consequences

Bootstrap checks for a complete checkout before setup. If installation or selection fails, bootstrap prints recovery instructions and continues.
The installer preserves existing bundles and lets the user select the saver in System Settings if automatic selection fails.
A new release requires a new ZIP, a new checksum, and a test of both the bundle and its selection.

## Revisit

Review this decision if macOS changes System Events discovery or if the build needs a different distribution channel.
