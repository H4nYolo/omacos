#!/usr/bin/env sh
# Microphone / camera in use (best effort: follows macOS' own sensor attribution log).
# Hidden unless something is recording. The plugin keeps a `log stream` running.
sketchybar --add item media right \
           --set media icon="" icon.color=$RED label.drawing=off drawing=off \
                       updates=on update_freq=60 script="$PLUGIN_DIR/media.sh"
