# Omarchy → macOS (tmux + yabai)

Port der Terminal-/Tiling-Konfiguration aus [omacom/omarchy](https://github.com/omacom/omarchy) auf macOS.

| Datei | Quelle bei Omarchy | Ziel auf dem Mac |
|---|---|---|
| `tmux/tmux.conf` | `config/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `zsh/omarchy.zsh` | `default/bash/aliases` + `tdl/tdlm/tsl` | `~/.config/zsh/omarchy.zsh` (in `.zshrc` sourcen) |
| `yabai/yabairc` | Hyprland dwindle + looknfeel | `~/.config/yabai/yabairc` |
| `skhd/skhdrc` | `default/hypr/bindings/tiling-v2` + `bindings.conf` | `~/.config/skhd/skhdrc` |
| `karabiner/meh-key.json` | – | Karabiner Complex Modification (Meh-Taste) |

## Installation

```sh
brew install tmux eza fzf bat zoxide jq neovim zsh-autosuggestions zsh-syntax-highlighting
brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd
brew install --cask ghostty      # oder kitty / alacritty / wezterm

mkdir -p ~/.config/{tmux,zsh,yabai,skhd}
cp tmux/tmux.conf   ~/.config/tmux/
cp zsh/omarchy.zsh  ~/.config/zsh/
cp yabai/yabairc    ~/.config/yabai/ && chmod +x ~/.config/yabai/yabairc
cp skhd/skhdrc      ~/.config/skhd/

echo 'source ~/.config/zsh/omarchy.zsh' >> ~/.zshrc

yabai --start-service
skhd  --start-service
```

**yabai Scripting Addition** (nötig für Space-Wechsel, Fenster in Spaces schieben, sticky):
SIP teilweise deaktivieren, dann `sudo yabai --load-sa` und den sudoers-Eintrag anlegen —
Anleitung: <https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection>.
Ohne SA funktionieren Fokus, Swap, Resize, Float, Zoom trotzdem.

**tmux-256color terminfo** (macOS-ncurses ist zu alt):
```sh
brew install ncurses
/opt/homebrew/opt/ncurses/bin/infocmp -x tmux-256color > /tmp/t.info && tic -x /tmp/t.info
```
Oder in `tmux.conf` auf `screen-256color` ausweichen.

## Terminal: Option als Alt

Omarchys tmux-Bindings hängen an `Alt` (Alt+Enter, Alt+1-9, Alt+Pfeile …). Das Terminal muss Option als Alt senden:

| Terminal | Einstellung |
|---|---|
| Ghostty | `macos-option-as-alt = true` in `~/.config/ghostty/config` |
| kitty | `macos_option_as_alt yes` |
| Alacritty | `[keyboard]` → `option_as_alt = "Both"` (bzw. `window.option_as_alt`) |
| iTerm2 | Profiles → Keys → Left/Right Option: `Esc+` |
| WezTerm | `send_composed_key_when_left_alt_is_pressed = false` |

`Alt+Shift+Enter` und `Ctrl+Alt+Shift+Pfeile` brauchen den kitty-keyboard-protocol (`extended-keys csi-u` ist gesetzt) – Ghostty, kitty und WezTerm können das.

## Modifier-Mapping (Karabiner)

| Omarchy | Mac | Wie |
|---|---|---|
| `Super` | **Hyper** (⇧⌘⌥⌃) | deine bestehende Caps-Lock-Regel, unverändert |
| `Super + Shift` | **Meh** (⌃⌥⇧) | neue Regel `karabiner/meh-key.json`: rechte ⌘ → Meh |
| `Alt` | `alt` (⌥) | echtes Option, damit tmux nichts abbekommt |
| `Super + Alt`, `Super + Ctrl` | – | nicht abbildbar (Hyper enthält ⌥ und ⌃ schon); wichtige Funktionen auf freie Tasten verlegt, siehe skhdrc-Kommentare "(verlegt)" |

Karabiner-Regel importieren: Karabiner-Elements → Complex Modifications → *Add your own rule* → Inhalt von `karabiner/meh-key.json` einfügen. Die Taste (`right_command`) im JSON kann beliebig getauscht werden (z.B. `right_option`, `tab` mit `to_if_alone`).

`Hyper + Space` bleibt Raycast – das entspricht Omarchys `Super + Space` (Omarchy-Menü) und wird in der skhdrc bewusst nicht gebunden.

### Verlegte Tasten (weil Super+Alt / Super+Ctrl fehlen)

| Omarchy | Mac |
|---|---|
| `Super + Alt + F` Full width | `Meh + Z` |
| `Super + Ctrl + F` Native fullscreen | `Hyper + Z` |
| `Super + Ctrl + Tab` Former workspace | `Hyper + 0` |
| `Super + Alt + S` Move to scratchpad | `Meh + S` |
| `Super + Shift + Alt + ←/→` Workspace auf Monitor | `Meh + Home / End` |
| `Super + Alt + G` Out of group | `Meh + G` |
| `Super + Alt + Tab` Next in group | `Hyper + /` |
| `Super + Alt + Return` Tmux terminal | `Meh + T` |
| `Super + Ctrl + T` btop | `Hyper + B` |
| `Super + Ctrl + L` Lock | `Meh + L` |
| `Super + Shift + G` Signal | `Meh + I` (G ist "out of group") |

Nicht belegt: Resize-Stufen (Alt/Ctrl), Move-without-follow, Fenster per Pfeil in Gruppe schieben, Private-Browser, WhatsApp.

## zsh-Plugins

`omarchy.zsh` lädt `zsh-autosuggestions` (History-Vorschläge, → annimmt) und `zsh-syntax-highlighting`, falls per brew installiert:

```sh
brew install zsh-autosuggestions zsh-syntax-highlighting
```

## Was sich nicht 1:1 übersetzen lässt

| Omarchy | Mac | Hinweis |
|---|---|---|
| Scrolling-Layout (`Super + L`) | `bsp ↔ stack` | yabai hat kein niri-artiges Scrolling |
| Gruppen (`Super + G`) | Space-Layout `stack` | yabai-Stacks sind Tabs für den ganzen Space; `⌥ ⌘ Pfeil` stackt gezielt ein Fenster |
| Pseudo tile (`Super + P`) | – | kein Äquivalent |
| Save/restore width (`Super + Home`) | `⌥ ⌘ Home` = balance | Ersatz |
| Scratchpad (`Super + S`) | Space 10 mit Label `scratch` | yabai kennt keinen special workspace |
| `Super + Space` Launcher | Raycast/Spotlight | eigener Hotkey |
| `omarchy-menu-tmux-keybindings` (`Prefix + ?`) | `tmux list-keys -N` im Popup | – |
| `open()` → `xdg-open` | entfällt | macOS hat `open` nativ |
| `sff` mit GNU `find -printf` | BSD `stat -f` | – |

## Aliase (unverändert aus Omarchy)

`ls lsa lt lta ff eff sff cd(zoxide) .. ... .... c cx cy d r t ic ix icx mup n g gcm gcam gcad`

`t` = `tmux attach || tmux new -s Work`. Die AI-Aliase setzen `opencode`, `claude`, `codex` voraus.

## tmux-Layouts (Nachbau)

`tdl`, `tdlm`, `tsl` sind nach dem Omarchy-Manual nachgebaut (Omarchys Originale liegen in `default/bash/fns`, das Verhalten ist: Editor links, KI rechts, Terminal darunter).

```
tdl cx          # nvim | claude / terminal
tdl c cx        # nvim | opencode + claude / terminal
tdlm cx         # ein Window pro Unterverzeichnis
tsl 4 cx        # 4 Panes, in jedem claude
```
