#!/usr/bin/env sh
# Watchdog: the actual work happens in omacos-media-stream (started by AeroSpace at login)
PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
pgrep -f '^log stream .*attributions changed' >/dev/null && exit 0
( cd / && nohup omacos-media-stream </dev/null >/dev/null 2>&1 & )
