#!/usr/bin/env sh
# Omarchy's update indicator: number of outdated brew packages, hidden when none.
# Hourly, plus right after the brew popup finishes (omacos-popup-run fires brew_update).
sketchybar --add event brew_update \
           --add item updates right \
           --set updates icon="󰚰" icon.color=$YELLOW drawing=off updates=on update_freq=3600 \
                         script="$PLUGIN_DIR/updates.sh" \
                         click_script="$HOME/.local/bin/omacos-popup brew" \
           --subscribe updates brew_update
