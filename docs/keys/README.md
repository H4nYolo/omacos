# Keys

[← Manual](../README.md)

## The modifier story

Omarchy hangs everything on `Super`. macOS has no spare modifier, so Karabiner-Elements
(`karabiner/`) rewires two keys:

| Omarchy | Here | How |
|---|---|---|
| `Super` | **Left Command** held | Karabiner: left command → `ctrl + option + command` |
| `Super + Shift` | **Left Command + Shift** | same rule, shift passes through |
| macOS `⌘` shortcuts (`⌘C`, `⌘V`, `⌘T`, `⌘Tab` …) | **Caps Lock** held | Karabiner: caps lock → `command` |
| `Escape` | **Caps Lock** tapped | same rule |
| `Alt` | `Option` | untouched, so tmux keeps its `Alt` bindings (Ghostty sends option as alt) |
| `Super + Alt`, `Super + Ctrl` | – | not expressible on this keyboard; those bindings were re-homed (below) |

Super sits under the thumb, which is the point: every Omarchy chord is reachable without leaving
the home row. The price is that the macOS Command key moved to Caps Lock. If that is not for you,
swap the two rules in `karabiner/.config/karabiner/karabiner.json` back, or remap one thumb key of
your keyboard to Right Command and bind Super to that.

`Super + Shift + , . /` are never bound: Karabiner swallows them (macOS would start sysdiagnose).

## Keybindings

Everything Omarchy has, on the same keys, with `Super` = Left Command held.

**Windows** — `W`/`Q` close the window and quit the app when it was its last one · `T` float · `J` split · `F` fullscreen ·
arrows focus · `Shift + arrows` swap · `-`/`=` resize · `Shift + -`/`=` resize the other axis · `Home` balance

**Workspaces** — `1-9`, `0` (= 10) jump, press the current one again to go back · `Shift + 1-9`, `Shift + 0` move window & follow ·
`Tab`/`Shift + Tab` next/prev · `S` or `` ` `` toggle scratchpad · `Shift + S` send to scratchpad

**Monitors** — `Ctrl + Alt + Tab` cycle · `Shift + Home`/`End` move workspace to prev/next monitor

**Groups** (AeroSpace accordion) — `G` toggle · `/` next in group · `Shift + U` ungroup ·
`Shift + ;` then `Shift + arrow` join a neighbour

**Apps** — `Enter` Ghostty · `Shift + T` Ghostty with tmux · `Shift + Enter` Zen · `Shift + F` Finder ·
`Shift + W` nvim · `Shift + N` quick notes · `Shift + D` lazydocker · `Shift + A` NeoHtop · `Shift + G` Telegram

`Alt + Tab` cycles windows on the workspace.

**Menus** — `Space` launcher · `Shift + Space` omacos menu · `Shift + C` capture · `Shift + E` emoji ·
`Shift + V` clipboard history · `Shift + B` next wallpaper

**Help** — `Super + K` opens a searchable list of every binding (AeroSpace and tmux), generated
from the config itself, plus the shell aliases, tmux layouts (`ix`, `tdl`, `tsl`, …) and every
`omacos-*` command. `Shift + K` shows only the tmux keys, `omacos-keys shell` only the shell part.
`Esc` closes it.

## Re-homed keys (no `Super + Alt` / `Super + Ctrl`)

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
| `Super + Ctrl + Space` next background | `Super + Shift + B` |
| `Super + Shift + N` editor · `Super + Shift + W` Omawrite | `Super + Shift + W` editor · `Super + Shift + N` quick notes |

## Not portable

Sticky windows, scrolling layout, pseudo-tiling, gap toggling and
focus-follows-mouse have no AeroSpace equivalent.

## tmux

Omarchy's tmux config as-is: prefix `Ctrl + Space`, `Alt + Enter` / `Alt + Shift + Enter` split,
`Alt + 1-9` windows, `Alt + arrows` navigate, plus `Ctrl + h/j/k/l` pane navigation that is vim-aware.
`Super + Shift + K` lists them all.
