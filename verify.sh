#!/usr/bin/env bash
# verify.sh — read-only health check for this dotfiles setup.
#
# Safe to run anytime: it makes NO changes, only inspects. Run it after
# bootstrap, periodically, or whenever something feels off. Exits non-zero if
# any hard check (FAIL) fails; WARN items are advisory.
#
#   ./verify.sh
#
# Catches the failure modes we've actually hit: clobbered/empty symlinks
# (apps replacing them), missing tools the config depends on, and
# machine-specific content leaking into the committed Claude settings.

set -uo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
fails=0
warns=0

tag_ok()   { printf "  \033[32mOK\033[0m    %s\n" "$1"; }
tag_warn() { printf "  \033[33mWARN\033[0m  %s\n" "$1"; warns=$((warns+1)); }
tag_fail() { printf "  \033[31mFAIL\033[0m  %s\n" "$1"; fails=$((fails+1)); }
section()  { printf "\n== %s ==\n" "$1"; }

short() { printf '%s' "${1/#$HOME/~}"; }

check_symlink() { # <link> <expected_target> [optional]
  local link="$1" want="$2" optional="${3:-}"
  if [ -L "$link" ]; then
    local got; got="$(readlink "$link")"
    if [ "$got" = "$want" ]; then
      if [ -s "$link" ]; then tag_ok "$(short "$link")"
      else tag_fail "$(short "$link") is a symlink but resolves to an EMPTY file"; fi
    else
      tag_fail "$(short "$link") -> $(short "$got") (expected $(short "$want"))"
    fi
  elif [ -e "$link" ]; then
    tag_fail "$(short "$link") is a regular file, not a symlink (app may have clobbered it — re-run setup.sh)"
  else
    if [ "$optional" = "optional" ]; then tag_warn "$(short "$link") missing (optional)"
    else tag_fail "$(short "$link") missing"; fi
  fi
}

check_cmd() { # <binary> <why>
  if command -v "$1" >/dev/null 2>&1; then tag_ok "$1 ($2)"
  else tag_fail "$1 not found — needed for: $2"; fi
}

section "Managed symlinks"
check_symlink "$HOME/.zshrc"                       "$DOTFILES_DIR/.zshrc"
check_symlink "$HOME/.gitignore_global"            "$DOTFILES_DIR/.gitignore_global"
check_symlink "$HOME/.p10k.zsh"                    "$DOTFILES_DIR/.p10k.zsh" optional
check_symlink "$HOME/.codex/AGENTS.md"             "$DOTFILES_DIR/codex/AGENTS.md"
check_symlink "$HOME/.claude/CLAUDE.md"            "$DOTFILES_DIR/codex/AGENTS.md"
check_symlink "$HOME/.claude/settings.json"        "$DOTFILES_DIR/claude/settings.json"
check_symlink "$HOME/.claude/statusline-command.sh" "$DOTFILES_DIR/claude/statusline-command.sh"
check_symlink "$HOME/.config/ghostty/config"       "$DOTFILES_DIR/ghostty/config.ghostty"
check_symlink "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" "$DOTFILES_DIR/ghostty/config.ghostty"

section "Managed skills"
skills_found=0
for skill in "$DOTFILES_DIR"/claude/skills/*/; do
  [ -d "$skill" ] || continue
  skills_found=1
  name="$(basename "$skill")"
  check_symlink "$HOME/.claude/skills/$name" "$DOTFILES_DIR/claude/skills/$name"
done
for skill in "$DOTFILES_DIR"/codex/skills/*/; do
  [ -d "$skill" ] || continue
  skills_found=1
  name="$(basename "$skill")"
  check_symlink "$HOME/.codex/skills/$name" "$DOTFILES_DIR/codex/skills/$name"
done
[ "$skills_found" = 1 ] || tag_warn "no skills found under $(short "$DOTFILES_DIR")/{claude,codex}/skills"

section "Required tools"
check_cmd git   "version control"
check_cmd gh    "GitHub auth / SSH key registration"
check_cmd node  "npm-based Claude Code install"
check_cmd jq    "Claude Code status line command"
check_cmd claude "Claude Code"
check_cmd brew  "Homebrew package management"

section "Claude settings hygiene"
SETTINGS="$DOTFILES_DIR/claude/settings.json"
if [ -f "$SETTINGS" ]; then
  if command -v jq >/dev/null 2>&1 && jq empty "$SETTINGS" >/dev/null 2>&1; then
    tag_ok "claude/settings.json is valid JSON"
  else
    tag_fail "claude/settings.json is not valid JSON"
  fi
  # The committed (shared) settings.json must stay portable: no app-injected
  # hooks and no machine-specific absolute paths.
  if grep -q '"hooks"' "$SETTINGS"; then
    tag_warn "committed settings.json contains a \"hooks\" block — likely app-injected (Bartender/claudio); move it to ~/.claude/settings.local.json"
  else
    tag_ok "no machine-specific hooks leaked into committed settings.json"
  fi
  if grep -q '/Users/' "$SETTINGS"; then
    tag_warn "committed settings.json contains an absolute /Users/ path — not portable across machines"
  else
    tag_ok "no absolute /Users/ paths in committed settings.json"
  fi
else
  tag_fail "claude/settings.json not found at $(short "$SETTINGS")"
fi

if [ -f "$HOME/.claude/settings.local.json" ]; then
  tag_ok "~/.claude/settings.local.json present (per-machine hooks/permissions)"
else
  tag_warn "~/.claude/settings.local.json missing — run claude/install-local-hooks.sh (Bartender hooks/permissions won't load)"
fi

section "Intentionally unmanaged"
if [ -L "$HOME/.codex/config.toml" ]; then
  tag_warn "~/.codex/config.toml is a symlink — it should be a plain per-machine file (Codex rewrites it); remove the link"
else
  tag_ok "~/.codex/config.toml is unmanaged (correct)"
fi

section "Result"
if [ "$fails" -gt 0 ]; then
  printf "\033[31m%d FAIL\033[0m, %d WARN\n" "$fails" "$warns"
  exit 1
elif [ "$warns" -gt 0 ]; then
  printf "0 FAIL, \033[33m%d WARN\033[0m\n" "$warns"
  exit 0
else
  printf "\033[32mAll checks passed.\033[0m\n"
  exit 0
fi
