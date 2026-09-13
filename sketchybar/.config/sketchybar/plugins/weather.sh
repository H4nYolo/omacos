#!/usr/bin/env sh
# wttr.in one-liner: "<location> <icon> <temp>". Set WEATHER_LOCATION to pin a place, e.g. "Berlin".
WEATHER_LOCATION="${WEATHER_LOCATION:-}"
out="$(curl -s -m 10 "wttr.in/${WEATHER_LOCATION}?format=%l|%c|%t" 2>/dev/null)"
case "$out" in
  *"|"*"|"*) loc="${out%%|*}"; rest="${out#*|}"; icon="${rest%%|*}"; temp="${rest#*|}"
             sketchybar --set "$NAME" label="$(printf '%s %s %s' "${loc%%,*}" "$icon" "$temp" | tr -s ' ')" drawing=on ;;
  *)         sketchybar --set "$NAME" drawing=off ;;   # offline or wttr.in down: hide
esac
