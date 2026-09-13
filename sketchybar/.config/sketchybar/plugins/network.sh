#!/usr/bin/env sh
# Active interface of the default route: Wi-Fi shows the SSID, wired shows the port name
iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
if [ -z "$iface" ]; then
  icon="󰤮"; label="offline"
else
  port="$(networksetup -listallhardwareports | awk -v i="$iface" '$0 == "Device: "i {print prev} {prev=$0}' | sed 's/Hardware Port: //')"
  case "$port" in
    *Wi-Fi*|*AirPort*) ssid="$(ipconfig getsummary "$iface" 2>/dev/null | awk -F': ' '/ SSID/{print $2; exit}')"; icon="󰤨"; label="${ssid:-Wi-Fi}" ;;
    *)                 icon="󰈀"; label="${port:-$iface}" ;;
  esac
fi
sketchybar --set "$NAME" icon="$icon" label="$label"
