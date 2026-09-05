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

- Native Omarchy behavior and the other Macs were not verified during this documentation baseline.
- Check current code, relevant issues, and live evidence before reusing historical claims.
- Record active task details in the existing issue or a [handoff](handoffs/README.md).
- Update this file when verified operating facts change; cite the check and its date.
