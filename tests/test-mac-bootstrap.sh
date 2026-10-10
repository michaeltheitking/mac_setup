#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT
export TEST_ROOT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export SOURCE_REPO="$TEST_ROOT/source"
mkdir -p "$TEST_ROOT/bin" "$SOURCE_REPO"

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
git -C "$SOURCE_REPO" init -q -b main
git -C "$SOURCE_REPO" add bootstrap_new_mac.sh
git -C "$SOURCE_REPO" -c user.name=Test -c user.email=test@example.invalid commit -qm fixture

cat > "$TEST_ROOT/bin/mock" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "${0##*/}" in
  uname) echo Darwin ;;
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
for tool in uname sudo xcode-select softwareupdate xcrun; do
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

echo "PASS: Mac bootstrap preparation, tool checks, fallback, and target preservation"
