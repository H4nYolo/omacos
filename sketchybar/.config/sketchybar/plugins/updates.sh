#!/usr/bin/env sh
PATH="/opt/homebrew/bin:$PATH"
brew update --quiet >/dev/null 2>&1
n="$(brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')"
if [ "${n:-0}" -gt 0 ]; then
  sketchybar --set "$NAME" label="$n" drawing=on
else
  sketchybar --set "$NAME" drawing=off
fi
