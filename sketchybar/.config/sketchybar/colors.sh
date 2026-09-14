#!/usr/bin/env sh
# Defaults = Tokyo Night; `omacos-theme set` overrides them via the rendered colors.sh below.
BG=0xff1a1b26
BG_DARK=0xff16161e
FG=0xffc0caf5
COMMENT=0xff565f89
BLUE=0xff7aa2f7
CYAN=0xff7dcfff
GREEN=0xff9ece6a
MAGENTA=0xffbb9af7
RED=0xfff7768e
YELLOW=0xffe0af68
ORANGE=0xffff9e64
ACCENT=$BLUE
MUTED=0xff414868
TRANSPARENT=0x00000000

[ -f "$HOME/.local/state/omacos/theme/colors.sh" ] && . "$HOME/.local/state/omacos/theme/colors.sh"

BAR_COLOR=$BG
ICON_COLOR=$FG
LABEL_COLOR=$FG
