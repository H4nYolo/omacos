# omacos — last status

Read this first when resuming work on this repo (new session or after a context compact).
Keep it current: update it at the end of every working session.

**Last updated:** 2026-09-13 (session 2: other-monitor workspace marker in the bar)

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
| Super key | Caps Lock held = ctrl+alt+cmd (Karabiner), tap = Escape. Super+Shift = Caps+Shift. **No Meh key.** Caps+Shift+, . / are swallowed by Karabiner (macOS sysdiagnose) — never bind them |
| Tiling | AeroSpace, `aerospace/.aerospace.toml`, config-version 2. Workspaces 1-5 + `scratch` on `CG437K P`, 6-10 on `Studio Display`; key 0 = workspace 10; `--auto-back-and-forth` on every workspace key (press again = go back). yabai and skhd are gone |
| Alt | belongs to tmux (Ghostty `macos-option-as-alt = true`); AeroSpace only binds Alt+Tab |
| Bar | sketchybar as Waybar clone (`sketchybar/`): workspaces (filled pill = focused, outlined pill = visible on the other monitor, via `aerospace list-workspaces --monitor all --visible`) · front app · mic/cam · brew updates · network · bluetooth · audio out · volume · cpu · mem · weather · clock. Menu bar hidden |
| Borders | JankyBorders (`borders/`), Tokyo Night blue |
| Popups | a **second Ghostty instance** (`omacos-popupd`, config `ghostty/.config/ghostty/popup`, `initial-window=false`) owns a *quick terminal* panel (centred, monitor under the mouse, AeroSpace ignores it, fixed 1760x720 pt — Ghostty 1.3.1 ignores `quick-terminal-size`). `omacos-popup <launcher|keys|brew|audio|weather>` writes `~/.local/state/omacos/popup-request` and fires the instance's private global hotkey ctrl+alt+shift+cmd+F19 via System Events; `omacos-popup-run` execs the request inside. A running `brew upgrade` is never killed, only re-shown |
| Launcher | Super+Space → `omacos-launcher`: fzf list of all apps (+ Finder, CoreServices user apps, actions Screensaver/Lock/Sleep), most-launched first (`~/.local/state/omacos/launcher-history`), ctrl-x → Pearcleaner deep link |
| Help | Super+K → `omacos-keys`: parses `.aerospace.toml` bindings + comments and tmux keys into fzf. Comments name the app so searches like "neohtop" hit |
| Uninstall | Pearcleaner (Sentinel + CLI `Pearcleaner uninstall-all <path>`). Raycast is gone. Sol still installed on plain Option+Space (calculator/clipboard), optional |
| Screensaver | `omacos-idle` (started by AeroSpace) → after `~/.config/omacos/idle-minutes` (5) idle → `omacos-screensaver`: one fullscreen Ghostty per monitor (`ghostty/.config/ghostty/screensaver`) running `omacos-screensaver-run` = random `tte` effects on `~/.config/omacos/screensaver.txt` (Omarchy logo). Any key / focus loss ends all. Skips while `PreventUserIdleDisplaySleep` is asserted. `tte` via `uv tool install terminaltexteffects` |
| Shell | OMZ + p10k kept, `zsh/.config/zsh/omarchy.zsh` = Omarchy aliases + `tdl`/`tdlm`/`tsl` (`ix` = `tdl cx`). zoxide replaced tiny-dc. Secrets + machine PATH in `~/.zshrc.local` (never committed) |
| tmux | Omarchy config, prefix Ctrl+Space (Ctrl+b secondary), + Ctrl+hjkl navigator. tmux 3.7c |
| Theme | Tokyo Night hard-wired everywhere; CaskaydiaMono Nerd Font; wallpaper downloaded by install.sh (gitignored). No theme switching yet |
| Started at login by AeroSpace | `after-startup-command`: `omacos-popupd`, `omacos-media-stream`, `omacos-idle`. sketchybar + borders are brew services |

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
- Homebrew now requires `brew trust <tap>` for third-party taps (felixkratz/formulae, nikitabobko/tap).
- The sketchybar formula 2.24.0 fails to build on macOS 26 (its `curl` for the docs cannot verify TLS inside the build sandbox). Ignored via `~/.config/omacos/updates-ignore`; issue text drafted for `felixkratz/homebrew-formulae`, user submits it.

## Open / next

1. User: submit the sketchybar formula issue (`gh issue create -R felixkratz/homebrew-formulae …`, draft in `$TMPDIR/sketchybar-issue.md` — regenerate from the gotcha above if gone).
2. Verify the mic/camera indicator during a real call (`log stream --predicate 'eventMessage CONTAINS "attributions changed"'`); adjust `omacos-media-stream` if the wording differs.
3. First real logout/login: confirm AeroSpace brings up popupd, media-stream, idle; sketchybar/borders services; Ghostty may ask for Accessibility for the global hotkey.
4. Decide on Sol (keep on Option+Space or uninstall via launcher ctrl-x + Brewfile).
5. Optional: Omarchy-style theme switching (one command for Ghostty, sketchybar, borders, tmux, nvim, wallpaper).
6. Optional: remaining "doesn't hurt" cleanup candidates from closed issue #2 (Office apps, Final Cut, iMovie, Arc, Cursor, …) via Pearcleaner.

## Archive

Pre-omacos configs (tmux with TPM/Dracula, yabai, skhd, old Ghostty/zsh) are in `~/.config-archive/20260913-145052/`. Safe to delete once everything has survived a few logins.
