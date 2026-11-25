#!/bin/zsh -f
set -eu
repo=${0:A:h:h}
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
export HOME="$fixture" TMPDIR="$fixture" PATH="/usr/bin:/bin"
source "$repo/.zshrc" || true

fail() { print -u2 -- "$1"; exit 1; }
aws() { print -r -- "$*" >> "$fixture/aws-log"; }
mkdir "$fixture/site"
cd "$fixture/site"
git init -q
print index > index.html
print projects > projects.html
git remote add origin https://github.com/example/other.git
if awssync; then fail "unrelated checkout reached AWS"; fi
git remote set-url origin git@github.com:michaeltheitking/website.git
mkdir subdir
cd subdir
if awssync; then fail "subdirectory reached AWS"; fi
[[ ! -e "$fixture/aws-log" ]] || fail "invalid source made AWS calls"
cd ..
awssync
grep -Fq "s3 sync ${PWD:A}/ s3://michael-king.com --delete" "$fixture/aws-log"
grep -q '^cloudfront create-invalidation' "$fixture/aws-log"

pngpaste() { print image > "$1"; }
ssh() { [[ "$1" = devbox && "$failure" != ssh ]]; }
scp() { [[ -f "$1" && "$2" = devbox:/tmp/claude-images/* && "$failure" != scp ]]; }
pbcopy() { cat > "$fixture/clipboard"; }
for failure in ssh scp; do
  if clip; then fail "transfer reported success after $failure failed"; fi
  [[ ! -e "$fixture/clipboard" ]] || fail "failed transfer changed the clipboard"
done
failure=none
clip
grep -Eq '^/tmp/claude-images/clip-.+\.png$' "$fixture/clipboard"
print 'PASS: website deployment guard and clipboard transfer'
