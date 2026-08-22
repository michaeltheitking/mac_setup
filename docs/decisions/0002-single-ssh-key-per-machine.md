# 2. One SSH key per machine, not one per destination

- Status: Accepted
- Date: 2026-08-22

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

All hosts use a single `~/.ssh/id_ed25519`. `ssh/config` and
`bootstrap_new_mac.sh`'s `SSH_KEY_PATH` both point at it. Key separation is
per-machine — one key per device, revoked when that device is lost.

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

- Losing a device means revoking one key from GitHub, not auditing which of two
  it held.
- `bootstrap_new_mac.sh` generates one key and registers it. Its keygen step is
  idempotent, so machines that already have `id_ed25519` skip it.
- Any machine still holding an `id_ed25519_github` keeps a now-unreferenced key.
  It is inert, but should be removed from the GitHub account and the disk.
- Revoking the shared key costs both GitHub and devbox access at once. That is
  the accepted tradeoff, and re-running bootstrap restores both.

## Revisit triggers

- Commit signing gets set up, making a separate signing key worthwhile.
- Agent forwarding into devbox becomes necessary, which would expose loaded keys
  to that host.
- Devbox stops being a personal machine, or a destination appears that is not
  fully trusted.
