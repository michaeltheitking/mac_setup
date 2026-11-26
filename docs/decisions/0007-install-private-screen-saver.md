# 0007. Install the private screen saver with macOS tools

- Status: Accepted
- Date: 2026-11-26

## Context

Michael's Mac is a personal Apple silicon screen saver. The source checkout and generated bundle are local.
On macOS 27.2.1, System Events can discover the installed module and select it after a short delay.

## Decision

Store the release ZIP in the owner's private iCloud Drive under **Mac Setup**. Track its SHA-256 in the installer.
Verify the archive and signed bundle before installing it for the current user.
Select the saver with System Events and wait for macOS to report the selection.

## Rationale

Private iCloud Drive gives the owner's Macs a common source. The checksum pins the tested build.
macOS provides the tools for installation and selection.

## Consequences

If the archive or Automation permission is unavailable, bootstrap prints recovery instructions and continues.
The installer preserves existing bundles and lets the user select the saver in System Settings if automatic selection fails.
A new release requires a new checksum and a test of both the bundle and its selection.

## Revisit

Review this decision if macOS changes System Events discovery or if the build needs a different distribution channel.
