#!/usr/bin/env sh
# Name of the focused app, centred (the menu bar is hidden, so nothing else shows it)
sketchybar --add item front_app center \
           --set front_app icon.drawing=off label.font="$FONT:Bold:14.0" \
                           script="$PLUGIN_DIR/front_app.sh" \
           --subscribe front_app front_app_switched
