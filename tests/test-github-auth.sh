#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUTH="$REPO_DIR/scripts/github-auth.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
export HOME="$TEST_DIR/home" GH_CONFIG_DIR="$TEST_DIR/gh"
unset GH_TOKEN GITHUB_TOKEN GH_ENTERPRISE_TOKEN GITHUB_ENTERPRISE_TOKEN
mkdir -p "$HOME" "$GH_CONFIG_DIR" "$TEST_DIR/bin"
export REAL_GIT="$(command -v git)" AUTH_TEST_LOG="$TEST_DIR/calls"
export AUTH_TEST_STATE=success AUTH_TEST_SOURCE=keyring AUTH_TEST_LOGIN=michaeltheitking
export AUTH_TEST_WHOAMI=michaeltheitking AUTH_TEST_GIT_FAIL=0 AUTH_TEST_API_FAIL=0
export AUTH_TEST_PROTOCOL=https AUTH_TEST_PRIVATE=1
export AUTH_TEST_EMPTY=0 AUTH_TEST_EMPTY_REPO="$TEST_DIR/empty.git"
"$REAL_GIT" init --bare --quiet "$AUTH_TEST_EMPTY_REPO"

cat > "$TEST_DIR/bin/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$AUTH_TEST_LOG"
case "$1 $2" in
  'auth status')
    if [ -f "$GH_CONFIG_DIR/logged-in" ]; then
      AUTH_TEST_STATE=success
    fi
    if [ "$AUTH_TEST_STATE" = missing ]; then printf '{}\n'; exit 0; fi
    printf '{"state":"%s","login":"%s","tokenSource":"%s","error":"%s"}\n' \
      "$AUTH_TEST_STATE" "$AUTH_TEST_LOGIN" "$AUTH_TEST_SOURCE" "${AUTH_TEST_ERROR:-}"
    ;;
  'auth login')
    [[ "$*" == *'--git-protocol https --web'* ]] || exit 9
    touch "$GH_CONFIG_DIR/logged-in"
    ;;
  'auth setup-git')
    "$REAL_GIT" config --global credential.https://github.com.helper '!gh auth git-credential'
    ;;
  'config set') printf '%s\n' "$4" > "$GH_CONFIG_DIR/protocol" ;;
  'config get')
    if [ -f "$GH_CONFIG_DIR/protocol" ]; then cat "$GH_CONFIG_DIR/protocol"
    else printf '%s\n' "$AUTH_TEST_PROTOCOL"; fi
    ;;
  'api --hostname')
    [ "$AUTH_TEST_API_FAIL" = 0 ] || exit 1
    if [[ "$*" == *'user/repos?'* ]]; then
      [ "$AUTH_TEST_PRIVATE" = 1 ] && printf 'https://github.com/test/private.git\n'
      exit 0
    fi
    printf '%s\n' "$AUTH_TEST_WHOAMI"
    ;;
  *) exit 8 ;;
