#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT
export TEST_ROOT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export SOURCE_REPO="$TEST_ROOT/source"
mkdir -p "$TEST_ROOT/bin" "$SOURCE_REPO"
export HOME="$TEST_ROOT/home"
mkdir -p "$HOME"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# Execute the actual bootstrap through checkout preparation, before live installs.
awk '
  /log "Installing Homebrew if needed"/ { exit }
  { sub(/CLT_PLACEHOLDER="[^"]*"/, "CLT_PLACEHOLDER=\"$TEST_CASE_DIR/clt-placeholder\""); print }
' "$REPO_DIR/bootstrap_new_mac.sh" > "$TEST_ROOT/preflight.sh"
printf '%s\n' 'echo preflight-complete >> "$EVENTS"' >> "$TEST_ROOT/preflight.sh"

cat > "$SOURCE_REPO/bootstrap_new_mac.sh" <<'STUB'
#!/usr/bin/env bash
echo checkout-bootstrap >> "$EVENTS"
STUB
for file in setup.sh setup_common.sh setup_macos.sh verify.sh .zshrc .tmux.conf .p10k.zsh .gitignore_global \
  scripts/macos-apps.sh scripts/github-auth.sh scripts/install-michaels-mac-saver.sh \
  scripts/set-screen-saver-delay.sh \
  assets/MichaelsMac-AppleSilicon.zip claude/remove-bartender-hooks.sh \
  claude/settings.json claude/statusline-command.sh ssh/config ssh/github-known-hosts \
  ghostty/config.ghostty codex/AGENTS.md; do
  mkdir -p "$SOURCE_REPO/$(dirname "$file")"
  cp -p "$REPO_DIR/$file" "$SOURCE_REPO/$file"
done
git -C "$SOURCE_REPO" init -q -b main
git -C "$SOURCE_REPO" add -f .
git -C "$SOURCE_REPO" -c user.name=Test -c user.email=test@example.invalid commit -qm fixture

cat > "$TEST_ROOT/bin/mock" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "${0##*/}" in
  uname) echo Darwin ;;
  pmset) [ "$*" = '-g custom' ] && cat "$TEST_CASE_DIR/power" ;;
  defaults)
    case "$1 $2 $3 $4" in
      '-currentHost read com.apple.screensaver idleTime') cat "$TEST_CASE_DIR/delay" ;;
      '-currentHost write com.apple.screensaver idleTime')
        [ "$5" = -int ] || exit 9
        printf '%s\n' "$6" > "$TEST_CASE_DIR/delay"
        printf 'delay %s\n' "$6" >> "$EVENTS"
        ;;
      *) exit 9 ;;
    esac
    ;;
  sudo) "$@" ;;
  xcode-select)
    case "$1" in
      -p) [ -f "$TEST_CASE_DIR/selected" ] && echo /Library/Developer/CommandLineTools ;;
      --switch) touch "$TEST_CASE_DIR/selected"; echo switch >> "$EVENTS" ;;
      --install) echo gui-install >> "$EVENTS" ;;
      *) exit 1 ;;
    esac
    ;;
  softwareupdate)
    case "$1" in
      -l)
        echo list-update >> "$EVENTS"
        if [ "$UPDATE_MODE" != missing ]; then
          echo '* Label: Command Line Tools for Xcode-16.4'
        fi
        ;;
      -i)
        echo install-update >> "$EVENTS"
        [ "$UPDATE_MODE" != failed ] || exit 1
        [ "$UPDATE_MODE" = broken ] || touch "$TEST_CASE_DIR/git-ready"
        ;;
      *) exit 1 ;;
    esac
    ;;
  xcrun)
    [ "$1" = git ] || exit 1
    shift
    if [ "$1" = --version ]; then
      [ -f "$TEST_CASE_DIR/git-ready" ] || exit 1
      /usr/bin/git --version
    elif [ "$1" = clone ]; then
      [ "$2" = --branch ] && [ "$3" = main ] || exit 1
      [ "$4" = https://github.com/michaeltheitking/mac_setup.git ] || exit 1
      [ "${GIT_TERMINAL_PROMPT:-}" = 0 ] || exit 1
      echo clone >> "$EVENTS"
      /usr/bin/git clone --branch main "$SOURCE_REPO" "$5"
    else
      exit 1
    fi
    ;;
  *) exit 1 ;;
