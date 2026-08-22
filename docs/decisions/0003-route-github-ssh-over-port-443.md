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
GitHub host block uses the repository's pinned Ed25519 key through
`UserKnownHostsFile`. `verify.sh` checks the route and the pinned fingerprint.
It also tests GitHub client authentication with a bounded, noninteractive probe.
The bootstrap validates the exact host-key record before its first SSH request.

## Rationale

Port 443 avoids the port 22 traffic pattern that triggered the IDS signature.
It keeps SSH key authentication and the existing Git remote URLs.

The hostname policy follows GitHub's supported SSH-over-HTTPS-port endpoint. It
does not depend on one GitHub address or a broad IDS exception.

## Consequences

- Git operations for `github.com` connect to `ssh.github.com:443`.
- GitHub still authenticates with `~/.ssh/id_ed25519`.
- HTTPS-only networks can permit GitHub SSH without opening outbound port 22.
- Host verification uses `ssh/github-known-hosts` from the managed repository.
- Fresh Macs clone this repository through HTTPS before the SSH remote is set.
- GitHub pushes do not need an interactive first-use host-key prompt.
- Health checks fail when the client key cannot authenticate with GitHub.
- A GitHub host-key rotation blocks SSH until the pinned key is verified and
  updated from GitHub's published fingerprints.
- The temporary fixed-IP UniFi suppression can be removed after every Mac uses
  this configuration.

## Revisit triggers

- GitHub ends SSH service on `ssh.github.com:443`.
- The network stops inspecting or blocking normal outbound GitHub SSH on port 22.
- The repository changes from SSH remotes to HTTPS remotes.
