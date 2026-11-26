#!/bin/bash
set -euo pipefail

if ! sleep_minutes=$(pmset -g custom | awk '
  $1 == "displaysleep" && $2 ~ /^[0-9]+$/ {
    found = 1
    if ($2 > 0 && (!minimum || $2 < minimum)) minimum = $2 + 0
  }
  END { if (!found) exit 1; print minimum + 0 }
'); then
  echo "Could not read the display sleep timers." >&2
  exit 1
fi

sleep_seconds=$((sleep_minutes * 60))
current_delay=$(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null) || current_delay=0
if [[ "$current_delay" =~ ^[0-9]+$ ]] && [ "$current_delay" -gt 0 ] &&
   { [ "$sleep_seconds" -eq 0 ] || [ "$current_delay" -lt "$sleep_seconds" ]; }; then
  echo "Screen saver delay is already suitable ($current_delay seconds)."
  exit 0
fi

delay=120
if [ "$sleep_seconds" -gt 0 ] && [ "$sleep_seconds" -le "$delay" ]; then
  delay=$((sleep_seconds / 2))
fi

defaults -currentHost write com.apple.screensaver idleTime -int "$delay"
if [ "$(defaults -currentHost read com.apple.screensaver idleTime)" != "$delay" ]; then
  echo "macOS did not confirm the screen saver delay." >&2
  exit 1
fi
echo "Screen saver delay set to $delay seconds."
