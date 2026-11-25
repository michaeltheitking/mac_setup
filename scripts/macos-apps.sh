#!/usr/bin/env bash

mac_app_present() {
  local folder
  for folder in /Applications "$HOME/Applications"; do
    [ -s "$folder/$1.app/Contents/Info.plist" ] && return 0
  done
  return 1
}
