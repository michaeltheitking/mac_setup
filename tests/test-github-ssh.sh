#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINNED_HOST_KEY="$REPO_DIR/ssh/github-known-hosts"
EXPECTED_FINGERPRINT="SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU"
CHECK_HOST_KEY="$REPO_DIR/scripts/check-github-host-key.sh"
CHECK_AUTH="$REPO_DIR/scripts/github-ssh-auth.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

actual_fingerprint="$("$CHECK_HOST_KEY" "$PINNED_HOST_KEY")"
if [ "$actual_fingerprint" != "$EXPECTED_FINGERPRINT" ]; then
  echo "GitHub Ed25519 host-key fingerprint does not match the pinned fingerprint."
  exit 1
fi

if "$CHECK_HOST_KEY" "$TEST_DIR/missing-known-hosts" >/dev/null 2>&1; then
  echo "Missing GitHub host-key files must fail validation."
  exit 1
fi

ssh-keygen -q -t ed25519 -N '' -f "$TEST_DIR/wrong-key"
awk '{ print "[ssh.github.com]:443 " $1 " " $2 }' "$TEST_DIR/wrong-key.pub" > "$TEST_DIR/wrong-known-hosts"
if "$CHECK_HOST_KEY" "$TEST_DIR/wrong-known-hosts" >/dev/null 2>&1; then
  echo "Incorrect GitHub host keys must fail validation."
  exit 1
fi

awk 'NF && $1 !~ /^#/ { print "github.example:443 " $2 " " $3 }' "$PINNED_HOST_KEY" > "$TEST_DIR/wrong-host-known-hosts"
if "$CHECK_HOST_KEY" "$TEST_DIR/wrong-host-known-hosts" >/dev/null 2>&1; then
  echo "A GitHub key bound to the wrong host must fail validation."
  exit 1
fi

cp "$PINNED_HOST_KEY" "$TEST_DIR/extra-known-hosts"
awk '{ print "[ssh.github.com]:443 " $1 " " $2 }' "$TEST_DIR/wrong-key.pub" >> "$TEST_DIR/extra-known-hosts"
if "$CHECK_HOST_KEY" "$TEST_DIR/extra-known-hosts" >/dev/null 2>&1; then
  echo "Additional trusted GitHub host keys must fail validation."
  exit 1
fi

# shellcheck source=../scripts/github-ssh-auth.sh
source "$CHECK_AUTH"

ssh() {
  echo "Hi test! You've successfully authenticated, but GitHub does not provide shell access."
  return 1
}
github_ssh_authenticate >/dev/null

ssh() {
  echo "Permission denied (publickey)."
  return 1
}
if github_ssh_authenticate >/dev/null 2>&1; then
  echo "Rejected GitHub keys must fail authentication validation."
  exit 1
fi

ssh() { return 255; }
if github_ssh_authenticate >/dev/null 2>&1; then
  echo "GitHub transport failures must fail authentication validation."
  exit 1
fi

ssh() { return 0; }
if github_ssh_authenticate >/dev/null 2>&1; then
  echo "Unexpected GitHub SSH success exits must fail validation."
  exit 1
fi
unset -f ssh

for ssh_config in "$REPO_DIR/ssh/config" "$REPO_DIR/ssh/config.omarchy"; do
  github_ssh_config="$(ssh -G -F "$ssh_config" github.com 2>/dev/null)"
  if ! awk -v known_hosts="$HOME/.ssh/github-known-hosts" '
    $0 == "hostname ssh.github.com" { hostname = 1 }
    $0 == "port 443" { port = 1 }
    $0 == "user git" { user = 1 }
    $0 == "identityfile ~/.ssh/id_ed25519" { identity = 1 }
    $0 == "userknownhostsfile " known_hosts { hosts = 1 }
    $0 == "globalknownhostsfile /dev/null" { global_hosts = 1 }
    END { exit !(hostname && port && user && identity && hosts && global_hosts) }
  ' <<< "$github_ssh_config"; then
    echo "$ssh_config must pin the complete GitHub SSH route, key, and trust file."
    exit 1
  fi
done

for bootstrap_script in bootstrap_new_mac.sh bootstrap_omarchy.sh; do
  if ! awk '
    index($0, "$DOTFILES_DIR/setup.sh") && !setup { setup = NR }
    index($0, "scripts/check-github-host-key.sh") && !trust { trust = NR }
    index($0, "scripts/github-ssh-auth.sh") && !auth { auth = NR }
    END { exit !(setup && trust && auth && setup < trust && trust < auth) }
  ' "$REPO_DIR/$bootstrap_script"; then
    echo "$bootstrap_script must validate managed SSH trust before GitHub authentication."
    exit 1
  fi
done

echo "GitHub SSH policy is valid."
