# Menu, launcher, panel and popup

[← Manual](../README.md)

![Super + Shift + Space: the menu panel](../images/menu.jpg)

## The panel

`Super + Space` and `Super + Shift + Space` open the **native panel**, `omacos-shell` (`shell/`,
Swift, built by `install.sh`): one resident process that shows a compact floating window centred
on the monitor under the mouse — no process start, app icons from macOS, the app you were in keeps
focus. `Esc` or the same hotkey closes it, another view's hotkey switches in place, `Backspace`
on an empty query goes up a level, a click outside closes. Emoji (`Super + Shift + E`), clipboard
history (`Super + Shift + V`, with a preview column) and the keybindings list (`Super + K`, `Super + Shift + K`
for tmux only) are views of the same panel. Matching works like `fzf --exact`: every word you
type must appear, most-used entries first.

The same views also exist as fzf lists in the popup terminal (`omacos-launcher`, `omacos-menu`,
`omacos-menu-emoji`, `omacos-clipboard`, `omacos-keys`), which the panel opens for anything that
needs a terminal (brew pickers, upgrades, notes, the style pickers) and which keep working over SSH.

## The menu

Omarchy's menu as a tree. Typing searches everything below the current level, so `back` at the
top finds `Style › Background` without opening Style first; `Enter` on such a row acts as if you had
walked there. `Backspace` on an empty query goes up a level, also out of the pickers; `Esc` closes. The tree is data: `~/.config/omacos/menu.json` (icon, label, and one of `menu`,
`view`, `popup`, `run`; optional `state` and `when` shell commands for dynamic labels and
visibility). Edit it to add entries; `omacos-menu <route> --list` shows what a level resolves to.

- **Apps** — the launcher below
- **Learn** — keybindings (all / tmux / AeroSpace), the omacos repo, the Omarchy manual, AeroSpace, Ghostty and tmux docs
- **Capture** (`Super + Shift + C`) — screenshot of a region, window or screen (saved to `~/Pictures/Screenshots` and copied),
  screen recording with or without microphone (the entry turns into *Stop* while recording),
  text recognition (OCR) from a selection straight into the clipboard, the clipboard as a QR code, a colour picker that copies hex
- **Clipboard** (`Super + Shift + V`) — history of the last 200 text entries (`omacos-clipboardd`, started by AeroSpace);
  `Enter` pastes into the app that had focus, `ctrl-x` deletes, `alt-c` clears. Password managers' concealed entries are skipped
- **Emoji** (`Super + Shift + E`) — search by name or keyword, `Enter` pastes
- **Notes** (`Super + Shift + N`) — Raycast-Notes-style scratch pad: `~/notes/quick.md` (path in `~/.config/omacos/notes-file`) in nvim,
  cursor under a fresh timestamp in insert mode, every keystroke saved; `Esc` `:q` or just closing the popup keeps everything
- **Style** — theme, background, wallpaper pack and font pickers, see [Style](../style/README.md)
- **Toggle** — screensaver on idle, bar, borders, microphone mute, Wi-Fi, keep session awake
- **Install** — `omacos-pkg-install`: every Homebrew formula and cask in fzf with `brew info` as preview, `Tab` multi-select,
  `Enter` installs right there. Or the App Store
- **Remove** — `omacos-pkg-remove`: the same for what is installed (`brew leaves` + casks, unused dependencies go too), or an app via Pearcleaner
- **Update** — `brew upgrade`, `brew outdated`, macOS software update
- **Info** — time, weather and network as notifications, About
- **System** — screensaver, lock, sleep, logout, restart, shutdown

The OCR helper is Apple's Vision framework (`~/.config/omacos/ocr.swift`); `install.sh` compiles it once
into `~/.cache/omacos/omacos-ocr`, the capture menu does the same on first use if needed.

## Keep session awake

Remote desktops lock themselves when nothing happens in them — even while you are busy on the other
monitor, which also leaves you on "Away" in the chat everyone else is watching. **Toggle → Keep session
awake** asks how long it should last — a preset from 15 minutes to 8 hours, "until I stop it", or just type
`45`, `1h30`, `2h` — and then, every 60-120 seconds (random, so it does not look like a metronome), nudges
the window of the app named in `~/.config/omacos/awake-app` (`Citrix Viewer` by default) with a four-pixel
mouse move and an F15 press — invisible in Windows, but input as far as the session is concerned. Set it to
the length of the meeting you are about to sit in and it switches itself off afterwards.

