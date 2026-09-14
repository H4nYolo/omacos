# Install

[← Manual](../README.md)

> Read the [disclaimer](../../README.md) first. `install.sh` rewires your keyboard, takes over
> window management, hides the menu bar, replaces your terminal and shell configs and starts
> background services. Only run it on a machine you are happy to reset.

```sh
git clone https://github.com/H4nYolo/omacos ~/work/projects/omacos
cd ~/work/projects/omacos
./install.sh
```

`install.sh` asks once, then runs `brew bundle`, hides the macOS menu bar, moves any existing
configs to `~/.config-archive/<timestamp>/`, links every package with GNU stow, builds the
native panel (`shell/`), compiles the OCR helper, starts the services and applies the Tokyo Night
theme (`OMACOS_THEME=<name> ./install.sh` for another one). Re-running it is safe.
`./install.sh --yes` skips the question, `--no-brew` skips `brew bundle`.

Each top-level directory is a stow package mirroring `$HOME`, so a single tool
can be linked on its own: `stow --target=$HOME aerospace`.

## What maps to what

| Omarchy piece | On the Mac |
|---|---|
| Hyprland tiling & bindings | [AeroSpace](https://github.com/nikitabobko/AeroSpace) (`aerospace/`) |
| Waybar | [sketchybar](https://github.com/FelixKratz/SketchyBar) (`sketchybar/`) |
| Window borders | [JankyBorders](https://github.com/FelixKratz/JankyBorders) (`borders/`) |
| `Super` key | Left Command via [Karabiner-Elements](https://karabiner-elements.pqrs.org) (`karabiner/`) |
| Walker (launcher, menus) | `omacos-shell` (`shell/`): a native Swift panel; fzf in a Ghostty popup for terminal tasks |
| tmux config | tmux (`tmux/`) |
| bash aliases, `tdl` / `tdlm` / `tsl` layouts | zsh (`zsh/`) |
| Alacritty / Ghostty | Ghostty (`ghostty/`) |
| LazyVim | LazyVim (`nvim/`) |
| btop | [NeoHtop](https://github.com/Abdenasser/neohtop) on `Super + Shift + A` |
| Clean app uninstall | [Pearcleaner](https://github.com/alienator88/Pearcleaner), with its Sentinel watching the Trash |
| Themes | Omarchy's palettes (`omacos/.config/omacos/themes/`), switched by `omacos-theme` |

## First run: permissions macOS will ask for

- **Karabiner-Elements** — Input Monitoring (and its driver extension under Login Items & Extensions)
- **AeroSpace** — Accessibility
- **Ghostty** — Accessibility (global hotkey of the popup)
- **Sol** — Accessibility (only if you keep it)
- **Pearcleaner** — Full Disk Access to find leftovers; turn on *Sentinel* in its settings

Grant them once, then restart the app that asked.

## Packages

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
| `bin` | `~/.local/bin/omacos-*` — every script; `omacos-keys shell` lists them with a one-liner each |
| `omacos` | `~/.config/omacos/` — menu tree, themes, templates, wallpaper packs, emoji and tool lists, screensaver text, idle minutes |
| `shell` | not stowed: SwiftPM package of the native panel, built into `~/.local/share/omacos/omacos-shell.app` |

Secrets and machine-specific exports go in `~/.zshrc.local`, the weather place in
`~/.config/omacos/weather-location`; neither is committed.

## Undo

Unstow the packages (`stow --target=$HOME -D <pkg>`), copy your old configs back from
`~/.config-archive/<timestamp>/`, `brew services stop sketchybar borders`, remove the
`after-startup-command` daemons by uninstalling AeroSpace, and delete the Karabiner rules. There
is no script for it.
