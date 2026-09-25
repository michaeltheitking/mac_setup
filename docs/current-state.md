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

- 2026-09-25: Added the reviewed [iStat Menus 7 export](../istat-menus/README.md) from the local Documents file.
  The source file modification date is 2026-05-23. License and device fields are excluded.
  Plist validation and comparison confirm that all other settings match the source.
  Import of the sanitized copy remains unverified; current app settings were not changed.

- Native Omarchy behavior and the other Macs were not verified during this documentation baseline.
- Check current code, relevant issues, and live evidence before reusing historical claims.
- Record active task details in the existing issue or a [handoff](handoffs/README.md).
- Update this file when verified operating facts change; cite the check and its date.
