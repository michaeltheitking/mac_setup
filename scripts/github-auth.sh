#!/usr/bin/env bash
# Shared HTTPS setup and read-only checks. Never print or copy credentials.
set -uo pipefail

GITHUB_USERNAME="${GITHUB_USERNAME:-michaeltheitking}"

github_read_auth() {
  local metadata error
  metadata="$(gh auth status --hostname github.com --active --json hosts \
    --jq '(.hosts["github.com"] // [] | map(select(.active)) | .[0]) // {} | {state, tokenSource, error}' \
    2>/dev/null)" || {
    GITHUB_AUTH_STATE=unavailable
    echo 'GitHub status is unavailable. Check the network and installed gh version.' >&2
    return 1
  }
  GITHUB_AUTH_STATE="$(jq -r '.state // "missing"' <<< "$metadata")" || return 1
  GITHUB_AUTH_SOURCE="$(jq -r '.tokenSource // ""' <<< "$metadata")" || return 1
  error="$(jq -r '.error // ""' <<< "$metadata")" || return 1
  case "$GITHUB_AUTH_STATE" in
    success) return 0 ;;
    missing) echo 'GitHub needs browser authorization.' >&2 ;;
    error)
      if [[ "$error" == *'HTTP 401'* || "$error" == *'status code: 401 Unauthorized'* ]]; then
        GITHUB_AUTH_STATE=invalid
        echo 'GitHub authentication is invalid. Authorize this machine again.' >&2
      else
        echo 'GitHub access failed. Check network, service status, and gh auth status.' >&2
      fi
      ;;
    *) echo 'GitHub network access timed out or returned an unknown state.' >&2 ;;
  esac
  return 1
}

github_check_identity() {
  local login
  login="$(gh api --hostname github.com user --jq .login 2>/dev/null)" || {
    echo 'GitHub API access failed. Check network access and gh auth status.' >&2
    return 1
  }
  if [ "$login" != "$GITHUB_USERNAME" ]; then
    echo "Expected GitHub account $GITHUB_USERNAME. Use gh auth switch before setup." >&2
    return 1
  fi
}

github_check_storage() {
  case "$GITHUB_AUTH_SOURCE" in
    keyring) return 0 ;;
    GH_TOKEN|GITHUB_TOKEN)
      echo 'GitHub uses an environment credential. Confirm its source in the actual job environment.'
      return 2
      ;;
    *)
      echo 'GitHub uses plaintext or unrecognized credential storage. Reauthorize with an available native credential store.'
      return 2
      ;;
  esac
}

github_check_https() {
  local helper private_url effective_url storage_status=0
  github_read_auth || return 1
  github_check_identity || return 1
  if [ "$(gh config get git_protocol --host github.com 2>/dev/null)" != https ]; then
    echo 'GitHub CLI Git protocol is not HTTPS. Run github-auth.sh setup.' >&2
    return 1
  fi
  helper="$(git config --get-urlmatch credential.helper https://github.com 2>/dev/null)"
  if [[ "$helper" != *'gh auth git-credential'* ]]; then
    echo 'GitHub Git credential helper is missing. Run gh auth setup-git --hostname github.com.' >&2
    return 1
  fi
  private_url="$(gh api --hostname github.com 'user/repos?visibility=private&per_page=1' \
    --jq '[.[] | select(.private)] | .[0].clone_url // empty' 2>/dev/null)" || {
    echo 'GitHub private repository discovery failed. Check API permissions and network access.' >&2
    return 1
  }
  if [ -z "$private_url" ]; then
    echo 'GitHub API identity works; no private repository is available to verify Git authentication.'
    return 2
  fi
  case "$private_url" in
    https://github.com/*) ;;
    *) echo 'GitHub returned an unexpected repository URL.' >&2; return 1 ;;
  esac
  effective_url="$(git ls-remote --get-url "$private_url" 2>/dev/null)" || {
    echo 'GitHub repository URL resolution failed. Check Git configuration.' >&2
    return 1
  }
  if [ "$effective_url" != "$private_url" ]; then
    echo 'A Git URL rewrite changes the private HTTPS repository. Review Git configuration before retrying.' >&2
    return 1
  fi
  if ! GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/usr/bin/false GCM_INTERACTIVE=never \
    git -c credential.interactive=false -c http.lowSpeedLimit=1 -c http.lowSpeedTime=15 \
    ls-remote "$private_url" HEAD >/dev/null 2>&1; then
    echo 'GitHub HTTPS access to a private repository failed. Check Git credentials, permissions, and network access.' >&2
    return 1
  fi
  github_check_storage || storage_status=$?
  echo "GitHub API identity and private HTTPS Git read work for $GITHUB_USERNAME."
  return "$storage_status"
}

github_setup_https() {
  if ! github_read_auth; then
    case "$GITHUB_AUTH_STATE" in
      missing|invalid)
        if [ ! -t 0 ]; then
          echo 'Run browser authorization in a terminal: gh auth login --hostname github.com --git-protocol https --web' >&2
          return 1
        fi
        gh auth login --hostname github.com --git-protocol https --web || return 1
        github_read_auth || return 1
        ;;
      *) return 1 ;;
    esac
  fi
  github_check_identity || return 1
  if ! github_check_storage; then
    echo 'Bootstrap requires native credential storage. Check Keychain or Linux Secret Service, then reauthorize.' >&2
    return 1
  fi
  gh config set git_protocol https --host github.com || return 1
  gh auth setup-git --hostname github.com || return 1
  github_check_https
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-check}" in
    check) github_check_https ;;
    setup) github_setup_https ;;
    *) echo 'Usage: bash scripts/github-auth.sh [check|setup]' >&2; exit 1 ;;
  esac
fi
