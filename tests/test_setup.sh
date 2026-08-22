#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

unset DOTFILES_PLATFORM DOTFILES_TEST_PLATFORM

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_link() {
  local link="$1"
  local target="$2"

  [ -L "$link" ] || fail "$link is not a symbolic link"
  [ "$(readlink "$link")" = "$target" ] \
    || fail "$link does not point to $target"
}

assert_absent() {
  local path="$1"
  local message="$2"

  if [ -e "$path" ] || [ -L "$path" ]; then
    fail "$message"
  fi
}

mac_home="$TEST_ROOT/macos-home"
mkdir -p "$mac_home"
HOME="$mac_home" DOTFILES_DIR="$REPO_DIR" DOTFILES_PLATFORM=macos \
  DOTFILES_TEST_PLATFORM=macos \
  "$REPO_DIR/setup.sh" >/dev/null
HOME="$mac_home" DOTFILES_DIR="$REPO_DIR" DOTFILES_PLATFORM=macos \
  DOTFILES_TEST_PLATFORM=macos \
  "$REPO_DIR/setup.sh" >/dev/null

assert_link "$mac_home/.tmux.conf" "$REPO_DIR/.tmux.conf"
assert_link "$mac_home/.zshrc" "$REPO_DIR/.zshrc"
assert_link "$mac_home/.ssh/config" "$REPO_DIR/ssh/config"
assert_link "$mac_home/.ssh/github-known-hosts" \
  "$REPO_DIR/ssh/github-known-hosts"
assert_link "$mac_home/.config/ghostty/config" "$REPO_DIR/ghostty/config.ghostty"
[ -f "$mac_home/.claude/settings.local.json" ] \
  || fail "macOS local Claude settings were not created"

omarchy_home="$TEST_ROOT/omarchy-home"
mkdir -p "$omarchy_home"
HOME="$omarchy_home" DOTFILES_DIR="$REPO_DIR" DOTFILES_PLATFORM=omarchy \
  DOTFILES_TEST_PLATFORM=omarchy \
  "$REPO_DIR/setup.sh" >/dev/null
HOME="$omarchy_home" DOTFILES_DIR="$REPO_DIR" DOTFILES_PLATFORM=omarchy \
  DOTFILES_TEST_PLATFORM=omarchy \
  "$REPO_DIR/setup.sh" >/dev/null

assert_link "$omarchy_home/.codex/AGENTS.md" "$REPO_DIR/codex/AGENTS.md"
assert_link "$omarchy_home/.ssh/config" "$REPO_DIR/ssh/config.omarchy"
assert_link "$omarchy_home/.ssh/github-known-hosts" \
  "$REPO_DIR/ssh/github-known-hosts"
assert_absent "$omarchy_home/.tmux.conf" \
  "Omarchy setup replaced the Tmux configuration"
assert_absent "$omarchy_home/.zshrc" \
  "Omarchy setup replaced the Zsh configuration"
assert_absent "$omarchy_home/.config/ghostty/config" \
  "Omarchy setup replaced the Ghostty configuration"
assert_absent "$omarchy_home/.claude/settings.local.json" \
  "Omarchy setup created macOS-only Claude hooks"

stale_link_home="$TEST_ROOT/stale-link-home"
mkdir -p "$stale_link_home/.ssh"
ln -s "$TEST_ROOT/missing-ssh-config" "$stale_link_home/.ssh/config"
HOME="$stale_link_home" DOTFILES_DIR="$REPO_DIR" DOTFILES_PLATFORM=omarchy \
  DOTFILES_TEST_PLATFORM=omarchy \
  "$REPO_DIR/setup.sh" >/dev/null
assert_link "$stale_link_home/.ssh/config" "$REPO_DIR/ssh/config.omarchy"

wrong_platform_home="$TEST_ROOT/wrong-platform-home"
mkdir -p "$wrong_platform_home"
if HOME="$wrong_platform_home" DOTFILES_DIR="$REPO_DIR" \
  DOTFILES_TEST_PLATFORM=omarchy "$REPO_DIR/setup_macos.sh" \
  >/dev/null 2>&1; then
  fail "direct macOS setup accepted Omarchy"
fi
assert_absent "$wrong_platform_home/.gitignore_global" \
  "direct macOS setup made changes on Omarchy"
if HOME="$wrong_platform_home" DOTFILES_DIR="$REPO_DIR" \
  DOTFILES_TEST_PLATFORM=macos "$REPO_DIR/setup_omarchy.sh" \
  >/dev/null 2>&1; then
  fail "direct Omarchy setup accepted macOS"
fi
assert_absent "$wrong_platform_home/.gitignore_global" \
  "direct Omarchy setup made changes on macOS"

conflict_home="$TEST_ROOT/conflict-home"
mkdir -p "$conflict_home/.ssh"
printf 'keep me\n' > "$conflict_home/.ssh/config"
if HOME="$conflict_home" DOTFILES_DIR="$REPO_DIR" DOTFILES_PLATFORM=omarchy \
  DOTFILES_TEST_PLATFORM=omarchy \
  "$REPO_DIR/setup.sh" >/dev/null 2>&1; then
  fail "setup accepted a conflicting regular file"
fi
[ "$(cat "$conflict_home/.ssh/config")" = "keep me" ] \
  || fail "setup changed a conflicting regular file"
assert_absent "$conflict_home/.gitignore_global" \
  "setup made partial changes before reporting a conflict"

