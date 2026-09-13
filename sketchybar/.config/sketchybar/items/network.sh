#!/usr/bin/env sh
sketchybar --add item network right \
           --set network update_freq=15 script="$PLUGIN_DIR/network.sh" \
                         click_script="open x-apple.systempreferences:com.apple.Network-Settings.extension"
