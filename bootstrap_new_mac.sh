#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  echo "bootstrap_new_mac.sh supports macOS only." >&2
  exit 1
fi

if [ "$EUID" -eq 0 ]; then
  echo "Run bootstrap as your normal user. Individual installs request sudo when needed." >&2
  exit 1
fi

GIT_NAME="michael"
GIT_EMAIL="mk@michael-king.com"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
export DOTFILES_DIR

BREW_CASKS=(
  1password
  nikitabobko/tap/aerospace
  bartender
  chatgpt
  claude
  codex
  cursor
  fantastical
  font-jetbrains-mono-nerd-font
  font-meslo-lg-nerd-font
  ghostty
  grandperspective
  istat-menus
  linear
  microsoft-edge@beta
  microsoft-office
  notion
  nvidia-geforce-now
  openlogi
  protonvpn
  raindropio
  raycast
  saffsanity/sill/sill
  spotify
  tailscale-app
  todoist-app
  vlc
  wispr-flow
  windows-app
  zed
)

BREW_FORMULAS=(
  awscli
  git
  gh
  node
  jq
  pngpaste
  ruff
  prettier
  tmux
  powerlevel10k
  zsh-autosuggestions
  fastfetch
  btop
)

CLAUDE_MARKETPLACES=(
  "EveryInc/compound-engineering-plugin"
)

CLAUDE_PLUGINS=(
  "claude-md-management@claude-plugins-official"
  "compound-engineering@compound-engineering-plugin"
  "context7@claude-plugins-official"
  "skill-creator@claude-plugins-official"
  "superpowers@claude-plugins-official"
  "atlassian@claude-plugins-official"
  "linear@claude-plugins-official"
)