parent_conflict_home="$TEST_ROOT/parent-conflict-home"
mkdir -p "$parent_conflict_home/.codex"
printf 'keep me\n' > "$parent_conflict_home/.codex/skills"
if HOME="$parent_conflict_home" DOTFILES_DIR="$REPO_DIR" \
  DOTFILES_PLATFORM=omarchy DOTFILES_TEST_PLATFORM=omarchy \
  "$REPO_DIR/setup.sh" >/dev/null 2>&1; then
  fail "setup accepted a regular file at a required directory path"
fi
[ "$(cat "$parent_conflict_home/.codex/skills")" = "keep me" ] \
  || fail "setup changed a conflicting parent path"
assert_absent "$parent_conflict_home/.gitignore_global" \
  "setup made partial changes before reporting a parent conflict"

auto_omarchy_bin="$TEST_ROOT/auto-omarchy-bin"
auto_omarchy_home="$TEST_ROOT/auto-omarchy-home"
mkdir -p "$auto_omarchy_bin" "$auto_omarchy_home"
printf '#!/bin/sh\nprintf "Linux\\n"\n' > "$auto_omarchy_bin/uname"
printf '#!/bin/sh\nexit 0\n' > "$auto_omarchy_bin/omarchy"
chmod +x "$auto_omarchy_bin/uname" "$auto_omarchy_bin/omarchy"
HOME="$auto_omarchy_home" PATH="$auto_omarchy_bin:$PATH" \
  DOTFILES_DIR="$REPO_DIR" "$REPO_DIR/setup.sh" >/dev/null
assert_link "$auto_omarchy_home/.ssh/config" "$REPO_DIR/ssh/config.omarchy"
assert_absent "$auto_omarchy_home/.zshrc" \
  "automatic Omarchy detection selected the macOS setup"

unsupported_bin="$TEST_ROOT/unsupported-bin"
unsupported_home="$TEST_ROOT/unsupported-home"
mkdir -p "$unsupported_bin" "$unsupported_home"
ln -s "$(command -v bash)" "$unsupported_bin/bash"
printf '#!/bin/sh\nprintf "Linux\\n"\n' > "$unsupported_bin/uname"
chmod +x "$unsupported_bin/uname"
if HOME="$unsupported_home" PATH="$unsupported_bin" DOTFILES_DIR="$REPO_DIR" \
  "$REPO_DIR/setup.sh" >/dev/null 2>&1; then
  fail "automatic platform detection accepted unsupported Linux"
fi
assert_absent "$unsupported_home/.gitignore_global" \
  "unsupported Linux detection made changes"

fake_bin="$TEST_ROOT/fake-bin"
mkdir -p "$fake_bin"
for command_name in omarchy pacman wl-copy; do
  ln -s /usr/bin/true "$fake_bin/$command_name"
done
printf '%s\n' \
  '#!/bin/sh' \
  'case " $* " in' \
  '  *" -G "*)' \
  '    printf "hostname ssh.github.com\nport 443\nuser git\nuserknownhostsfile %s/.ssh/github-known-hosts\nglobalknownhostsfile /dev/null\n" "$HOME"' \
  '    exit 0' \
  '    ;;' \
  '  *" -T "*)' \
  '    echo "Hi test! You have successfully authenticated, but GitHub does not provide shell access."' \
  '    exit 1' \
  '    ;;' \
  'esac' \
  'exit 2' > "$fake_bin/ssh"
chmod +x "$fake_bin/ssh"
verify_log="$TEST_ROOT/verify.log"
if ! HOME="$omarchy_home" PATH="$fake_bin:$PATH" DOTFILES_DIR="$REPO_DIR" \
  DOTFILES_PLATFORM=omarchy "$REPO_DIR/verify.sh" > "$verify_log"; then
  cat "$verify_log" >&2
  fail "Omarchy verification failed"
fi

(
  # Loading the bootstrap exposes its read-only installed-state helpers.
  source "$REPO_DIR/bootstrap_omarchy.sh"

  claude() {
    case "$*" in
      "plugin marketplace list --json")
        printf '[{"name":"compound-engineering-plugin"}]\n'
        ;;
      "plugin list --json")
        printf '[{"id":"context7@claude-plugins-official"}]\n'
        ;;
      *)
        return 2
        ;;
    esac
  }

  claude_marketplace_installed "compound-engineering-plugin" \
    || fail "Claude marketplace exact match was not found"
  if claude_marketplace_installed "compound-engineering"; then
    fail "Claude marketplace helper accepted a partial match"
  fi
  claude_plugin_installed "context7@claude-plugins-official" \
    || fail "Claude plugin exact match was not found"
  if claude_plugin_installed "context7"; then
    fail "Claude plugin helper accepted a partial match"
  fi

  SSH_KEY_PATH="$TEST_ROOT/github-key"
  printf 'ssh-ed25519 AAAAtestkey local-comment\n' > "${SSH_KEY_PATH}.pub"
  gh() {
    [ "$*" = "api user/keys --paginate --jq .[].key" ] || return 2
    printf '%s\n' \
      'ssh-ed25519 AAAAotherkey' \
      'ssh-ed25519 AAAAtestkey'
  }

  github_has_ssh_key || fail "GitHub SSH key exact match was not found"
  printf 'ssh-ed25519 AAAAtest local-comment\n' > "${SSH_KEY_PATH}.pub"
  if github_has_ssh_key; then
    fail "GitHub SSH key helper accepted a partial match"
  fi
)

echo "Setup tests passed."
