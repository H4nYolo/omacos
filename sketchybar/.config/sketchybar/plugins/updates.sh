#!/usr/bin/env sh
PATH="/opt/homebrew/bin:$PATH"
# Formulae only: inside the sketchybar launchd service brew cannot spawn the helper it
# needs to read cask Info.plists and crashes on the cask check.
# ~/.config/omacos/updates-ignore lists formulae to leave out (one per line, # comments).
brew update --quiet >/dev/null 2>&1
ignore="$(mktemp)"
grep -vE '^\s*(#|$)' "$HOME/.config/omacos/updates-ignore" 2>/dev/null | sed 's|.*/||' > "$ignore"
n="$(brew outdated --formula --quiet 2>/dev/null | sed 's|.*/||' | grep -vxF -f "$ignore" | wc -l | tr -d ' ')"
rm -f "$ignore"
if [ "${n:-0}" -gt 0 ]; then
  sketchybar --set "$NAME" label="$n" drawing=on
else
  sketchybar --set "$NAME" drawing=off
fi