esac
MOCK
chmod +x "$TEST_ROOT/bin/mock"
for tool in uname pmset defaults sudo xcode-select softwareupdate xcrun; do
  ln -s mock "$TEST_ROOT/bin/$tool"
done

new_case() {
  export TEST_CASE_DIR="$TEST_ROOT/$1"
  export DOTFILES_DIR="$TEST_CASE_DIR/dotfiles"
  export EVENTS="$TEST_CASE_DIR/events"
  export UPDATE_MODE=ready
  mkdir -p "$TEST_CASE_DIR"
  : > "$EVENTS"
}

run_preflight() {
  PATH="$TEST_ROOT/bin:$PATH" bash "$TEST_ROOT/preflight.sh" > "$TEST_CASE_DIR/output" 2>&1
}

new_case fresh
run_preflight || fail "fresh Mac preparation failed"
grep -qx install-update "$EVENTS" || fail "missing tools were not installed"
grep -qx clone "$EVENTS" || fail "checkout was not cloned"
grep -qx checkout-bootstrap "$EVENTS" || fail "checkout bootstrap did not run"
[ ! -e "$TEST_CASE_DIR/clt-placeholder" ] || fail "install marker remains"

new_case existing
touch "$TEST_CASE_DIR/selected" "$TEST_CASE_DIR/git-ready"
git clone -q "$SOURCE_REPO" "$DOTFILES_DIR"
run_preflight || fail "existing checkout failed"
grep -qx preflight-complete "$EVENTS" || fail "existing checkout did not continue"
[ "$(wc -l < "$EVENTS" | tr -d ' ')" = 1 ] || fail "existing tools or checkout were changed"
touch "$HOME/.zshrc"
if run_preflight; then fail "existing configuration conflict passed preflight"; fi
[ ! -e "$HOME/.codex" ] || fail "checkout preflight made links"
rm "$HOME/.zshrc"
mv "$DOTFILES_DIR/assets/MichaelsMac-AppleSilicon.zip" "$TEST_CASE_DIR/asset-backup.zip"
if run_preflight; then fail "checkout with missing screen saver archive passed"; fi
grep -Fq 'Missing or empty checkout file: assets/MichaelsMac-AppleSilicon.zip' "$TEST_CASE_DIR/output" || fail "missing screen saver archive diagnosis"
mv "$TEST_CASE_DIR/asset-backup.zip" "$DOTFILES_DIR/assets/MichaelsMac-AppleSilicon.zip"
rm "$DOTFILES_DIR/scripts/github-auth.sh"
if run_preflight; then fail "incomplete checkout passed"; fi

new_case unrelated
touch "$TEST_CASE_DIR/selected" "$TEST_CASE_DIR/git-ready"
git init -q "$DOTFILES_DIR"
if run_preflight; then fail "unrelated repository passed"; fi
grep -q 'Expected the mac_setup repository root' "$TEST_CASE_DIR/output" || fail "missing checkout diagnosis"

new_case stale-selection
touch "$TEST_CASE_DIR/selected"
run_preflight || fail "broken Git with a selected developer path was not repaired"
grep -qx install-update "$EVENTS" || fail "stale selection bypassed installation"

for mode in missing failed broken; do
  new_case "$mode"
  export UPDATE_MODE="$mode"
  if run_preflight; then fail "$mode tools incorrectly passed"; fi
  [ ! -e "$TEST_CASE_DIR/clt-placeholder" ] || fail "$mode install marker remains"
  ! grep -qx clone "$EVENTS" || fail "$mode tools reached clone"
  if [ "$mode" = missing ]; then
    grep -qx gui-install "$EVENTS" || fail "no update did not reach GUI fallback"
  fi
done

new_case conflict
touch "$TEST_CASE_DIR/selected" "$TEST_CASE_DIR/git-ready"
mkdir -p "$DOTFILES_DIR"
printf '%s\n' preserve > "$DOTFILES_DIR/user-file"
if run_preflight; then fail "non-Git target incorrectly passed"; fi
grep -qx preserve "$DOTFILES_DIR/user-file" || fail "conflicting file changed"
! grep -qx clone "$EVENTS" || fail "conflicting target reached clone"

