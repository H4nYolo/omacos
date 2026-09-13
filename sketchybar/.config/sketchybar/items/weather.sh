#!/usr/bin/env sh
# Weather with location from wttr.in (IP-based unless WEATHER_LOCATION is set in the plugin)
sketchybar --add item weather right \
           --set weather updates=on update_freq=900 icon.drawing=off script="$PLUGIN_DIR/weather.sh" \
                         click_script="$HOME/.local/bin/omacos-popup weather"
