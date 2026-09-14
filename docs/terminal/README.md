# Terminal, shell, screensaver

[← Manual](../README.md)

## Ghostty

`ghostty/.config/ghostty/config`: CaskaydiaMono Nerd Font, Omarchy's padding, no close confirmation,
option sends alt (tmux owns `Alt`), the kitty keyboard protocol for the chords tmux needs, and two
optional includes that `omacos-theme` and `omacos-font` render: the palette and the font family.
The title bar keeps the theme's background colour without buttons; tmux writes the title.
`popup` and `screensaver` are the configs of the two extra Ghostty instances (quick terminal,
idle animation) and load on top of the main one.

## tmux

Omarchy's tmux config as-is: prefix `Ctrl + Space` (`Ctrl + B` still works), `Alt + Enter` /
`Alt + Shift + Enter` split, `Alt + 1-9` windows, `Alt + arrows` navigate, plus `Ctrl + h/j/k/l`
pane navigation that is vim-aware. Colours come from the terminal palette, so a theme switch
recolours running sessions.

## Shell

`zsh/.config/zsh/omarchy.zsh` is Omarchy's `default/bash/aliases`, running
unchanged in zsh (`ls`, `lt`, `ff`, zoxide `cd`, `c`/`cx` for AI agents,
`t` for tmux, git shortcuts) plus the `tdl`, `tdlm` and `tsl` tmux layouts. `ix ~/work/foo`
(= `tdl cx ~/work/foo`) opens the editor / Claude Code / terminal layout in that folder and
offers to create it when it does not exist yet. Oh My Zsh and Powerlevel10k stay.
Secrets and machine-specific exports go in `~/.zshrc.local`, which is never committed.
`Super + K`, then type `alias` or a tool's name, lists every alias and every CLI tool from the
Brewfile with a one-line description.

## Neovim

LazyVim (`nvim/`). The colourscheme follows the omacos theme (`lua/plugins/theme.lua` loads the
spec that `omacos-theme set` rendered); a running nvim keeps its colours until restarted.

## Screensaver

Omarchy's terminal screensaver: after 5 idle minutes (`~/.config/omacos/idle-minutes`, `0`
disables it) `omacos-idle` opens one fullscreen Ghostty per monitor running random
[terminaltexteffects](https://github.com/ChrisBuilds/terminaltexteffects) animations on
`~/.config/omacos/screensaver.txt` (Omarchy's logo by default, edit it or drop in your own ASCII
art). Any key, or clicking somewhere else, ends it on every monitor. It stays off while an app
keeps the display awake (video, calls). Start it by hand from the launcher (`Screensaver`) or with
`omacos-screensaver`. The launcher also has `Lock screen` and `Sleep`; **Toggle → Screensaver on
idle** switches the timer off.

## Every omacos command

`omacos-keys shell` (or `Super + K`) lists every `omacos-*` script with its one-line summary.
The important ones: `omacos-theme`, `omacos-background`, `omacos-font`, `omacos-menu`,
`omacos-launcher`, `omacos-capture`, `omacos-notes`, `omacos-toggle`, `omacos-system`,
`omacos-pkg-install`, `omacos-pkg-remove`, `omacos-popup`, `omacos-shell`.