new_case broken-link
touch "$TEST_CASE_DIR/selected" "$TEST_CASE_DIR/git-ready"
ln -s "$TEST_CASE_DIR/absent" "$DOTFILES_DIR"
if run_preflight; then fail "broken target symlink incorrectly passed"; fi
[ -L "$DOTFILES_DIR" ] || fail "conflicting symlink changed"

# Run core verification, app installation and final verification together with local stand-ins.
new_case app-retry
mkdir -p "$DOTFILES_DIR/scripts" "$TEST_CASE_DIR/installed"
sed -n '/^log "Verifying terminal and GitHub setup"/,$p' "$REPO_DIR/bootstrap_new_mac.sh" > "$TEST_CASE_DIR/app-phase"
cat > "$DOTFILES_DIR/verify.sh" <<'STUB'
#!/bin/bash
echo "verify ${1:-full}" >> "$EVENTS"
STUB
chmod +x "$DOTFILES_DIR/verify.sh"
cat > "$DOTFILES_DIR/scripts/install-michaels-mac-saver.sh" <<'STUB'
echo screen-saver >> "$EVENTS"
[ -f "$TEST_CASE_DIR/screen-saver-archive-available" ]
STUB
cat > "$DOTFILES_DIR/scripts/set-screen-saver-delay.sh" <<'STUB'
echo screen-saver-timing >> "$EVENTS"
[ -f "$TEST_CASE_DIR/power-settings-available" ]
STUB
run_app_phase() (
  set -eu
  BREW_CASKS=(linear ghostty zed)
  log() { :; }
  have_cmd() { [ "$1" = mas ]; }
  mac_app_present() { [ -f "$TEST_CASE_DIR/installed/screens" ]; }
  mas() {
    [ "$*" = 'get 1663047912' ] || exit 9
    echo screens >> "$EVENTS"
    touch "$TEST_CASE_DIR/installed/screens"
  }
  osascript() {
    [ "$#" = 2 ] && [ "$1" = -e ] &&
      [ "$2" = 'tell application "System Events" to tell appearance preferences to set dark mode to true' ] || exit 9
    echo dark-mode >> "$EVENTS"
    [ -f "$TEST_CASE_DIR/automation-allowed" ]
  }
  defaults() {
    [ "$*" = 'write com.apple.finder FXPreferredViewStyle -string clmv' ] || exit 9
    echo finder-columns >> "$EVENTS"
    [ -f "$TEST_CASE_DIR/finder-write-allowed" ]
  }
  brew() {
    case "$1 $2" in
      "list --cask") [ -f "$TEST_CASE_DIR/installed/$3" ] ;;
      "install --cask")
        [ "$3" = --adopt ] || exit 9
        echo "install $4" >> "$EVENTS"
        [ "$4" != linear ] || [ -f "$TEST_CASE_DIR/retry" ] || return 1
        touch "$TEST_CASE_DIR/installed/$4"
        ;;
      *) exit 9 ;;
    esac
  }
  source "$TEST_CASE_DIR/app-phase"
)
if run_app_phase > "$TEST_CASE_DIR/output" 2>&1; then fail "failed cask reported success"; fi
grep -Fq 'App installation failed: linear' "$TEST_CASE_DIR/output" || fail "missing app failure summary"
[ "$(head -1 "$EVENTS")" = 'verify --core' ] || fail "apps ran before core verification"
grep -qx 'verify full' "$EVENTS" || fail "app failure skipped final verification"
! grep -qx dark-mode "$EVENTS" || fail "failed bootstrap changed appearance"
! grep -qx finder-columns "$EVENTS" || fail "failed bootstrap changed Finder"
! grep -qx screen-saver "$EVENTS" || fail "failed bootstrap installed the screen saver"
! grep -qx screen-saver-timing "$EVENTS" || fail "failed bootstrap changed the screen saver delay"
touch "$TEST_CASE_DIR/retry"
run_app_phase > "$TEST_CASE_DIR/output" 2>&1 || fail "desktop setup failure blocked bootstrap"
[ "$(tail -5 "$EVENTS")" = $'verify full\ndark-mode\nfinder-columns\nscreen-saver\nscreen-saver-timing' ] || fail "desktop setup did not run after final verification"
grep -Fq 'System Settings > Appearance > Dark' "$TEST_CASE_DIR/output" || fail "missing Dark Mode fallback"
grep -Fq 'View > as Columns' "$TEST_CASE_DIR/output" || fail "missing Finder fallback"
grep -Fq 'To retry the screen saver later' "$TEST_CASE_DIR/output" || fail "missing screen saver retry instructions"
grep -Fq 'Set Start Screen Saver in System Settings' "$TEST_CASE_DIR/output" || fail "missing screen saver timing fallback"
grep -Fxq 'Your Mac is bootstrapped.' "$TEST_CASE_DIR/output" || fail "missing success after desktop preference failure"
touch "$TEST_CASE_DIR/automation-allowed" "$TEST_CASE_DIR/finder-write-allowed" \
  "$TEST_CASE_DIR/screen-saver-archive-available" "$TEST_CASE_DIR/power-settings-available"
