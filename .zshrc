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
# Terminal Title
# -----------------------------------------------------------------------------
# Show which box I'm on in the terminal/tab title: hostname when on a remote
# SSH session, otherwise the current directory name. Registered via add-zsh-hook
# so it coexists with Powerlevel10k's own precmd hooks.
autoload -Uz add-zsh-hook
_set_terminal_title() {
  if [[ -n "$SSH_CONNECTION" ]]; then
    print -Pn "\e]0;SSH: %m\a"
  else
    print -Pn "\e]0;%1~\a"
  fi
}
add-zsh-hook precmd _set_terminal_title

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
alias claudeauto="claude --permission-mode auto"
alias brewall='brew update && brew upgrade && brew cleanup'
alias devbox='ssh -t devbox /opt/homebrew/bin/tmux new -As main'
alias devclaude='ssh -t devbox /opt/homebrew/bin/tmux new -As claude'

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
awssync() {
  local root origin
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  origin=$(git config --local --get remote.origin.url) || return 1
  case "${origin%.git}" in
    https://github.com/michaeltheitking/website|git@github.com:michaeltheitking/website|ssh://git@github.com/michaeltheitking/website) ;;
    *) print -u2 "Run awssync from the personal website checkout."; return 1 ;;
  esac
  if [[ "${root:A}" != "${PWD:A}" || ! -s "$root/index.html" || ! -s "$root/projects.html" ]]; then
    print -u2 "Run awssync from the complete website root."
    return 1
  fi
  aws s3 sync "$root/" s3://michael-king.com --delete \
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
    --exclude "CLAUDE.md" \
    --exclude "print-contact.json" \
    --exclude "staging/*" \
  && aws cloudfront create-invalidation --distribution-id E2LXTUFU951CL5 --paths "/*" > /dev/null \
  && echo "CloudFront cache invalidated."
}

dbox() {
  cd ~/Dropbox/website
}

clip() (
  local remote="devbox"
  local dir="/tmp/claude-images"
  local temp_dir file local_file
  temp_dir=$(mktemp -d) || return 1
  trap 'rm -rf -- "$temp_dir"' EXIT
  file="clip-${temp_dir:t}.png"
  local_file="$temp_dir/$file"

  pngpaste "$local_file" || {
    echo "No image found in local clipboard"
    return 1
  }

  ssh "$remote" "mkdir -p $dir" || return 1
  scp "$local_file" "$remote:$dir/$file" >/dev/null || return 1

  local remote_path="$dir/$file"
  printf "%s" "$remote_path" | pbcopy || return 1
  echo "Copied remote image path: $remote_path"
)

# -----------------------------------------------------------------------------
# Private Local Overrides
# -----------------------------------------------------------------------------
[[ -f ~/.zshrc.private ]] && source ~/.zshrc.private
