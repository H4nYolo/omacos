#!/usr/bin/env sh
# Keep-awake indicator: countdown to the next nudge into the remote session's window.
# Hidden unless omacos-awake runs — the daemon sets label and drawing itself (no polling).
# Click stops it.
sketchybar --add item awake right \
           --set awake icon="󰅶" icon.color=$GREEN drawing=off \
                       click_script="$HOME/.local/bin/omacos-awake toggle"
