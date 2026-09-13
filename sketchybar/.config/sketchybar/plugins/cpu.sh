#!/usr/bin/env sh
# Sum of per-process cpu / core count, like Omarchy's waybar cpu module
cores=$(sysctl -n hw.ncpu)
pct=$(ps -A -o %cpu | awk -v c="$cores" 'NR>1 {s+=$1} END {printf "%d", s/c}')
sketchybar --set "$NAME" label="${pct}%"
