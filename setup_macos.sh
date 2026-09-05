#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
# shellcheck source=setup_common.sh
source "$DOTFILES_DIR/setup_common.sh"

require_platform macos

preflight_directory "$HOME/.ssh"
preflight_directory "$HOME/.config"
preflight_directory "$HOME/.config/ghostty"
preflight_directory "$HOME/Library"
preflight_directory "$HOME/Library/Application Support"
preflight_directory "$HOME/Library/Application Support/com.mitchellh.ghostty"
preflight_common
preflight_path "$HOME/.ssh/config"
preflight_path "$HOME/.zshrc"
preflight_path "$HOME/.p10k.zsh"
preflight_path "$HOME/.tmux.conf"
preflight_path "$HOME/.config/ghostty/config"
preflight_path "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

setup_common

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
link_path "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

link_path "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_path "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
link_path "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

bash "$DOTFILES_DIR/claude/remove-bartender-hooks.sh"

mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
link_path "$DOTFILES_DIR/ghostty/config.ghostty" \
  "$HOME/.config/ghostty/config"
link_path "$DOTFILES_DIR/ghostty/config.ghostty" \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

echo "macOS dotfiles linked."
