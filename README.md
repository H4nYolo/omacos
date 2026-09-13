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

## The modifier story

Omarchy hangs everything on `Super`. macOS has no spare modifier, so:

| Omarchy | macOS | How |
|---|---|---|
| `Super` | **Caps Lock** held | Karabiner: caps lock → `ctrl + option + command`; tap = `Escape` |
| `Super + Shift` | **Caps Lock + Shift** | same rule, shift passes through |
| `Alt` | `Option` | untouched, so tmux keeps its `Alt` bindings (Ghostty sends option as alt) |
| `Super + Alt`, `Super + Ctrl` | – | not expressible; those bindings were re-homed (below) |

`Caps Lock + Space` stays your launcher (Karabiner turns it into `⌘ Space` for Raycast).

`Caps Lock + Shift + , . /` are swallowed by Karabiner — macOS would otherwise
start sysdiagnose on them.

## Keybindings

Everything Omarchy has, on the same keys, with `Super` = Caps Lock.

**Windows** — `W`/`Q` close · `T` float · `J` split · `F` fullscreen ·
arrows focus · `Shift + arrows` swap · `-`/`=` resize · `Shift + -`/`=` resize the other axis · `Home` balance

**Workspaces** — `1-9` jump · `Shift + 1-9` move window & follow · `Tab`/`Shift + Tab` next/prev ·
`0` previous workspace · `S` or `` ` `` toggle scratchpad · `Shift + S` send to scratchpad

**Monitors** — `Ctrl + Alt + Tab` cycle · `Shift + Home`/`End` move workspace to prev/next monitor

**Groups** (AeroSpace accordion) — `G` toggle · `/` next in group · `Shift + U` ungroup ·
`Shift + ;` then `Shift + arrow` join a neighbour

**Apps** — `Enter` Ghostty · `Shift + T` Ghostty with tmux · `Shift + Enter` Zen · `Shift + F` Finder ·
`Shift + N` nvim · `Shift + D` lazydocker · `Shift + A` NeoHtop · `Shift + G` Telegram

`Alt + Tab` cycles windows on the workspace.

**Help** — `Super + K` opens a searchable list of every binding (AeroSpace and tmux), generated
from the config itself. Inside tmux, `Prefix + ?` lists the tmux keys.

### Re-homed keys (no `Super + Alt` / `Super + Ctrl`)

| Omarchy | Here |
|---|---|
| `Super + Ctrl + Tab` previous workspace | `Super + 0` |
| `Super + Alt + S` move to scratchpad | `Super + Shift + S` |
| `Super + Alt + Return` tmux terminal | `Super + Shift + T` |
| `Super + Alt + Tab` next in group | `Super + /` |
| `Super + Alt + G` leave group | `Super + Shift + U` |
| `Super + Shift + Alt + ←/→` workspace to monitor | `Super + Shift + Home/End` |
| `Super + Ctrl + T` activity | `Super + Shift + A` |
| `Super + Ctrl + F` native fullscreen | macOS `⌃⌘F` |
| `Super + Ctrl + L` lock | macOS `⌃⌘Q` |

### Not portable

Sticky windows, scrolling layout, pseudo-tiling, gap toggling and
focus-follows-mouse have no AeroSpace equivalent.

## Workspaces & monitors

Workspaces `1-5` and `scratch` live on the main display, `6-9` on the second
one (`workspace-to-monitor-force-assignment` in `aerospace/.aerospace.toml`).
Edit the monitor names there for your setup — `aerospace list-monitors` prints them.

## Bar, borders, wallpaper

`sketchybar/` is a Waybar clone: workspaces on the left (focused = blue pill, occupied = bright,
empty = dim, `scratch` only when in use), volume / cpu / memory / clock on the right, all in
Tokyo Night with Nerd Font glyphs. The macOS menu bar is hidden by `install.sh`.
`borders/` draws Hyprland's 2px accent border around the focused window.
`install.sh` fetches Omarchy's Tokyo Night wallpaper and sets it on every display.
Raycast keeps its stock dark look: custom themes need Raycast Pro.

## tmux

Omarchy's tmux config as-is: prefix `Ctrl + Space`, `Alt + Enter` / `Alt + Shift + Enter` split,
`Alt + 1-9` windows, `Alt + arrows` navigate, plus `Ctrl + h/j/k/l` pane navigation that is vim-aware.

## Shell

`zsh/.config/zsh/omarchy.zsh` is Omarchy's `default/bash/aliases`, running
unchanged in zsh (`ls`, `lt`, `ff`, zoxide `cd`, `c`/`cx` for AI agents,
`t` for tmux, git shortcuts) plus the `tdl`, `tdlm` and `tsl` tmux layouts.
Secrets and machine-specific exports go in `~/.zshrc.local`, which is never committed.

## Credits

Configuration derived from [Omarchy](https://github.com/basecamp/omarchy) by
Basecamp, MIT licensed. See `LICENSE`.
