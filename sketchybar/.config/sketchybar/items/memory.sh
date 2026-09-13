#!/usr/bin/env sh
sketchybar --add item memory right \
           --set memory icon="" update_freq=5 script="$PLUGIN_DIR/memory.sh" \
                        click_script="open -a NeoHtop"
