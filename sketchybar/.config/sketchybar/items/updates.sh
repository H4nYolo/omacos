#!/usr/bin/env sh
# Omarchy's update indicator: number of outdated brew packages, hidden when none
sketchybar --add item updates right \
           --set updates icon="󰚰" icon.color=$YELLOW drawing=off update_freq=3600 \
                         script="$PLUGIN_DIR/updates.sh" \
                         click_script="$HOME/.local/bin/omacos-popup brew"
