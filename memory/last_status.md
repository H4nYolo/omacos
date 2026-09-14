# omacos — last status

Read this first when resuming work on this repo (new session or after a context compact).
Keep it current: update it at the end of every working session.

**Last updated:** 2026-09-14 00:xx, end of session 2 (other-monitor workspace marker, Omarchy menu with Backspace = back, brew picker, clipboard, emoji, capture, help with aliases/tools, weather-location, Super+W quits last window, tdl <dir>, Sol hotkey conflict fixed, glow borders). Open work is in GitHub issues #5-#9.

## What this is

Omarchy look & feel on macOS. Public repo `H4nYolo/omacos`, cloned at `~/work/projects/omacos`,
MIT, English README. Every top-level dir is a GNU stow package mirroring `$HOME`
(`stow --target=$HOME --restow <pkg>`). `install.sh` + `Brewfile` reproduce the machine.
Issue tracker: GitHub Issues (`gh`). All four issues from session 1 are closed.

## Machine facts

Mac Studio (Mac15,14), macOS 26 Tahoe, US layout, Kinesis Advantage360 Pro (sends only
left_* modifiers — no right Cmd/Ctrl/Alt exist). Monitors as AeroSpace sees them:
`CG437K P` (4K, main, 3840x2160 pt) and `Studio Display` (3200x1800 pt, below the 4K in
screen coordinates). Displays never sleep before 3h (`displaysleep 180`).

## Architecture (all live and pushed)

