# -----------------------------------------------------------------------------
# Powerlevel10k Instant Prompt
# -----------------------------------------------------------------------------
# Keep this near the top of ~/.zshrc. Any initialization that requires console
# input should go above this block; regular shell setup can go below it.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -----------------------------------------------------------------------------
# Prompt And Shell Decorations
# -----------------------------------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  [[ -f "$BREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme" ]] && source "$BREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [[ -n "${BREW_PREFIX:-}" && -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Fastfetch system summary. Run once when the line editor is ready, after
# Powerlevel10k startup has finished.
if [[ -o interactive && "$TERM_PROGRAM" != "vscode" ]] && command -v fastfetch >/dev/null 2>&1; then
  _run_fastfetch_zle_once() {
    zle -I
    print -r -- >/dev/tty
    fastfetch --pipe false --logo-print-remaining true >/dev/tty 2>&1
    print -r -- >/dev/tty
    print -r -- >/dev/tty
    zle reset-prompt
    zle -D zle-line-init
  }
  zle -N zle-line-init _run_fastfetch_zle_once
fi

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
alias claudeauto="claude --permission-mode auto"
alias brewall='brew update && brew upgrade && brew cleanup'

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
awssync() {
  aws s3 sync . s3://michael-king.com --delete \
    --exclude ".*" \
    --exclude ".*/**" \
    --exclude "README.md" \
    --exclude "package.json" \
    --exclude "package-lock.json" \
    --exclude "yarn.lock" \
    --exclude "pnpm-lock.yaml" \
    --exclude "node_modules" \
    --exclude "node_modules/*" \
    --exclude "node_modules/**" \
    --exclude "tests" \
    --exclude "tests/*" \
    --exclude "tests/**" \
    --exclude "test" \
    --exclude "test/*" \
    --exclude "test/**" \
    --exclude "*.map" \
    --exclude "docs" \
    --exclude "docs/*" \
    --exclude "docs/**" \
    --exclude "AGENTS.md" \
  && aws cloudfront create-invalidation --distribution-id E2LXTUFU951CL5 --paths "/*" > /dev/null \
  && echo "CloudFront cache invalidated."
}

dbox() {
  cd ~/Dropbox/website
}

# -----------------------------------------------------------------------------
# Private Local Overrides
# -----------------------------------------------------------------------------
[[ -f ~/.zshrc.private ]] && source ~/.zshrc.private
