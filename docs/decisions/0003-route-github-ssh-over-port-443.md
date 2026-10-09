# 3. Default to GitHub HTTPS; retain optional SSH over port 443

- Status: Accepted
- Original date: 2026-08-22
- Revised: 2026-10-09

## Context

The original decision routed GitHub SSH through `ssh.github.com:443` after UniFi blocked port 22 traffic.
It used one per-machine key and a managed GitHub host-key pin.
This policy avoided the earlier port 22 issue but required key, agent, registration, and trust-file setup.

On 2026-10-09, all 13 inspected GitHub repository origins on the Mac mini use HTTPS.
GitHub API identity and a noninteractive private HTTPS Git read pass.
SSH verification fails because the configured trust file and client key are absent.
The bootstrap and health-check policy therefore conflict with the machine's working transport.

Michael requests simpler setup for future machines. Existing devices remain unchanged until repair is needed.
His web passkey already exists and remains separate from CLI credential storage.

## Decision

Both platform bootstraps use `scripts/github-auth.sh setup` for HTTPS Git through GitHub CLI.
Reuse valid credentials or request browser authorization in an interactive terminal.
Verify the expected account before configuring the Git protocol and credential helper.
Require native credential storage for new bootstrap. Stop and report file-storage fallback.
Test a private Git read without prompting, in addition to API authentication.

Do not generate GitHub SSH keys, start agents, register keys, or rewrite existing remotes during bootstrap.
Existing SSH configuration and pinned trust remain available for devices that select SSH.
Their route remains `ssh.github.com:443`, with the existing per-machine key and exact pinned host trust.
HTTPS verification requires no GitHub SSH key or trust file.
Verification reports legacy file storage without modifying it.

## Rationale

HTTPS shares the CLI credential with Git and removes GitHub-specific SSH enrollment from future setup.
It matches the verified Mac mini transport and avoids SSH host-key maintenance for default Git operations.
Browser authorization still requires initial human consent. Website login uses the existing passkey separately.

Keeping optional SSH preserves established devices and remote-machine access.
Silently weakening SSH host verification or copying credentials between machines is not an acceptable alternative.

## Consequences

- New devices authorize the CLI once and store credentials in the native credential store.
- Native storage must work in the intended desktop session; unavailable storage stops bootstrap.
- A vendor fallback can leave a local file-backed credential. Recovery remains explicit and preserves working credentials.
- Existing devices, SSH keys, remotes, and scheduled jobs receive no automatic migration.
- SSH-selected machines still require valid pinned trust and an authorized device key.
- HTTPS checks prove API identity and private Git read access, not every repository's write permission.
- Scheduled jobs require validation in their actual account and environment.
- No private repository leaves Git authentication unverified and prevents complete bootstrap.

## Revisit triggers

- GitHub changes CLI authorization or credential-storage behavior.
- A required native credential store is unavailable on a supported platform.
- Future automation requires access outside an unlocked desktop session.
- A destination requires SSH, commit signing, or a separate service identity.

See [setup and recovery](../github-authentication.md) and [SSH key scope](0002-single-ssh-key-per-machine.md).
