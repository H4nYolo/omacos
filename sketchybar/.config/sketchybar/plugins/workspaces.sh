#!/usr/bin/env bash
# Colour every workspace item:
#   focused                       = filled blue pill
#   visible on the other monitor  = outlined blue pill (so you see what the 2nd screen shows)
#   has windows                   = bright
#   empty                         = dim
# scratch is hidden unless focused or occupied.
PATH="/opt/homebrew/bin:$PATH"
source "$HOME/.config/sketchybar/colors.sh"

focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
visible="$(aerospace list-workspaces --monitor all --visible 2>/dev/null)"
occupied="$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)"

args=()
for ws in 1 2 3 4 5 6 7 8 9 10 scratch; do
  if [ "$ws" = "$focused" ]; then
    args+=(--set "space.$ws" background.drawing=on background.color=$ACCENT background.border_width=0 \
                             icon.highlight=on drawing=on)
  elif grep -qx "$ws" <<< "$visible"; then
    args+=(--set "space.$ws" background.drawing=on background.color=$TRANSPARENT \
                             background.border_color=$ACCENT background.border_width=2 \
                             icon.highlight=off icon.color=$ACCENT drawing=on)
  elif grep -qx "$ws" <<< "$occupied"; then
    args+=(--set "space.$ws" background.drawing=off icon.highlight=off icon.color=$FG drawing=on)
  else
    drawing=on; [ "$ws" = "scratch" ] && drawing=off
    args+=(--set "space.$ws" background.drawing=off icon.highlight=off icon.color=$COMMENT drawing=$drawing)
  fi
done
sketchybar "${args[@]}"
