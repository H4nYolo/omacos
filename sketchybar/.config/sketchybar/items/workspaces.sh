#!/usr/bin/env sh
# AeroSpace workspaces. Persistent list mirrors persistent-workspaces in ~/.aerospace.toml,
# so the bar comes up correctly even when AeroSpace is not running yet.
WORKSPACES="1 2 3 4 5 6 7 8 9 10 scratch"

sketchybar --add event aerospace_workspace_change

for ws in $WORKSPACES; do
  sketchybar --add item "space.$ws" left \
             --set "space.$ws" icon="$ws" \
                               icon.padding_left=8 \
                               icon.padding_right=8 \
                               icon.color=$COMMENT \
                               icon.highlight_color=$BG \
                               label.drawing=off \
                               background.color=$ACCENT \
                               background.corner_radius=4 \
                               background.height=22 \
                               background.drawing=off \
                               click_script="aerospace workspace $ws"
done

# One hidden item does the update for all workspaces on every change
sketchybar --add item workspaces.updater left \
           --set workspaces.updater drawing=off \
                                    updates=on \
                                    script="$PLUGIN_DIR/workspaces.sh" \
           --subscribe workspaces.updater aerospace_workspace_change front_app_switched
