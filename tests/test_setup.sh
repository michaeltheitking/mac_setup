#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

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
assert_absent "$omarchy_home/.tmux.conf" \
  "Omarchy setup replaced the Tmux configuration"
assert_absent "$omarchy_home/.zshrc" \
  "Omarchy setup replaced the Zsh configuration"
assert_absent "$omarchy_home/.config/ghostty/config" \
  "Omarchy setup replaced the Ghostty configuration"
assert_absent "$omarchy_home/.claude/settings.local.json" \
  "Omarchy setup created macOS-only Claude hooks"

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

if [ "$(uname -s)" = "Darwin" ]; then
  auto_home="$TEST_ROOT/auto-home"
  mkdir -p "$auto_home"
  HOME="$auto_home" DOTFILES_DIR="$REPO_DIR" "$REPO_DIR/setup.sh" >/dev/null
  assert_link "$auto_home/.zshrc" "$REPO_DIR/.zshrc"
fi

fake_bin="$TEST_ROOT/fake-bin"
mkdir -p "$fake_bin"
for command_name in omarchy pacman wl-copy; do
  ln -s /usr/bin/true "$fake_bin/$command_name"
done
verify_log="$TEST_ROOT/verify.log"
if ! HOME="$omarchy_home" PATH="$fake_bin:$PATH" DOTFILES_DIR="$REPO_DIR" \
  DOTFILES_PLATFORM=omarchy "$REPO_DIR/verify.sh" > "$verify_log"; then
  cat "$verify_log" >&2
  fail "Omarchy verification failed"
fi

echo "Setup tests passed."
