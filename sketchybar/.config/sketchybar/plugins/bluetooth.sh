#!/usr/bin/env sh
# Connected devices with battery level where the device reports one
PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"
json="$(system_profiler SPBluetoothDataType -json 2>/dev/null)"
state="$(printf '%s' "$json" | jq -r '.SPBluetoothDataType[0].controller_properties.controller_state // "attrib_on"')"
if [ "$state" != "attrib_on" ]; then
  sketchybar --set "$NAME" icon="󰂲" label=""
  exit 0
fi
devices="$(printf '%s' "$json" | jq -r '
  [.SPBluetoothDataType[0].device_connected[]? | to_entries[] |
   (.key | sub(" .*"; "")) + (if .value.device_batteryLevelMain then " " + (.value.device_batteryLevelMain | gsub("[^0-9%]"; "")) else "" end)]
  | join(" · ")')"
if [ -n "$devices" ]; then
  sketchybar --set "$NAME" icon="󰂱" label="$devices"
else
  sketchybar --set "$NAME" icon="󰂯" label=""
fi
