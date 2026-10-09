# 2. One SSH key per machine, not one per destination

- Status: Accepted
- Date: 2026-08-22
- Revised: 2026-10-09; GitHub bootstrap moves to HTTPS under decision 0003.

## Context

`ssh/config` previously pointed `github.com` at `~/.ssh/id_ed25519_github`
while the three devbox hosts used `~/.ssh/id_ed25519`, and
`bootstrap_new_mac.sh` generated and registered the GitHub-specific key. The
intent was per-destination key separation, so either key could be revoked
without disturbing the other.

The split was never enforced in practice. `id_ed25519.pub` is an authorized key
on the GitHub account, so the devbox key could already push to GitHub. The
separation existed in `ssh/config` but not in GitHub's authorized-keys list,
which is the only place it would have had an effect.

It also failed to survive contact with a real machine: a Mac whose key predated
the split had only `id_ed25519`, so `ssh -T git@github.com` failed outright with
`Permission denied (publickey)` rather than falling back.

## Decision

SSH destinations use a single `~/.ssh/id_ed25519` when a machine needs SSH access.
Key separation remains per-machine. Revoke the device key when that device is lost.
New GitHub setup uses HTTPS under [decision 0003](0003-route-github-ssh-over-port-443.md).
Bootstrap no longer generates, registers, or loads an SSH key for GitHub.

## Rationale

The per-destination split protected against a threat this setup does not have.
No host block sets `ForwardAgent`, so neither private key ever leaves the Mac;
a compromised devbox yields no key material and leaves nothing to revoke
separately.

Meanwhile the threat that is real — a stolen laptop, or anything that can read
`~/.ssh` — takes every key at once. Both keys sat in the same directory on the
same disk, and every host block sets `AddKeysToAgent yes`, so both were loaded
into the same agent. The split added no protection there.

Commit signing would have justified a dedicated key, since a signing key is
worth separating from an authentication key. No signing is configured:
`user.signingkey` is unset and there is no `allowed_signers`.

What remains is a per-device boundary, which one key per machine already
provides.

## Consequences

- Existing machines retain their keys and registrations. This change performs no key cleanup or device migration.
- Enroll a per-machine key separately when remote-machine SSH access is required.
- On legacy machines, revoking a shared key can affect both GitHub SSH and devbox access.
- New HTTPS GitHub credentials have a separate lifecycle from remote-machine SSH keys.

## Revisit triggers

- Commit signing gets set up, making a separate signing key worthwhile.
- Agent forwarding into devbox becomes necessary, which would expose loaded keys
  to that host.
- Devbox stops being a personal machine, or a destination appears that is not
  fully trusted.
