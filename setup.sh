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

# Global agent skills, shared across machines. Linked per-skill (driven by what's
# in the repo) so Codex's managed ~/.codex/skills/.system stays untouched.
mkdir -p "$HOME/.claude/skills" "$HOME/.codex/skills"
for skill in "$HOME"/dotfiles/claude/skills/*/; do
  [ -d "$skill" ] || continue
  ln -sfn "${skill%/}" "$HOME/.claude/skills/$(basename "$skill")"
done
for skill in "$HOME"/dotfiles/codex/skills/*/; do
  [ -d "$skill" ] || continue
  ln -sfn "${skill%/}" "$HOME/.codex/skills/$(basename "$skill")"
done

# Per-machine Claude settings (Bartender hooks + permissions); not symlinked.
"$HOME/dotfiles/claude/install-local-hooks.sh"
git config --global core.excludesfile "$HOME/.gitignore_global"

ln -sf "$HOME/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"

ln -sf "$HOME/dotfiles/ghostty/config.ghostty" "$HOME/.config/ghostty/config"
ln -sf "$HOME/dotfiles/ghostty/config.ghostty" \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

echo "Dotfiles linked."
