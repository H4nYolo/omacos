#!/usr/bin/env sh
sketchybar --add item bluetooth right \
           --set bluetooth update_freq=30 script="$PLUGIN_DIR/bluetooth.sh" \
                           click_script="open x-apple.systempreferences:com.apple.BluetoothSettings"
