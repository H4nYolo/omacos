#!/usr/bin/env sh
# Current output device; click opens a chooser in the popup
sketchybar --add item audio right \
           --set audio update_freq=10 script="$PLUGIN_DIR/audio.sh" \
                       click_script="$HOME/.local/bin/omacos-popup audio" \
           --subscribe audio volume_change
