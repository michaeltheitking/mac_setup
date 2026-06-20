#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.codex"
mkdir -p "$HOME/.claude"

ln -sf "$HOME/dotfiles/.zshrc" "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/.gitignore_global" "$HOME/.gitignore_global"
ln -sf "$HOME/dotfiles/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
ln -sf "$HOME/dotfiles/claude/settings.json" "$HOME/.claude/settings.json"
ln -sf "$HOME/dotfiles/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
# Share one set of global agent instructions between Codex and Claude Code.
ln -sf "$HOME/dotfiles/codex/AGENTS.md" "$HOME/.claude/CLAUDE.md"
# Per-machine Claude settings (Bartender hooks + permissions); not symlinked.
"$HOME/dotfiles/claude/install-local-hooks.sh"
git config --global core.excludesfile "$HOME/.gitignore_global"

if [ -f "$HOME/dotfiles/.p10k.zsh" ]; then
  ln -sf "$HOME/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
fi

ln -sf "$HOME/dotfiles/ghostty/config.ghostty" "$HOME/.config/ghostty/config"
ln -sf "$HOME/dotfiles/ghostty/config.ghostty" \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

echo "Dotfiles linked."