| piece | how |
|---|---|
| Super+W/Q | `close --quit-if-last-window`: plain `close` left apps running without a window (looked like minimise) |
| Super key | Caps Lock held = ctrl+alt+cmd (Karabiner), tap = Escape. Super+Shift = Caps+Shift. **No Meh key.** Caps+Shift+, . / are swallowed by Karabiner (macOS sysdiagnose) — never bind them |
| Tiling | AeroSpace, `aerospace/.aerospace.toml`, config-version 2. Workspaces 1-5 + `scratch` on `CG437K P`, 6-10 on `Studio Display`; key 0 = workspace 10; `--auto-back-and-forth` on every workspace key (press again = go back). yabai and skhd are gone |
| Alt | belongs to tmux (Ghostty `macos-option-as-alt = true`); AeroSpace only binds Alt+Tab |
| Bar | sketchybar as Waybar clone (`sketchybar/`): workspaces (filled pill = focused, outlined pill = visible on the other monitor, via `aerospace list-workspaces --monitor all --visible`) · front app · mic/cam · brew updates · network · bluetooth · audio out · volume · cpu · mem · weather · clock. Menu bar hidden |
| Borders | JankyBorders 1.9 (`borders/`): `style=round width=6 active_color='glow(0xff7aa2f7)'`; plain and gradient variants commented in `bordersrc`. `borders <options>` re-configures the running instance live |
| Popups | a **second Ghostty instance** (`omacos-popupd`, config `ghostty/.config/ghostty/popup`, `initial-window=false`) owns a *quick terminal* panel (centred, monitor under the mouse, AeroSpace ignores it, fixed 1760x720 pt — Ghostty 1.3.1 ignores `quick-terminal-size`). `omacos-popup <launcher|keys|brew|audio|weather>` writes `~/.local/state/omacos/popup-request` and fires the instance's private global hotkey ctrl+alt+shift+cmd+F19 via System Events; `omacos-popup-run` execs the request inside. A running `brew upgrade` is never killed, only re-shown |
| Menu | Super+Shift+Space → `omacos-menu [route]`: fzf tree (Apps, Learn, Capture, Clipboard, Emoji, Toggle, Install, Remove, Update, Info, System), Esc = one level up. Direct keys: Super+Shift+C capture, +E `omacos-menu-emoji` (`~/.config/omacos/emoji.tsv` from gemoji), +V `omacos-clipboard` (daemon `omacos-clipboardd` polls `pbpaste` 1/s → `~/.local/state/omacos/clipboard/`, 200 entries), +K tmux keys. `omacos-pkg-install`/`-remove` = fzf over `brew formulae`/`casks` (resp. `brew leaves` + casks) with `brew info` preview. `omacos-capture <region|window|screen|record|record-mic|stop|text|qr|color>` (screencapture; OCR = `~/.config/omacos/ocr.swift` compiled to `~/.cache/omacos/omacos-ocr`; qrencode). Actions that need the panel gone run via `omacos-detach` (nohup + 0.4s). `omacos-fzf` = fzf with the Tokyo Night look, `omacos-notify` = display notification |
| Launcher | Super+Space → `omacos-launcher`: fzf list of all apps (+ Finder, CoreServices user apps, actions Screensaver/Lock/Sleep), most-launched first (`~/.local/state/omacos/launcher-history`), ctrl-x → Pearcleaner deep link |
| Help | Super+K → `omacos-keys [tmux|aerospace|shell]`: parses `.aerospace.toml` bindings + comments, tmux keys, every alias of the interactive zsh (`zsh -ic alias`, trailing comments in omarchy.zsh become descriptions), the documented layout functions, `~/.config/omacos/tools.tsv` (Brewfile tools, generated with `brew desc`) and every `omacos-*` script's second line, into fzf. Comments name the app so searches like "neohtop" hit |
| Uninstall | Pearcleaner (Sentinel + CLI `Pearcleaner uninstall-all <path>`). Raycast is gone. Sol still installed on plain Option+Space as calculator only; its window-management hotkeys are nulled in `sol/.config/sol/config.json` (issue #8 decides its fate) |
| Screensaver | `omacos-idle` (started by AeroSpace) → after `~/.config/omacos/idle-minutes` (5) idle → `omacos-screensaver`: one fullscreen Ghostty per monitor (`ghostty/.config/ghostty/screensaver`) running `omacos-screensaver-run` = random `tte` effects on `~/.config/omacos/screensaver.txt` (Omarchy logo). Any key / focus loss ends all. Skips while `PreventUserIdleDisplaySleep` is asserted. `tte` via `uv tool install terminaltexteffects` |
| Shell | OMZ + p10k kept, `zsh/.config/zsh/omarchy.zsh` = Omarchy aliases + `tdl`/`tdlm`/`tsl` (`ix` = `tdl cx`). zoxide replaced tiny-dc. Secrets + machine PATH in `~/.zshrc.local` (never committed) |
| tmux | Omarchy config, prefix Ctrl+Space (Ctrl+b secondary), + Ctrl+hjkl navigator. tmux 3.7c |
| Theme | Tokyo Night hard-wired everywhere; CaskaydiaMono Nerd Font; wallpaper downloaded by install.sh (gitignored). No theme switching yet |
| Started at login by AeroSpace | `after-startup-command`: `omacos-popupd`, `omacos-media-stream`, `omacos-idle`, `omacos-clipboardd`. sketchybar + borders are brew services |

## Gotchas learned the hard way

- **New file in `bin/`** → run `stow --target=$HOME --restow bin` or the binding silently does nothing (happened twice). Folded packages (tmux, zsh, sketchybar, ghostty, omacos) pick up new files automatically.
- `.gitignore` must never contain `*.local`: it swallowed `bin/.local` and no script was committed for hours.
- GUI apps launched from a tmux shell inherit `TERM`/`TMUX`. Pearcleaner then runs as a CLI and exits; tmux refuses to nest. Launch with `env -u TERM -u TERM_PROGRAM -u TMUX -u TMUX_PANE -u COLORTERM`.
- Ghostty asks "Allow Ghostty to execute ...?" whenever an argv entry is an existing file path (macOS turns it into an open-file event). Pass bare command names, never paths; run the binary directly, not via `open`.
- AeroSpace's `on-window-detected` title rules miss Ghostty windows (title set late). That is why popups use the quick terminal instead of floating windows.
- AeroSpace `list-windows --pid` needs `--monitor all`. New windows land on the focused monitor; fullscreen must be applied after *all* screensaver windows exist (a new window ends a workspace's fullscreen).
- Killing the screensaver with `pkill -f 'title=…'` killed my own shell; patterns are anchored to the Ghostty binary path now.
- System Events: `set position of w` on a variable reference fails (-10006); address `window 1` / `window "name"` directly.
- brew inside the sketchybar launchd service crashes on cask checks → the updates plugin counts `--formula` only. `updates=when_shown` is the default: hidden items never run their script → set `updates=on`.
- Karabiner sometimes does not reload after in-place edits: `launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server`.
- Sol's window-management hotkeys (`control+option+command+left/right` = move to next screen, `control+option+arrows` = halves) collided with Super+arrows: every keyboard focus change made the unfocused window vanish for ~80 ms (Sol moved it, AeroSpace put it back). All `resize_*`/`move_*` shortcuts are `null` in `sol/.config/sol/config.json` now. Found by recording the screen with `screencapture -v` and diffing frames with ffmpeg; `aerospace focus` from the CLI never showed it, only real key events (`osascript key code 123 using {control down, option down, command down}`).
- Accordion layout (Super+G, "toggle group") shows one window at a time and looks like fullscreen; `aerospace list-windows --workspace N --format '%{window-layout}'` reveals `h_accordion`. User knows now; keep the binding.
- Never run an interactive `zsh -i` inside a popup pipeline: it takes over the panel's tty and fzf quits at once. Source `~/.zshrc` non-interactively instead (see `omacos-keys`).
- fzf pickers inside the menu: `backward-eof:become(echo BACK)` + exit 3 = "go back one level"; menu functions must keep title/items `local` or the parent redraws with the child's entries.
- Glyphs typed into heredocs can get lost silently (four menu icons arrived as two spaces). Check with a codepoint dump; use Material Design glyphs (U+F0000+), they all render in CaskaydiaMono NF.
- `brew install` inside the popup shares brew's lock with any running `brew upgrade`; the popup's "never kill brew" rule also protects installs.
- Homebrew now requires `brew trust <tap>` for third-party taps (felixkratz/formulae, nikitabobko/tap).
- The sketchybar formula 2.24.0 fails to build on macOS 26 (its `curl` for the docs cannot verify TLS inside the build sandbox). Ignored via `~/.config/omacos/updates-ignore`; issue text drafted for `felixkratz/homebrew-formulae`, user submits it.

## Open / next

Tracked as GitHub issues (`gh issue list`): #5 theme switcher, #6 background switcher, #7 font
switcher (build in that order, "Kosmetik 8-10"), #8 decide on Sol, #9 verification checklist for
things a script cannot test (recording, OCR, paste, mic/camera, logout/login, upstream sketchybar
issue). Open a new issue for every new piece of work; close it with the commit that finishes it.

## Archive

Pre-omacos configs (tmux with TPM/Dracula, yabai, skhd, old Ghostty/zsh) are in `~/.config-archive/20260913-145052/`. Safe to delete once everything has survived a few logins.
