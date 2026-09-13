#!/usr/bin/env sh
# $INFO carries the new volume on volume_change; fall back to a query on startup
vol="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"
muted=$(osascript -e 'output muted of (get volume settings)')
if [ "$muted" = "true" ] || [ "$vol" -eq 0 ]; then icon="󰝟"
elif [ "$vol" -lt 34 ]; then icon="󰕿"
elif [ "$vol" -lt 67 ]; then icon="󰖀"
else icon="󰕾"; fi
sketchybar --set "$NAME" icon="$icon" label="${vol}%"
