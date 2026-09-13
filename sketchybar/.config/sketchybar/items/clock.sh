#!/usr/bin/env sh
sketchybar --add item clock right \
           --set clock icon="" update_freq=10 script="$PLUGIN_DIR/clock.sh" \
                       click_script="open -a Calendar"
