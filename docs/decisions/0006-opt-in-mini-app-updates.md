# 0006: Use an opt-in user job for Mini app updates

Status: Accepted. Date: 2026-10-30.

## Context

Michael requests daily ChatGPT and Astropad Workbench updates on the Mac mini, followed by app relaunch.
The existing bootstrap installs ChatGPT through Homebrew and Workbench through an official DMG.
On 2026-10-30, both installed apps expose official public Sparkle release feeds in their bundles.
The installed unified ChatGPT app retains bundle ID `com.openai.codex`.

## Decision

Use an explicitly installed user LaunchAgent at 04:00 local time on the Mini.
Keep the schedule outside the shared bootstrap and setup paths.
Copy the reviewed updater into local Application Support so checkout changes cannot alter the running task.
Read the vendors' public feeds and install full ZIP or DMG releases.
Validate publisher signatures, bundle identifiers, build numbers, Gatekeeper acceptance, and CPU support before installation.
Keep one previous bundle for each app. Quit normally and relaunch after an update.

## Rationale

A user job can relaunch desktop apps within the signed-in session.
Direct release feeds cover both apps without adding another package manager or an UI automation dependency.
An explicit installation keeps the schedule on the requested host.
The local script copy avoids dependence on a development branch's working tree.

## Consequences

The job needs a logged-in desktop session and write access to `/Applications`.
It does not run before login or power on the Mac.
An update can interrupt Workbench access and active app work.
The task logs failures and does not force an app to quit.
Homebrew's ChatGPT cask receipt can lag the directly installed app version.
Reinstall the task after script changes. Publisher or feed changes require review.
An app process proves launch only; it does not establish app health or remote connectivity.

## Revisit triggers

Review this decision if a vendor supplies a supported unattended updater, changes its feed, or changes its signing identity.
Review the session model if updates must run without a logged-in desktop account.

See [operations and recovery](../daily-app-updates.md).
