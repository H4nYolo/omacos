#!/usr/bin/env sh
# Used = active + wired + compressed pages, as a percentage of physical memory
total=$(sysctl -n hw.memsize)
pct=$(vm_stat | awk -v total="$total" '
  /page size of/ { ps=$8 }
  /Pages active/ { a=$3 } /Pages wired/ { w=$4 } /Pages occupied by compressor/ { c=$5 }
  END { gsub(/\./,"",a); gsub(/\./,"",w); gsub(/\./,"",c); printf "%d", (a+w+c)*ps*100/total }')
sketchybar --set "$NAME" label="${pct}%"