`~/.config/omacos/jiggle.swift` (compiled once to `~/.cache/omacos/omacos-jiggle`) looks the app up by
name on every nudge, so a new pid every morning is fine, and takes its largest window from the window
list. Citrix Viewer only forwards input it receives while it is the active app, so the helper activates
it, waits for the activation to land, sends the events with `CGEventPostToPid` and hands the focus
straight back — about half a second, and the real mouse pointer never moves.

Half a second of borrowed focus would swallow whatever you type in that moment, so the daemon waits for
a pause first: it only nudges once this Mac has been idle for `awake-min-idle` seconds (the bar
icon turns into 󰏤 while it waits). Typing through a whole coffee break would still let the session lock, so after
`awake-deadline` seconds without a nudge it goes ahead anyway. While the app is frontmost the nudge is
skipped — you are using the session yourself then.

In a meeting the session usually sits on a workspace you are *not* looking at, which is the case it has to
survive: activating a window there makes AeroSpace pull its workspace onto that monitor for about two
tenths of a second before the focus — and the workspace — go back. Those nudges are therefore spaced as
far apart as `awake-deadline` allows, and `awake-hidden` = `skip` turns them off entirely if you would
rather have the lock than the flicker.

The bar shows how much of that time is left (󰅶 1h23, or 󰅶 23:05 in the last hour; with no end time it
counts down to the next nudge instead), and the menu entry carries the same number in brackets. Clicking
the bar item stops the whole thing, as does picking the menu entry again — and when the time is up it stops
itself with a notification. `omacos-awake status` prints the long version, `omacos-awake start 90` skips
the picker, `omacos-awake once` sends a single nudge for testing.

| file | meaning |
|---|---|
| `~/.config/omacos/awake-app` | app to keep awake (`Citrix Viewer`) |
| `~/.config/omacos/awake-interval` | `min max` seconds between nudges (`60 120`) |
| `~/.config/omacos/awake-min-idle` | seconds of local quiet before the focus is borrowed (`4`) |
| `~/.config/omacos/awake-deadline` | nudge anyway after this long without one (`210`) |
| `~/.config/omacos/awake-hidden` | `nudge` or `skip` while the window's workspace is not visible |
| `~/.config/omacos/awake-flags` | how the nudge is delivered: `--activate --key` by default, `--global` for apps that read the event stream through a tap, `--click`, `--dx <px>` |

## Launcher

![Super + Space: the launcher](../images/launcher.jpg)

The launcher is the Walker look-alike: every app from `/Applications`, `~/Applications` and the
system folders, most-launched first, plus a few actions (screensaver, lock, sleep). `Enter`
launches, `ctrl-x` opens the app in Pearcleaner with its leftovers listed for a clean uninstall,
`Esc` closes. Launch counts live in `~/.local/state/omacos/launcher-history`.

## The popup

Everything that needs a terminal runs in Ghostty's *quick terminal*: a floating panel, centred on the monitor
under the mouse, that AeroSpace never tiles, so it appears in place with no jumps. A second
Ghostty process started by AeroSpace (`omacos-popupd`, config `~/.config/ghostty/popup`) owns
it. `omacos-popup <request>` writes the request to `~/.local/state/omacos/popup-request`
and fires that process's private global hotkey (`ctrl+alt+shift+cmd+F19`, never typed by hand);
`omacos-popup-run` inside the panel then execs the requested script. When it exits, the panel
disappears. A running `brew upgrade` or an open notes pad is never killed, only re-shown.
Ghostty needs Accessibility for the global hotkey.

## Uninstalling apps

Uninstalling is Pearcleaner's job. Pick the app in the launcher with `ctrl-x`, or drag an app to
the Trash: Pearcleaner's Sentinel (enable it in Pearcleaner's settings) pops up and offers to
remove the leftovers. From a script: `/Applications/Pearcleaner.app/Contents/MacOS/Pearcleaner uninstall-all /Applications/Foo.app`.
Pearcleaner turns into that CLI whenever `TERM` is set in its environment, which is why
`install.sh` launches GUI apps with `TERM` and `TMUX` stripped (`omacos-open` does the same).

## Sol

[Sol](https://github.com/ospfranco/sol) stays around on `⌥ Space` as a calculator; drop it from the
Brewfile if you don't need it. Its built-in window management is switched off in `sol/.config/sol/config.json`:
Sol's default `⌃⌥⌘ ←/→` (move window to the next screen) is `Super + ←/→` here, and with both active every
focus change made the window jump.
