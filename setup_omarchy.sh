#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
# shellcheck source=setup_common.sh
source "$DOTFILES_DIR/setup_common.sh"

require_platform omarchy

preflight_directory "$HOME/.ssh"
preflight_common
preflight_path "$HOME/.ssh/config"

setup_common

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
link_path "$DOTFILES_DIR/ssh/config.omarchy" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

echo "Omarchy dotfiles linked."
echo "Omarchy retains control of Bash, Tmux, Ghostty, and desktop settings."
