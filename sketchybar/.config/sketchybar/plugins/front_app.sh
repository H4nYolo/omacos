#!/usr/bin/env sh
PATH="/opt/homebrew/bin:$PATH"
app="${INFO:-$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null)}"
sketchybar --set "$NAME" label="$app"
