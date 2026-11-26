#!/bin/bash
set -euo pipefail

archive="${1:-$(dirname "${BASH_SOURCE[0]}")/../assets/MichaelsMac-AppleSilicon.zip}"
archive_sha256=5ce703cd15c4c34e80c0705af3409f8f835bcbb55319493235ed16e451432e8c
install_dir="$HOME/Library/Screen Savers"
bundle_name=MichaelsMac.saver
installed_bundle="$install_dir/$bundle_name"

if [ "$(/usr/bin/uname -m)" != arm64 ] &&
   [ "$(/usr/sbin/sysctl -n hw.optional.arm64 2>/dev/null)" != 1 ]; then
  echo "Michael's Mac requires Apple silicon. Skipping screen saver setup."
  exit 0
fi
macos_version=$(/usr/bin/sw_vers -productVersion)
if [ "${macos_version%%.*}" -lt 13 ]; then
  echo "Michael's Mac requires macOS 13 or later. Skipping screen saver setup."
  exit 0
fi

if [ -e "$installed_bundle" ] || [ -L "$installed_bundle" ]; then
  if [ -L "$installed_bundle" ] ||
     ! /usr/bin/codesign --verify --strict -R='identifier "com.michael.screensaver.pixelterminal"' "$installed_bundle"; then
    echo "Check the existing screen saver at $installed_bundle before retrying." >&2
    exit 1
  fi
  echo "Michael's Mac screen saver is already installed."
else
  if [ ! -f "$archive" ]; then
    echo "Michael's Mac archive is missing: $archive" >&2
    exit 1
  fi

  mkdir -p "$install_dir"
  stage_dir=$(mktemp -d "$install_dir/.michaels-mac.XXXXXX")
  trap 'rm -rf "$stage_dir"' EXIT
  staged_archive="$stage_dir/MichaelsMac.zip"
  cp "$archive" "$staged_archive"
  if ! archive_hash=$(/usr/bin/shasum -a 256 < "$staged_archive") ||
     [ "${archive_hash%% *}" != "$archive_sha256" ]; then
    echo "The Michael's Mac archive did not pass its checksum." >&2
    exit 1
  fi

  /usr/bin/ditto -x -k "$staged_archive" "$stage_dir"
  /usr/bin/codesign --verify --strict -R='identifier "com.michael.screensaver.pixelterminal"' "$stage_dir/$bundle_name"
  mv -n "$stage_dir/$bundle_name" "$install_dir/"
  if [ -e "$stage_dir/$bundle_name" ]; then
    echo "A screen saver already exists at $installed_bundle. Check it before retrying." >&2
    exit 1
  fi
  echo "Michael's Mac screen saver installed."
fi

# System Events can take a few seconds to discover the bundle and apply the selection.
if /usr/bin/osascript >/dev/null <<'APPLESCRIPT'
set saverName to "Michael's Mac"
with timeout of 15 seconds
  tell application "System Events"
    repeat 20 times
      if exists (screen saver saverName) then exit repeat
      delay 0.5
    end repeat
    if not (exists (screen saver saverName)) then error "System Events did not find Michael's Mac."
    if name of current screen saver is not saverName then set current screen saver to screen saver saverName
    repeat 20 times
      if name of current screen saver is saverName then return
      delay 0.5
    end repeat
    error "System Events did not confirm the screen saver selection."
  end tell
end timeout
APPLESCRIPT
then
  echo "Michael's Mac screen saver selected."
else
  echo "To select it, search System Settings for Screen Saver and choose Michael's Mac." >&2
  exit 1
fi