run_app_phase > "$TEST_CASE_DIR/output" 2>&1 || fail "app retry failed"
! grep -Fq 'To retry the screen saver later' "$TEST_CASE_DIR/output" || fail "successful screen saver install reported a failure"
grep -Fxq 'Dark Mode enabled.' "$TEST_CASE_DIR/output" || fail "missing Dark Mode success"
grep -Fxq 'Finder Column View saved as the default.' "$TEST_CASE_DIR/output" || fail "missing Finder success"
grep -Fxq 'Reminder: Activate Bartender with the license key from your password manager.' "$TEST_CASE_DIR/output" || fail "missing Bartender activation reminder"
grep -Fxq 'Reminder: Open Fantastical and activate it.' "$TEST_CASE_DIR/output" || fail "missing Fantastical activation reminder"
[ "$(grep -cx 'install linear' "$EVENTS")" = 2 ] || fail "failed cask was not retried"
for event in 'install ghostty' 'install zed' screens; do
  [ "$(grep -cx "$event" "$EVENTS")" = 1 ] || fail "missing or repeated install: $event"
done

new_case screen-saver-timing
run_timing() {
  PATH="$TEST_ROOT/bin:$PATH" bash "$REPO_DIR/scripts/set-screen-saver-delay.sh" > "$TEST_CASE_DIR/output" 2>&1
}
printf 'AC Power:\n displaysleep 5\n' > "$TEST_CASE_DIR/power"
run_timing || fail "could not set the usual screen saver delay"
grep -qx 120 "$TEST_CASE_DIR/delay" || fail "wrong delay for five-minute display sleep"
printf 'Battery Power:\n displaysleep 2\nAC Power:\n displaysleep 5\n' > "$TEST_CASE_DIR/power"
run_timing || fail "could not set a delay for battery power"
grep -qx 60 "$TEST_CASE_DIR/delay" || fail "delay did not account for the shorter battery timer"
run_timing || fail "could not reuse an earlier delay"
[ "$(grep -cx 'delay 60' "$EVENTS")" = 1 ] || fail "rewrote an already suitable delay"
printf 'Battery Power:\n displaysleep 1\nAC Power:\n displaysleep 0\n' > "$TEST_CASE_DIR/power"
run_timing || fail "could not set a delay before one-minute display sleep"
grep -qx 30 "$TEST_CASE_DIR/delay" || fail "disabled AC timer affected the battery delay"
printf 'AC Power:\n displaysleep 0\n' > "$TEST_CASE_DIR/power"
printf '0\n' > "$TEST_CASE_DIR/delay"
run_timing || fail "could not enable the saver when display sleep is disabled"
grep -qx 120 "$TEST_CASE_DIR/delay" || fail "wrong delay when display sleep is disabled"
: > "$TEST_CASE_DIR/power"
if run_timing; then fail "unavailable power settings passed"; fi
grep -qx 120 "$TEST_CASE_DIR/delay" || fail "unavailable power settings changed the delay"

echo "PASS: Mac bootstrap preparation, conflict handling, app retry and desktop preferences"
