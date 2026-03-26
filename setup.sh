#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$HOME/.config/ghostty"

ln -sf "$HOME/dotfiles/.zshrc" "$HOME/.zshrc"

if [ -f "$HOME/dotfiles/.p10k.zsh" ]; then
  ln -sf "$HOME/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
fi

ln -sf "$HOME/dotfiles/ghostty/config.ghostty" "$HOME/.config/ghostty/config"
ln -sf "$HOME/dotfiles/ghostty/config.ghostty" \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

echo "Dotfiles linked."
