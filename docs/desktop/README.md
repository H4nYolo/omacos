# Desktop: tiling, workspaces, bar, borders

[← Manual](../README.md)

![Two Ghostty windows tiled, the focused one with the glowing border, the bar on top](../images/tiling.jpg)

## Dwindle layout

AeroSpace has no dwindle: every new window is put next to its siblings, so three windows end up
side by side. `omacos-dwindled` (started by AeroSpace) watches for new tiled windows and, whenever
one joins a container that already holds two or more, joins it with its neighbour into a nested
container, which AeroSpace's normalization gives the opposite orientation — Hyprland's spiral:
first split side by side, the next one top/bottom, and so on. A fresh workspace always starts
side by side. Kill the watcher to get plain AeroSpace behaviour; `Super + J` still toggles a split by hand.

## Workspaces & monitors

Workspaces `1-5` and `scratch` live on the main display, `6-10` (keys `6 7 8 9 0`) on the second
one (`workspace-to-monitor-force-assignment` in `aerospace/.aerospace.toml`).
Edit the monitor names there for your setup — `aerospace list-monitors` prints them.
Citrix sessions (`.ica` files) are sent to workspace 10 by an `on-window-detected` rule.

`Super + G` turns a workspace into a group (AeroSpace's accordion): one window at a time, the
others stacked behind it. It looks like fullscreen; `Super + G` again brings the tiles back.

## Bar

`sketchybar/` is a Waybar clone in the current theme's colours with Nerd Font glyphs. Left: workspaces (focused =
filled pill, visible on the other monitor = outlined pill, occupied = bright, empty = dim,
`scratch` only when in use). Centre: the focused app. Right, left to right:

- mic / camera in use (best effort, follows macOS' sensor attribution log via `omacos-media-stream`)
- brew updates: number of outdated packages, checked hourly, hidden at zero; click runs `brew upgrade` in the popup
- network: SSID on Wi-Fi, port name on wired; click opens Network settings
- weather: wttr.in, IP-based; put a place in `~/.config/omacos/weather-location` (`Berlin`, `Dieburg,DE`, or `48.5,10.2`) to pin it — the popup and the menu's weather notification use the same file
- bluetooth: connected devices with battery; click opens Bluetooth settings
- audio output device; click opens a chooser in the popup (SwitchAudioSource)
- volume (click mutes), cpu and memory (click opens NeoHtop), clock (click opens Calendar)

The macOS menu bar is hidden by `install.sh`. **Toggle → Bar** in the menu hides the bar.

## Borders

`borders/` draws a rounded, glowing border in the theme's accent colour around the focused window
(JankyBorders; plain and gradient variants are in `bordersrc`). **Toggle → Borders** switches it off.

## Ghostty window title

The title bar stays, in the theme's background colour, without traffic lights (`Super + W`
closes) and without the folder icon. tmux sets the title to `session · window`. The popup and
the screensaver windows have no title bar.