esac
STUB
cat > "$TEST_DIR/bin/git" <<'STUB'
#!/usr/bin/env bash
if [[ "$*" == *'ls-remote'* ]]; then
  if [[ "$*" == *'--get-url'* ]]; then exec "$REAL_GIT" "$@"; fi
  printf 'private Git probe\n' >> "$AUTH_TEST_LOG"
  if [ "$AUTH_TEST_EMPTY" = 1 ]; then
    args=()
    for arg in "$@"; do
      if [ "$arg" = https://github.com/test/private.git ]; then args+=("$AUTH_TEST_EMPTY_REPO")
      else args+=("$arg"); fi
    done
    exec "$REAL_GIT" "${args[@]}"
  fi
  exit "$AUTH_TEST_GIT_FAIL"
fi
exec "$REAL_GIT" "$@"
STUB
chmod +x "$TEST_DIR/bin/gh" "$TEST_DIR/bin/git"
export PATH="$TEST_DIR/bin:$PATH"
log="$TEST_DIR/output"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
expect_failure() {
  local expected="$1"
  shift
  if /bin/bash "$AUTH" "$@" > "$log" 2>&1; then fail "accepted $expected"; fi
  grep -Fq "$expected" "$log" || { cat "$log" >&2; fail "missing diagnosis: $expected"; }
}

/bin/bash "$AUTH" setup > "$log" 2>&1 || { cat "$log" >&2; fail 'HTTPS setup failed'; }
/bin/bash "$AUTH" setup > "$log" 2>&1 || fail 'repeated setup failed'
if grep -Fq 'auth login' "$AUTH_TEST_LOG"; then fail 'valid credentials triggered login'; fi
grep -Fq 'private Git probe' "$AUTH_TEST_LOG" || fail 'setup skipped authenticated Git access'
if [ -e "$HOME/.ssh/id_ed25519" ]; then fail 'HTTPS setup created an SSH key'; fi
if grep -Eq 'ssh-key|ssh-agent|auth token|--show-token' "$AUTH_TEST_LOG"; then fail 'setup used SSH or exposed credentials'; fi

# Preserve real Git's successful empty-ref behavior and URL rewrite resolution.
export AUTH_TEST_EMPTY=1
/bin/bash "$AUTH" check > "$log" 2>&1 || fail 'readable empty private repository failed authentication'
export AUTH_TEST_EMPTY=0
"$REAL_GIT" config --global url.git@github.com:.insteadOf https://github.com/
expect_failure 'URL rewrite' check
"$REAL_GIT" config --global --unset-all url.git@github.com:.insteadOf
"$REAL_GIT" config --global url.https://github.com/test/public.git.insteadOf https://github.com/test/private.git
expect_failure 'URL rewrite' check
"$REAL_GIT" config --global --unset-all url.https://github.com/test/public.git.insteadOf

export AUTH_TEST_STATE=error AUTH_TEST_ERROR='HTTP 401: Bad credentials'
expect_failure 'authentication is invalid' check
export AUTH_TEST_ERROR='non-200 OK status code: 401 Unauthorized'
expect_failure 'authentication is invalid' check
expect_failure 'browser authorization' setup
export AUTH_TEST_STATE=timeout AUTH_TEST_ERROR='network timeout'
expect_failure 'network' setup
if grep -Fq 'auth login' "$AUTH_TEST_LOG"; then fail 'network failure triggered login'; fi
export AUTH_TEST_STATE=success AUTH_TEST_ERROR=''
export AUTH_TEST_WHOAMI=other-user
expect_failure 'Expected GitHub account' setup
export AUTH_TEST_WHOAMI=michaeltheitking
export AUTH_TEST_GIT_FAIL=1
expect_failure 'private repository' check
export AUTH_TEST_GIT_FAIL=0
export AUTH_TEST_SOURCE="$GH_CONFIG_DIR/hosts.yml"
expect_failure 'plaintext' setup
set +e
/bin/bash "$AUTH" check > "$log" 2>&1
status=$?
set -e
[ "$status" = 2 ] || fail 'legacy plaintext storage must produce an advisory result'
grep -Fq 'plaintext' "$log" || fail 'plaintext storage was not reported'
export AUTH_TEST_SOURCE=keyring AUTH_TEST_STATE=missing
expect_failure 'browser authorization' setup

# A real pseudo-terminal exercises first login without contacting GitHub.
if [ "$(uname -s)" = Darwin ]; then
  script -q "$TEST_DIR/tty-log" /bin/bash "$AUTH" setup > "$log" 2>&1
else
  export AUTH
  script -q -e -c '/bin/bash "$AUTH" setup' "$TEST_DIR/tty-log" > "$log" 2>&1
fi
[ -f "$GH_CONFIG_DIR/logged-in" ] || fail 'first setup did not authorize through the browser'
grep -Fq 'auth login --hostname github.com --git-protocol https --web' "$AUTH_TEST_LOG" \
  || fail 'first login did not request HTTPS'

# Rejected credentials must enter the same real-terminal recovery path.
rm "$GH_CONFIG_DIR/logged-in"
export AUTH_TEST_STATE=error AUTH_TEST_ERROR='non-200 OK status code: 401 Unauthorized'
if [ "$(uname -s)" = Darwin ]; then
  script -q "$TEST_DIR/tty-log" /bin/bash "$AUTH" setup > "$log" 2>&1
else
  script -q -e -c '/bin/bash "$AUTH" setup' "$TEST_DIR/tty-log" > "$log" 2>&1
fi
[ -f "$GH_CONFIG_DIR/logged-in" ] || fail 'rejected credentials did not start browser recovery'

echo 'GitHub HTTPS authentication tests passed.'
