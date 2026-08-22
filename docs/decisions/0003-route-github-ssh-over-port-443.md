# 3. Route GitHub SSH over port 443

- Status: Accepted
- Date: 2026-08-22

## Context

GitHub SSH normally uses TCP port 22. UniFi identified normal GitHub SSH pushes
as `ET SCAN Potential SSH Scan OUTBOUND`. It blocked two connections from a Mac
to a GitHub address.

A destination-IP suppression restored access, but GitHub can use different IP
addresses. A fixed-IP exception is not a durable transport policy.

GitHub also provides SSH at `ssh.github.com` on TCP port 443. This endpoint uses
the same GitHub account key and Git remote syntax.

## Decision

The `github.com` SSH host entry uses `ssh.github.com` on TCP port 443 as user
`git`. It keeps the per-machine key from decision 0002.

`verify.sh` checks the effective hostname, port, and user through `ssh -G`. The
check fails when any value changes.

## Rationale

Port 443 avoids the port 22 traffic pattern that triggered the IDS signature.
It keeps SSH key authentication and the existing Git remote URLs.

The hostname policy follows GitHub's supported SSH-over-HTTPS-port endpoint. It
does not depend on one GitHub address or a broad IDS exception.

## Consequences

- Git operations for `github.com` connect to `ssh.github.com:443`.
- GitHub still authenticates with `~/.ssh/id_ed25519`.
- HTTPS-only networks can permit GitHub SSH without opening outbound port 22.
- Host verification stores the key under `[ssh.github.com]:443`.
- A first connection on a new Mac must verify GitHub's published host key.
- The temporary fixed-IP UniFi suppression can be removed after every Mac uses
  this configuration.

## Revisit triggers

- GitHub ends SSH service on `ssh.github.com:443`.
- The network stops inspecting or blocking normal outbound GitHub SSH on port 22.
- The repository changes from SSH remotes to HTTPS remotes.
