#!/usr/bin/env bash
set -uo pipefail

github_ssh_authenticate() {
  local output
  local status

  if output="$(ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1)"; then
    status=0
  else
    status=$?
  fi

  printf '%s\n' "$output"
  if [ "$status" -eq 1 ] && printf '%s\n' "$output" | grep -Fq "successfully authenticated"; then
    return 0
  fi

  echo "GitHub SSH authentication failed with exit code $status." >&2
  if [ "$status" -eq 0 ]; then
    return 1
  fi
  return "$status"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  github_ssh_authenticate
fi
