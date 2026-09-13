#!/usr/bin/env sh
sketchybar --add item cpu right \
           --set cpu icon="" update_freq=3 script="$PLUGIN_DIR/cpu.sh" \
                     click_script="open -a NeoHtop"
