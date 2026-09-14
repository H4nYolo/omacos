# omacos

Omarchy's look and feel rebuilt on macOS: one keyboard-driven desktop out of AeroSpace, sketchybar, Ghostty, tmux and a set of small scripts. This glossary fixes the words used across scripts, configs, README and issues.

## Language

### Keys

**Super**:
The modifier that Omarchy binds everything to. On this machine it is Caps Lock held, which Karabiner turns into ctrl+alt+cmd; a tap is Escape.
_Avoid_: Hyper, Meh, Caps

**Super+Shift**:
The second layer. Omarchy's Super+Ctrl and Super+Alt bindings are re-homed here because the keyboard has no right-hand modifiers.

**Re-homed key**:
An Omarchy binding that lives on a different key here because the original is impossible or taken on macOS.

### Desktop

**Workspace**:
One of AeroSpace's ten numbered virtual desktops plus `scratch`. Workspaces 1-5 belong to the main monitor, 6-10 to the second.
_Avoid_: Space, desktop, tag

**Scratchpad**:
The `scratch` workspace, toggled in and out of view like Hyprland's special workspace.

**Group**:
AeroSpace's accordion container: several windows stacked, one visible. Omarchy calls the Hyprland equivalent a group.
_Avoid_: Accordion (in user-facing text), tab

**Dwindle**:
The split behaviour where each new window splits the previous one in the opposite direction, giving a spiral. AeroSpace does not do this itself; the watcher does.

**Bar**:
The sketchybar strip at the top: workspaces, focused app, system widgets. Replaces Omarchy's Waybar and hides the macOS menu bar.
_Avoid_: Statusbar, menubar

**Border**:
The JankyBorders outline around the focused window.

### Surfaces

**Popup**:
The floating terminal panel that scripts run in: Ghostty's quick terminal, owned by a second Ghostty instance, centred on the monitor under the mouse. Every fzf-based picker appears here.
_Avoid_: Quick terminal (implementation), floating window, overlay

**Panel** (planned, issue #10):
The native Swift window that replaces the Popup for the views that do not need a terminal. Same place on screen, same keys, no process start.
_Avoid_: Popup (for the native one), window, HUD

**View**:
One screen inside the Popup or Panel: Launcher, Menu, Emoji, Clipboard, Keys, Notes. A view is what a hotkey opens.
_Avoid_: Mode, page, picker (see below)

**Picker**:
A view whose only job is to choose one line and act on it (Launcher, Emoji, Clipboard, brew install/remove). Backspace on an empty query goes back to the Menu when the picker was opened from there.
_Avoid_: Selector, chooser, list

### Menu

**Launcher**:
The app picker on Super+Space: every installed app plus a few actions, most-launched first. Omarchy's Walker app list.
_Avoid_: App menu, Spotlight, Raycast

**Menu**:
The tree on Super+Shift+Space: Apps, Learn, Capture, Clipboard, Notes, Emoji, Toggle, Install, Remove, Update, Info, System. Omarchy's Super+Space menu.
_Avoid_: Root menu, main menu, command palette

**Entry**:
One line of the Menu: an icon, a label and either a command or a submenu.
_Avoid_: Item, option, action

**Route**:
The name of a Menu level that a hotkey can open directly (`capture`, `system`, ...).

### Actions

**Capture**:
Screenshots, screen recordings, OCR from a selection, QR code, colour picker: Omarchy's capture menu.
_Avoid_: Screenshot menu

**Notes**:
The one-file markdown scratch pad on Super+Shift+N, Raycast Notes' replacement.
_Avoid_: Scratchpad (that is the workspace), journal

**Keys**:
The searchable list of every binding, alias, tool and omacos command on Super+K.
_Avoid_: Help, cheatsheet, keybindings view

**Screensaver**:
The terminal animation shown on idle, one fullscreen Ghostty per monitor.

### Packaging

**Package** (stow):
One top-level directory of the repo, mirroring `$HOME`, linked in with GNU stow.
_Avoid_: Module, dotfile set

**Package** (brew):
A Homebrew formula or cask. Say "formula" or "cask" when it matters.

**Tool**:
A command-line program from the Brewfile, listed with its description in the Keys view.
