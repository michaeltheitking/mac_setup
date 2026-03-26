#!/usr/bin/env bash
set -euo pipefail

GITHUB_USERNAME="michaeltheitking"
GIT_NAME="michael"
GIT_EMAIL="mk@michael-king.com"
DOTFILES_DIR="$HOME/dotfiles"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_github"
SSH_CONFIG_PATH="$HOME/.ssh/config"

BREW_CASKS=(
  1password
  chatgpt
  claude
  codex
  cursor
  dropbox
  fantastical
  firefox
  ghostty
  grandperspective
  istat-menus
  notion
  nvidia-geforce-now
  protonvpn
  raindropio
  raycast
  spotify
  todoist-app
  vlc
  wispr-flow
  zoom
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
  grep -Fqx "$line" "$file" || printf "%s\n" "$line" >> "$file"
}

log "Checking Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are not installed."
  echo "Running: xcode-select --install"
  xcode-select --install || true
  echo
  echo "Finish that install, then rerun this script."
  exit 1
fi

log "Installing Homebrew if needed"
if ! have_cmd brew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    append_line_if_missing 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zprofile"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    append_line_if_missing 'eval "$(/usr/local/bin/brew shellenv)"' "$HOME/.zprofile"
  else
    echo "Homebrew installed, but brew was not found in an expected location."
    exit 1
  fi
else
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

log "Updating Homebrew"
brew update

log "Installing core CLI packages"
brew install git gh

log "Installing GUI apps"
for cask in "${BREW_CASKS[@]}"; do
  if brew list --cask "$cask" >/dev/null 2>&1; then
    echo "Already installed: $cask"
  else
    brew install --cask "$cask"
  fi
done

log "Configuring Git identity"
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main

log "Preparing SSH"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$SSH_KEY_PATH" ]; then
  log "Generating GitHub SSH key"
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH"
else
  log "GitHub SSH key already exists"
fi

log "Starting ssh-agent"
eval "$(ssh-agent -s)"

touch "$SSH_CONFIG_PATH"
chmod 600 "$SSH_CONFIG_PATH"

if ! grep -q "Host github.com" "$SSH_CONFIG_PATH"; then
  cat >> "$SSH_CONFIG_PATH" <<EOF

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $SSH_KEY_PATH
EOF
fi

log "Adding SSH key to agent and Keychain"
ssh-add --apple-use-keychain "$SSH_KEY_PATH"

log "Authenticating GitHub CLI"
if ! gh auth status >/dev/null 2>&1; then
  gh auth login --hostname github.com --git-protocol ssh --web
fi

log "Adding SSH key to GitHub if needed"
KEY_TITLE="$(scutil --get ComputerName 2>/dev/null || hostname)-$(date +%Y)"

PUBKEY_CONTENT="$(cat "${SSH_KEY_PATH}.pub")"
if gh ssh-key list | grep -Fq "$PUBKEY_CONTENT"; then
  echo "SSH key already registered with GitHub."
else
  gh ssh-key add "${SSH_KEY_PATH}.pub" --title "$KEY_TITLE"
fi

log "Testing GitHub SSH"
ssh -T git@github.com || true

log "Switching dotfiles repo remote to SSH"
if [ -d "$DOTFILES_DIR/.git" ]; then
  cd "$DOTFILES_DIR"
  git remote set-url origin "git@github.com:${GITHUB_USERNAME}/mac_setup.git" || true
fi

log "Running dotfiles setup"
if [ -x "$DOTFILES_DIR/setup.sh" ]; then
  "$DOTFILES_DIR/setup.sh"
else
  chmod +x "$DOTFILES_DIR/setup.sh"
  "$DOTFILES_DIR/setup.sh"
fi

log "Reloading shell config if possible"
if [ -n "${ZSH_VERSION:-}" ]; then
  source "$HOME/.zshrc" || true
else
  echo "Open a new terminal window or run: source ~/.zshrc"
fi

log "Finished"
echo
echo "Your Mac is bootstrapped."
echo "Repo remote is now:"
git -C "$DOTFILES_DIR" remote -v || true
