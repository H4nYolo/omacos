#!/usr/bin/env sh
sketchybar --add item volume right \
           --set volume script="$PLUGIN_DIR/volume.sh" \
                        click_script="osascript -e 'set volume output muted not (output muted of (get volume settings))'" \
           --subscribe volume volume_change
