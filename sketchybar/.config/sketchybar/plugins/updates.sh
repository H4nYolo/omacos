#!/usr/bin/env sh
PATH="/opt/homebrew/bin:$PATH"
# Formulae only: inside the sketchybar launchd service brew cannot spawn the helper it
# needs to read cask Info.plists and crashes on the cask check.
brew update --quiet >/dev/null 2>&1
n="$(brew outdated --formula --quiet 2>/dev/null | wc -l | tr -d ' ')"
if [ "${n:-0}" -gt 0 ]; then
  sketchybar --set "$NAME" label="$n" drawing=on
else
  sketchybar --set "$NAME" drawing=off
fi