log() {
  printf "\n==> %s\n" "$1"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

append_line_if_missing() {
  local line="$1"
  local file="$2"
  touch "$file"
  grep -Fqx "$line" "$file" && return
  # Keep an existing final command separate when its newline is missing.
  if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then
    printf '\n' >> "$file"
  fi
  printf "%s\n" "$line" >> "$file"
}

log "Checking Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1 || ! xcrun git --version >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools (headless)..."
  CLT_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  trap 'rm -f "$CLT_PLACEHOLDER"' EXIT
  touch "$CLT_PLACEHOLDER"
  # No matching update is a supported GUI fallback, not a pipefail exit.
  CLT_LABEL=$(softwareupdate -l 2>/dev/null \
    | grep -E "Command Line Tools" \
    | awk -F'Label: ' '/Label: /{print $2}' \
    | sort -V \
    | tail -n1) || CLT_LABEL=""
  if [ -n "$CLT_LABEL" ]; then
    sudo softwareupdate -i "$CLT_LABEL" --verbose
    sudo xcode-select --switch /Library/Developer/CommandLineTools
  else
    echo "Could not find CLT in softwareupdate; falling back to xcode-select --install."
    xcode-select --install || true
    echo "Finish the GUI install, then rerun this script."
    rm -f "$CLT_PLACEHOLDER"
    exit 1
  fi
  rm -f "$CLT_PLACEHOLDER"
  trap - EXIT
fi

if ! xcode-select -p >/dev/null 2>&1 || ! xcrun git --version >/dev/null 2>&1; then
  echo "Xcode tools do not provide working Git. Repair the developer tools, then rerun." >&2
  exit 1
fi
echo "Xcode tools and Git passed verification."

log "Preparing dotfiles checkout"
if [ ! -e "$DOTFILES_DIR/.git" ]; then
  if [ -e "$DOTFILES_DIR" ] || [ -L "$DOTFILES_DIR" ]; then
    echo "Cannot clone: $DOTFILES_DIR already exists without Git metadata. Preserve it before retrying." >&2
    exit 1
  fi
  GIT_TERMINAL_PROMPT=0 xcrun git clone --branch main \
    https://github.com/michaeltheitking/mac_setup.git "$DOTFILES_DIR"
  # Continue with the checkout's script and helpers after a standalone download.
  exec /bin/bash "$DOTFILES_DIR/bootstrap_new_mac.sh"
fi

required_files=(bootstrap_new_mac.sh setup.sh setup_macos.sh setup_common.sh verify.sh
  scripts/github-auth.sh scripts/macos-apps.sh scripts/install-michaels-mac-saver.sh
  assets/MichaelsMac-AppleSilicon.zip claude/remove-bartender-hooks.sh
  .zshrc .p10k.zsh .tmux.conf .gitignore_global ssh/config ssh/github-known-hosts
  ghostty/config.ghostty codex/AGENTS.md claude/settings.json claude/statusline-command.sh)
if [ "$(git -C "$DOTFILES_DIR" rev-parse --show-toplevel)" != "$(cd "$DOTFILES_DIR" && pwd -P)" ] ||
   ! git -C "$DOTFILES_DIR" ls-files --error-unmatch -- "${required_files[@]}" >/dev/null 2>&1; then
  echo "Expected the mac_setup repository root at $DOTFILES_DIR. Check DOTFILES_DIR before retrying." >&2
  exit 1
fi
for file in "${required_files[@]}"; do
  if [ ! -s "$DOTFILES_DIR/$file" ]; then
    echo "Missing or empty checkout file: $file. Repair the checkout before retrying." >&2
    exit 1
  fi
done
for file in setup.sh setup_macos.sh verify.sh; do
  if [ ! -x "$DOTFILES_DIR/$file" ]; then
    echo "Required script is not executable: $file" >&2
    exit 1
  fi
done
"$DOTFILES_DIR/setup_macos.sh" --preflight
source "$DOTFILES_DIR/scripts/macos-apps.sh"

log "Installing Homebrew if needed"
if ! have_cmd brew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  append_line_if_missing 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
  append_line_if_missing 'eval "$(/usr/local/bin/brew shellenv)"' "$HOME/.zprofile"
elif ! have_cmd brew; then
  echo "Homebrew installed, but brew was not found in an expected location."
  exit 1
fi

log "Updating Homebrew"
brew update

log "Installing CLI packages"
for formula in "${BREW_FORMULAS[@]}"; do
  if brew list --formula "$formula" >/dev/null 2>&1; then
    echo "Already installed: $formula"
  else
    brew install "$formula"
  fi
done

log "Installing Claude Code"
if have_cmd claude; then
  echo "Already installed: claude"
else
  npm install -g @anthropic-ai/claude-code
fi

log "Configuring Git identity"
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main

log "Preparing SSH"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

log "Running dotfiles setup"
"$DOTFILES_DIR/setup.sh"

log "Configuring GitHub HTTPS authentication"
bash "$DOTFILES_DIR/scripts/github-auth.sh" setup

log "Verifying terminal and GitHub setup"
"$DOTFILES_DIR/verify.sh" --core

log "Installing GUI apps"
failed_apps=()
for cask in "${BREW_CASKS[@]}"; do
  if brew list --cask "$cask" >/dev/null 2>&1; then
    echo "Already installed: $cask"
  elif ! brew install --cask --adopt "$cask"; then
    failed_apps+=("$cask")
  fi
done
if ! mac_app_present "Screens 5"; then
  if ! { have_cmd mas || brew install mas; } || ! mas get 1663047912; then
    echo "Sign in to the Mac App Store and retry Screens 5." >&2
    failed_apps+=("Screens 5")
  fi
fi

app_install_status=0
if [ "${#failed_apps[@]}" -gt 0 ]; then
  printf 'App installation failed: %s\n' "${failed_apps[@]}" >&2
  app_install_status=1
fi

log "Installing Claude Code plugins"
if have_cmd claude; then
  for market in "${CLAUDE_MARKETPLACES[@]}"; do
    claude plugin marketplace add "$market" 2>/dev/null \
      || echo "Marketplace already added or unavailable: $market"
  done
  for plugin in "${CLAUDE_PLUGINS[@]}"; do
    claude plugin install "$plugin" 2>/dev/null \
      || echo "Could not install plugin (may already be installed): $plugin"
  done
else
  echo "Skipping plugins: claude CLI not found."
fi

log "Reloading shell config if possible"
if [ -n "${ZSH_VERSION:-}" ]; then
  source "$HOME/.zshrc" || true
else
  echo "Open a new terminal window or run: source ~/.zshrc"
fi

log "Verifying setup"
if [ ! -x "$DOTFILES_DIR/verify.sh" ] || ! "$DOTFILES_DIR/verify.sh"; then
  echo "Verification failed or verify.sh is unavailable. Bootstrap did not complete." >&2
  exit 1
fi
if [ "$app_install_status" != 0 ]; then
  echo "Retry bootstrap to finish failed app installations." >&2
  exit 1
fi

log "Enabling macOS Dark Mode"
if osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' >/dev/null; then
  echo "Dark Mode enabled."
else
  echo "Could not enable Dark Mode. Choose System Settings > Appearance > Dark." >&2
fi

log "Setting Finder to Column View"
if defaults write com.apple.finder FXPreferredViewStyle -string clmv; then
  echo "Finder Column View saved as the default."
else
  echo "Could not save the Finder default. In Finder, choose View > as Columns." >&2
fi

log "Installing the Michael's Mac screen saver"
if ! bash "$DOTFILES_DIR/scripts/install-michaels-mac-saver.sh"; then
  echo "To retry the screen saver later, run: bash \"$DOTFILES_DIR/scripts/install-michaels-mac-saver.sh\"" >&2
fi

log "Finished"
echo
echo "Your Mac is bootstrapped."
echo "Reminder: restore iStat Menus settings from the exported file in your Documents folder."
echo "A copy without license or device fields is available at: $DOTFILES_DIR/istat-menus/settings.ismp7"
echo "Import it through iStat Menus; activate the app separately if required."
echo "Reminder: Activate Bartender with the license key from your password manager."
echo "Restore other app settings with: $DOTFILES_DIR/docs/manual-settings.md"
echo "Repo remote is now:"
git -C "$DOTFILES_DIR" remote -v || true
