#!/usr/bin/env sh
PATH="/opt/homebrew/bin:$PATH"
dev="$(SwitchAudioSource -c -t output 2>/dev/null)"
case "$dev" in
  *Headphone*|*AirPods*|*Buds*|*Headset*) icon="󰋋" ;;
  *Teams*|*Zoom*|*Webex*)                 icon="󰍬" ;;
  *)                                      icon="󰓃" ;;
esac
label="$(printf '%s' "$dev" | sed -E 's/ Speakers$//; s/^Microsoft //')"
sketchybar --set "$NAME" icon="$icon" label="$label"
