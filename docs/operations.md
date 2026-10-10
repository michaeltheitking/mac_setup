# Operations

## Start work

Read [the overview](../README.md), [project instructions](../AGENTS.md), and [current state](current-state.md).
Use the existing command definitions as authoritative; do not invent a second command interface.

Use the README for bootstrap and setup. Follow AGENTS.md for the checks required by each changed file.
Use [manual settings backup and restore](manual-settings.md) for application settings that setup does not manage.
Use the [new-device walkthrough](../README.md#new-device-walkthrough) for browser authorization and automatic confirmation.
The Mac bootstrap supports a standalone download before Git exists.
It checks working developer-tool Git before cloning and stops when an existing target lacks Git metadata.

## Work across devices

Use a separate checkout and local dependencies on each device.
Inspect Git status, fetch available changes, and select the relevant task branch before integration.
Preserve uncommitted work; do not run blind automatic pulls or reset a checkout.
Keep production services on their declared host. Verify platform prerequisites before running commands on Omarchy.
Keep authentication and runtime data local. Use disposable test data and separate output paths.

## Record and deliver

Update affected instructions, current-state facts, and accepted decisions with the code change.
Use a [handoff](handoffs/README.md) for unfinished work; include branch, commit, checks, and the next action.
Review and push only authorized, non-sensitive files under the existing Git policy.
A push does not verify deployment or runtime behavior.

## Recovery and verification

On macOS, verification requires `pngpaste`, `btop`, `fastfetch`, and the three Microsoft application bundles.
Office supplies OneDrive; do not install the conflicting standalone OneDrive cask alongside Office.
Bootstrap exits unsuccessfully when final verification fails. A missing Mac verifier also prevents success.
Verification checks Git's global ignore-file setting and the selected GitHub transport.
HTTPS uses the expected API account, `gh` credential helper, and a private Git read.
SSH-selected machines retain active-config, trust, and authentication checks.
Authentication needs network access. Treat transport failures separately from credential failures.
Use [GitHub setup and recovery](github-authentication.md) on future machines.

Use the existing project checks and review the exact diff.
Check changed documentation links, instruction loading, and tracking rules.
For documentation-only recovery, reverse the specific documentation commit after reviewing subsequent changes.
Do not restore live databases, restart jobs, or overwrite source inputs as a documentation recovery step.
Record any unverified platform or unavailable check explicitly.
