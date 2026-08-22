#!/usr/bin/env bash
set -euo pipefail

GITHUB_USERNAME="michaeltheitking"
GIT_NAME="michael"
GIT_EMAIL="mk@michael-king.com"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_github"

# Omarchy already provides Git, jq, Tmux, Fastfetch, wl-clipboard, and the
# Claude/Codex lazy launchers. Add only personal tools missing from its base.
OMARCHY_PACKAGES=(
  github-cli
  ruff
  prettier
)

CLAUDE_MARKETPLACES=(
  "compound-engineering-plugin|EveryInc/compound-engineering-plugin"
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

claude_marketplace_installed() {
  local marketplace_name="$1"

  claude plugin marketplace list --json \
    | jq -e --arg name "$marketplace_name" \
      'any(.[]; .name == $name)' >/dev/null
}

claude_plugin_installed() {
  local plugin_id="$1"

  claude plugin list --json \
    | jq -e --arg id "$plugin_id" \
      'any(.[]; .id == $id)' >/dev/null
}

github_has_ssh_key() {
  local public_key

  public_key="$(awk '{ print $1 " " $2 }' "${SSH_KEY_PATH}.pub")"
  gh api user/keys --paginate --jq '.[].key' | grep -Fxq "$public_key"
}

main() {
if [ "$(uname -s)" != "Linux" ] \
  || ! command -v omarchy >/dev/null 2>&1 \
  || ! command -v pacman >/dev/null 2>&1; then
  echo "bootstrap_omarchy.sh supports Omarchy Linux only." >&2
  exit 1
fi

log "Running Omarchy dotfiles setup"
DOTFILES_PLATFORM=omarchy "$DOTFILES_DIR/setup.sh"

log "Installing personal command-line packages"
for package in "${OMARCHY_PACKAGES[@]}"; do
  if pacman -Q "$package" >/dev/null 2>&1; then
    echo "Already installed: $package"
  else
    omarchy pkg add "$package"
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
  echo "GitHub SSH key already exists."
fi

log "Starting ssh-agent"
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_PATH"

log "Authenticating GitHub CLI"
if ! gh auth status >/dev/null 2>&1; then
  gh auth login --hostname github.com --git-protocol ssh --web
fi

log "Adding SSH key to GitHub if needed"
KEY_TITLE="$(hostname)-$(date +%Y)"
if github_has_ssh_key; then
  echo "SSH key already registered with GitHub."
else
  gh ssh-key add "${SSH_KEY_PATH}.pub" --title "$KEY_TITLE"
fi

log "Testing GitHub SSH"
ssh -T git@github.com || true

log "Switching dotfiles repo remote to SSH"
if [ -d "$DOTFILES_DIR/.git" ]; then
  git -C "$DOTFILES_DIR" remote set-url origin \
    "git@github.com:${GITHUB_USERNAME}/mac_setup.git" || true
fi

log "Installing Claude Code plugins"
if command -v claude >/dev/null 2>&1; then
  for marketplace in "${CLAUDE_MARKETPLACES[@]}"; do
    marketplace_name="${marketplace%%|*}"
    marketplace_source="${marketplace#*|}"
    if claude_marketplace_installed "$marketplace_name"; then
      echo "Marketplace already installed: $marketplace_name"
      continue
    fi

    claude plugin marketplace add "$marketplace_source"
    if ! claude_marketplace_installed "$marketplace_name"; then
      echo "Marketplace installation did not register: $marketplace_name" >&2
      exit 1
    fi
  done
  for plugin in "${CLAUDE_PLUGINS[@]}"; do
    if claude_plugin_installed "$plugin"; then
      echo "Plugin already installed: $plugin"
      continue
    fi

    claude plugin install "$plugin"
    if ! claude_plugin_installed "$plugin"; then
      echo "Plugin installation did not register: $plugin" >&2
      exit 1
    fi
  done
else
  echo "Skipping plugins. Run claude once to install its Omarchy launcher."
fi

log "Verifying setup"
if ! DOTFILES_PLATFORM=omarchy "$DOTFILES_DIR/verify.sh"; then
  echo "Verification failed. Bootstrap did not complete." >&2
  exit 1
fi

log "Finished"
echo
echo "Your Omarchy system is bootstrapped."
echo "Omarchy still manages Bash, Tmux, Ghostty, Hyprland, and desktop settings."
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
