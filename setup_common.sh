#!/usr/bin/env bash

require_platform() {
  local expected="$1"
  local actual

  if [ -n "${DOTFILES_TEST_PLATFORM:-}" ]; then
    actual="$DOTFILES_TEST_PLATFORM"
  else
    case "$(uname -s)" in
      Darwin)
        actual="macos"
        ;;
      Linux)
        if command -v omarchy >/dev/null 2>&1; then
          actual="omarchy"
        else
          actual="unsupported-linux"
        fi
        ;;
      *)
        actual="unsupported"
        ;;
    esac
  fi

  if [ "$actual" != "$expected" ]; then
    echo "This setup script supports $expected only." >&2
    return 1
  fi
}

preflight_directory() {
  local directory="$1"

  if { [ -e "$directory" ] || [ -L "$directory" ]; } \
    && [ ! -d "$directory" ]; then
    echo "Required directory path is not a directory: $directory" >&2
    echo "Move or merge that path, then run setup again." >&2
    return 1
  fi
}

preflight_path() {
  local destination="$1"

  if [ -e "$destination" ] && [ ! -L "$destination" ]; then
    echo "Refusing to replace existing path: $destination" >&2
    echo "Move or merge that path, then run setup again." >&2
    return 1
  fi
}

link_path() {
  local source="$1"
  local destination="$2"

  mkdir -p "$(dirname "$destination")"

  if [ -L "$destination" ]; then
    if [ "$(readlink "$destination")" = "$source" ]; then
      return
    fi
    ln -sfn "$source" "$destination"
    return
  fi

  preflight_path "$destination"
  ln -s "$source" "$destination"
}

link_skills() {
  local skill

  mkdir -p "$HOME/.claude/skills" "$HOME/.codex/skills"
  for skill in "$DOTFILES_DIR"/claude/skills/*/; do
    [ -d "$skill" ] || continue
    link_path "${skill%/}" "$HOME/.claude/skills/$(basename "$skill")"
  done
  for skill in "$DOTFILES_DIR"/codex/skills/*/; do
    [ -d "$skill" ] || continue
    link_path "${skill%/}" "$HOME/.codex/skills/$(basename "$skill")"
  done
}

preflight_common() {
  local skill

  preflight_directory "$HOME/.codex"
  preflight_directory "$HOME/.claude"
  preflight_directory "$HOME/.codex/skills"
  preflight_directory "$HOME/.claude/skills"
  preflight_path "$HOME/.gitignore_global"
  preflight_path "$HOME/.codex/AGENTS.md"
  preflight_path "$HOME/.claude/settings.json"
  preflight_path "$HOME/.claude/statusline-command.sh"
  preflight_path "$HOME/.claude/CLAUDE.md"
  preflight_path "$HOME/.ssh/github-known-hosts"

  for skill in "$DOTFILES_DIR"/claude/skills/*/; do
    [ -d "$skill" ] || continue
    preflight_path "$HOME/.claude/skills/$(basename "$skill")"
  done
  for skill in "$DOTFILES_DIR"/codex/skills/*/; do
    [ -d "$skill" ] || continue
    preflight_path "$HOME/.codex/skills/$(basename "$skill")"
  done
}

setup_common() {
  mkdir -p "$HOME/.codex" "$HOME/.claude" "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  link_path "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
  link_path "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
  link_path "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
  link_path "$DOTFILES_DIR/claude/statusline-command.sh" \
    "$HOME/.claude/statusline-command.sh"
  link_path "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.claude/CLAUDE.md"
  link_path "$DOTFILES_DIR/ssh/github-known-hosts" \
    "$HOME/.ssh/github-known-hosts"
  link_skills

  git config --global core.excludesfile "$HOME/.gitignore_global"
}
