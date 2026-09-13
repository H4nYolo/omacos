#!/usr/bin/env sh
# wttr.in one-liner: "<location> <icon> <temp>". Location: ~/.config/omacos/weather-location
# (e.g. "Berlin", "Dieburg,DE", "48.5,10.2"), IP-based when the file is missing or empty.
WEATHER_LOCATION="$(cat "$HOME/.config/omacos/weather-location" 2>/dev/null | tr -d '[:space:]' | sed 's/ /+/g')"
out="$(curl -s -m 10 "wttr.in/${WEATHER_LOCATION}?format=%l|%c|%t" 2>/dev/null)"
case "$out" in
  *"|"*"|"*) loc="${out%%|*}"; rest="${out#*|}"; icon="${rest%%|*}"; temp="${rest#*|}"
             sketchybar --set "$NAME" label="$(printf '%s %s %s' "${loc%%,*}" "$icon" "$temp" | tr -s ' ')" drawing=on ;;
  *)         sketchybar --set "$NAME" drawing=off ;;   # offline or wttr.in down: hide
esac
