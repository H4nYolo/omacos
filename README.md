# omacos

Omarchy look & feel on macOS. A port of the terminal and tiling experience of
[Omarchy](https://github.com/basecamp/omarchy) — Hyprland keybindings, tmux, shell
aliases, Tokyo Night — onto AeroSpace, Ghostty, tmux, zsh and Karabiner.

| Omarchy piece | On the Mac |
|---|---|
| Hyprland tiling & bindings | [AeroSpace](https://github.com/nikitabobko/AeroSpace) (`aerospace/`) |
| Waybar | [sketchybar](https://github.com/FelixKratz/SketchyBar) (`sketchybar/`) |
| Window borders | [JankyBorders](https://github.com/FelixKratz/JankyBorders) (`borders/`) |
| `Super` key | Caps Lock via [Karabiner-Elements](https://karabiner-elements.pqrs.org) (`karabiner/`) |
| tmux config | tmux (`tmux/`) |
| bash aliases, `tdl` / `tdlm` / `tsl` layouts | zsh (`zsh/`) |
| Alacritty / Ghostty | Ghostty (`ghostty/`) |
| LazyVim | LazyVim (`nvim/`) |
| btop | [NeoHtop](https://github.com/Abdenasser/neohtop) on `Super + Shift + A` |
| Walker (`Super + Space` menu) | `omacos-launcher`: fzf app list in a floating Ghostty, Pearcleaner on `ctrl-x` |
| Clean app uninstall | [Pearcleaner](https://github.com/alienator88/Pearcleaner), with its Sentinel watching the Trash |
| Theme | Tokyo Night everywhere (`themes/`) |

## Install

```sh
git clone https://github.com/H4nYolo/omacos ~/work/projects/omacos
cd ~/work/projects/omacos
./install.sh
```

`install.sh` runs `brew bundle`, hides the macOS menu bar, moves any existing
configs to `~/.config-archive/<timestamp>/`, links every package with GNU stow
and starts the services. Re-running it is safe.

Each top-level directory is a stow package mirroring `$HOME`, so a single tool
can be linked on its own: `stow --target=$HOME aerospace`.

### First run: permissions macOS will ask for

- **Karabiner-Elements** — Input Monitoring (and its driver extension under Login Items & Extensions)
- **AeroSpace** — Accessibility
- **Ghostty** — Accessibility (global hotkey of the popup panel)
- **Sol** — Accessibility (window management, clipboard)
- **Pearcleaner** — Full Disk Access to find leftovers; turn on *Sentinel* in its settings

Grant them once, then restart the app that asked.

### Packages

| package | links |
|---|---|
| `aerospace` | `~/.aerospace.toml` |
| `karabiner` | `~/.config/karabiner/` (Karabiner rewrites `karabiner.json` itself; backups are ignored) |
| `tmux` | `~/.config/tmux/tmux.conf` |
| `zsh` | `~/.zshrc`, `~/.p10k.zsh`, `~/.config/zsh/omarchy.zsh` |
| `ghostty` | `~/.config/ghostty/config`, `popup` (the popup instance), `screensaver` |
| `sketchybar`, `borders` | `~/.config/sketchybar/`, `~/.config/borders/bordersrc` |
| `sol` | `~/.config/sol/` (Sol writes `config.json` itself; `state.json` is ignored) |
| `nvim`, `git` | `~/.config/nvim/`, `~/.config/git/ignore` |
| `bin` | `~/.local/bin/omacos-launcher`, `omacos-keys`, `omacos-scratchpad`, `omacos-popup`, `omacos-popupd`, `omacos-popup-run`, `omacos-media-stream`, `omacos-screensaver`, `omacos-screensaver-run`, `omacos-idle` |
| `omacos` | `~/.config/omacos/` (screensaver text, idle minutes) |

## The modifier story

Omarchy hangs everything on `Super`. macOS has no spare modifier, so:

| Omarchy | macOS | How |
|---|---|---|
| `Super` | **Caps Lock** held | Karabiner: caps lock → `ctrl + option + command`; tap = `Escape` |
| `Super + Shift` | **Caps Lock + Shift** | same rule, shift passes through |
| `Alt` | `Option` | untouched, so tmux keeps its `Alt` bindings (Ghostty sends option as alt) |
| `Super + Alt`, `Super + Ctrl` | – | not expressible; those bindings were re-homed (below) |

`Caps Lock + Space` opens the app launcher. Sol, if installed, keeps its own `⌥ Space`.

`Caps Lock + Shift + , . /` are swallowed by Karabiner — macOS would otherwise
start sysdiagnose on them.

## Keybindings

Everything Omarchy has, on the same keys, with `Super` = Caps Lock.

**Windows** — `W`/`Q` close the window and quit the app when it was its last one · `T` float · `J` split · `F` fullscreen ·
arrows focus · `Shift + arrows` swap · `-`/`=` resize · `Shift + -`/`=` resize the other axis · `Home` balance

**Workspaces** — `1-9`, `0` (= 10) jump, press the current one again to go back · `Shift + 1-9`, `Shift + 0` move window & follow ·
`Tab`/`Shift + Tab` next/prev · `S` or `` ` `` toggle scratchpad · `Shift + S` send to scratchpad

**Monitors** — `Ctrl + Alt + Tab` cycle · `Shift + Home`/`End` move workspace to prev/next monitor

**Groups** (AeroSpace accordion) — `G` toggle · `/` next in group · `Shift + U` ungroup ·
`Shift + ;` then `Shift + arrow` join a neighbour

**Apps** — `Enter` Ghostty · `Shift + T` Ghostty with tmux · `Shift + Enter` Zen · `Shift + F` Finder ·
`Shift + N` nvim · `Shift + D` lazydocker · `Shift + A` NeoHtop · `Shift + G` Telegram

`Alt + Tab` cycles windows on the workspace.

**Menus** — `Shift + Space` omacos menu · `Shift + C` capture · `Shift + E` emoji · `Shift + V` clipboard history

**Help** — `Super + K` opens a searchable list of every binding (AeroSpace and tmux), generated
from the config itself, plus the shell aliases, tmux layouts (`ix`, `tdl`, `tsl`, …) and every
`omacos-*` command, in the popup panel (below). `Shift + K` shows only the tmux keys, `omacos-keys shell`
only the shell part. `Esc` closes it.

### Re-homed keys (no `Super + Alt` / `Super + Ctrl`)

| Omarchy | Here |
|---|---|
| `Super + Ctrl + Tab` previous workspace | press the current workspace's key again |
| `Super + Alt + S` move to scratchpad | `Super + Shift + S` |
| `Super + Alt + Return` tmux terminal | `Super + Shift + T` |
| `Super + Alt + Tab` next in group | `Super + /` |
| `Super + Alt + G` leave group | `Super + Shift + U` |
| `Super + Shift + Alt + ←/→` workspace to monitor | `Super + Shift + Home/End` |
| `Super + Ctrl + T` activity | `Super + Shift + A` |
| `Super + Ctrl + F` native fullscreen | macOS `⌃⌘F` |
| `Super + Ctrl + L` lock | macOS `⌃⌘Q` |
| `Super + Space` Omarchy menu / `Super + Alt + Space` apps | `Super + Shift + Space` / `Super + Space` |
| `Super + Ctrl + C` capture · `Super + Ctrl + E` emoji · `Super + Ctrl + V` clipboard | `Super + Shift + C` · `E` · `V` |
| `Super + Alt + K` tmux keybindings | `Super + Shift + K` |

### Not portable

Sticky windows, scrolling layout, pseudo-tiling, gap toggling and
focus-follows-mouse have no AeroSpace equivalent.

## Workspaces & monitors

Workspaces `1-5` and `scratch` live on the main display, `6-10` (keys `6 7 8 9 0`) on the second
one (`workspace-to-monitor-force-assignment` in `aerospace/.aerospace.toml`).
Edit the monitor names there for your setup — `aerospace list-monitors` prints them.
Citrix sessions (`.ica` files) are sent to workspace 10 by an `on-window-detected` rule.

## Bar, borders, wallpaper

`sketchybar/` is a Waybar clone in Tokyo Night with Nerd Font glyphs. Left: workspaces (focused =
filled blue pill, visible on the other monitor = outlined blue pill, occupied = bright, empty = dim,
`scratch` only when in use). Centre: the focused app.
Right, left to right:

- mic / camera in use (best effort, follows macOS' sensor attribution log via `omacos-media-stream`)
- brew updates: number of outdated packages, checked hourly, hidden at zero; click runs `brew upgrade` in the popup
- network: SSID on Wi-Fi, port name on wired; click opens Network settings
- weather: wttr.in, IP-based; put a place in `~/.config/omacos/weather-location` (`Berlin`, `Dieburg,DE`, or `48.5,10.2`) to pin it — the popup and the menu's weather notification use the same file
- bluetooth: connected devices with battery; click opens Bluetooth settings
- audio output device; click opens a chooser in the popup (SwitchAudioSource)
- volume (click mutes), cpu and memory (click opens NeoHtop), clock (click opens Calendar) The macOS menu bar is hidden by `install.sh`.
`borders/` draws Hyprland's 2px accent border around the focused window.
`install.sh` fetches Omarchy's Tokyo Night wallpaper and sets it on every display.

## Menu, launcher and uninstall

`Super + Shift + Space` opens `omacos-menu`, Omarchy's menu as a tree of fzf lists in the popup
panel (`Backspace` on an empty query goes up a level, also out of the pickers; `Esc` closes):

- **Apps** — the launcher below
- **Learn** — keybindings (all / tmux / AeroSpace), the omacos repo, the Omarchy manual, AeroSpace, Ghostty and tmux docs
- **Capture** (`Super + Shift + C`) — screenshot of a region, window or screen (saved to `~/Pictures/Screenshots` and copied),
  screen recording with or without microphone (the entry turns into *Stop* while recording),
  text recognition (OCR) from a selection straight into the clipboard, the clipboard as a QR code, a colour picker that copies hex
- **Clipboard** (`Super + Shift + V`) — history of the last 200 text entries (`omacos-clipboardd`, started by AeroSpace);
  `Enter` pastes into the app that had focus, `ctrl-x` deletes, `alt-c` clears. Password managers' concealed entries are skipped
- **Emoji** (`Super + Shift + E`) — search by name or keyword, `Enter` pastes
- **Toggle** — screensaver on idle, bar, borders, microphone mute
- **Install** — `omacos-pkg-install`: every Homebrew formula and cask in fzf with `brew info` as preview, `Tab` multi-select,
  `Enter` installs right there. Or the App Store
- **Remove** — `omacos-pkg-remove`: the same for what is installed (`brew leaves` + casks, unused dependencies go too), or an app via Pearcleaner
- **Update** — `brew upgrade`, `brew outdated`, macOS software update
- **Info** — time, weather and network as notifications, About
- **System** — screensaver, lock, sleep, logout, restart, shutdown

The OCR helper is Apple's Vision framework (`~/.config/omacos/ocr.swift`); `install.sh` compiles it once
into `~/.cache/omacos/omacos-ocr`, the capture menu does the same on first use if needed.

### Launcher

`Super + Space` opens `omacos-launcher`, the walker look-alike: every app from `/Applications`,
`~/Applications` and the system folders in a monochrome fzf list, most-launched first. `Enter`
launches, `ctrl-x` opens the app in Pearcleaner with its leftovers listed for a clean uninstall,
`Esc` closes. Launch counts live in `~/.local/state/omacos/launcher-history`.

### The popup panel

Launcher and help run in Ghostty's *quick terminal*: a floating panel, centred on the monitor
under the mouse, that AeroSpace never tiles, so it appears in place with no jumps. A second
Ghostty process started by AeroSpace (`omacos-popupd`, config `~/.config/ghostty/popup`) owns
it. `omacos-popup <launcher|keys|menu [route]|emoji|clipboard>` writes the request to `~/.local/state/omacos/popup-request`
and fires that process's private global hotkey (`ctrl+alt+shift+cmd+F19`, never typed by hand);
`omacos-popup-run` inside the panel then execs the requested script. When it exits, the panel
disappears. Ghostty needs Accessibility for the global hotkey.

[Sol](https://github.com/ospfranco/sol) stays around on `⌥ Space` as a calculator; drop it from the
Brewfile if you don't need it. Its built-in window management is switched off in `sol/.config/sol/config.json`:
Sol's default `⌃⌥⌘ ←/→` (move window to the next screen) is `Super + ←/→` here, and with both active every
focus change made the window jump.
Uninstalling is Pearcleaner's job. Pick the app in the launcher with `ctrl-x`, or drag an app to
the Trash: Pearcleaner's Sentinel (enable it in Pearcleaner's settings) pops up and offers to
remove the leftovers. From a script: `/Applications/Pearcleaner.app/Contents/MacOS/Pearcleaner uninstall-all /Applications/Foo.app`.

Note: Pearcleaner turns into that CLI whenever `TERM` is set in its environment, which is why
`install.sh` launches Sol and AeroSpace with `TERM` and `TMUX` stripped.

## Screensaver

Omarchy's terminal screensaver: after 5 idle minutes (`~/.config/omacos/idle-minutes`, `0`
disables it) `omacos-idle` opens one fullscreen Ghostty per monitor running random
[terminaltexteffects](https://github.com/ChrisBuilds/terminaltexteffects) animations on
`~/.config/omacos/screensaver.txt` (Omarchy's logo by default, edit it or drop in your own ASCII
art). Any key, or clicking somewhere else, ends it on every monitor. It stays off while an app
keeps the display awake (video, calls). Start it by hand from the launcher (`Screensaver`) or with
`omacos-screensaver`. The launcher also has `Lock screen` and `Sleep`.

## tmux

Omarchy's tmux config as-is: prefix `Ctrl + Space`, `Alt + Enter` / `Alt + Shift + Enter` split,
`Alt + 1-9` windows, `Alt + arrows` navigate, plus `Ctrl + h/j/k/l` pane navigation that is vim-aware.

## Shell

`zsh/.config/zsh/omarchy.zsh` is Omarchy's `default/bash/aliases`, running
unchanged in zsh (`ls`, `lt`, `ff`, zoxide `cd`, `c`/`cx` for AI agents,
`t` for tmux, git shortcuts) plus the `tdl`, `tdlm` and `tsl` tmux layouts. `ix ~/work/foo`
(= `tdl cx ~/work/foo`) opens the editor / Claude Code / terminal layout in that folder and
offers to create it when it does not exist yet.
Secrets and machine-specific exports go in `~/.zshrc.local`, which is never committed.

## Credits

Configuration derived from [Omarchy](https://github.com/basecamp/omarchy) by
Basecamp, MIT licensed. See `LICENSE`.
