#!/usr/bin/env bash
set -uo pipefail

HOST_KEY_FILE="${1:-$HOME/dotfiles/ssh/github-known-hosts}"
EXPECTED_FINGERPRINT="SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU"

if [ ! -f "$HOST_KEY_FILE" ]; then
  echo "GitHub host-key file not found: $HOST_KEY_FILE" >&2
  exit 1
fi

if ! awk '
  NF && $1 !~ /^#/ {
    records++
    valid = ($1 == "[ssh.github.com]:443" && $2 == "ssh-ed25519" && NF == 3)
  }
  END { exit !(records == 1 && valid) }
' "$HOST_KEY_FILE"; then
  echo "GitHub host-key file must contain one exact ssh.github.com:443 Ed25519 record." >&2
  exit 1
fi

actual_fingerprint="$(ssh-keygen -lf "$HOST_KEY_FILE" -E sha256 2>/dev/null | awk 'NR == 1 { print $2 }')"
if [ "$actual_fingerprint" != "$EXPECTED_FINGERPRINT" ]; then
  echo "GitHub Ed25519 host key does not match the pinned fingerprint." >&2
  exit 1
fi

echo "$actual_fingerprint"
