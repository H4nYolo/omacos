#!/usr/bin/env bash
# omacos installer — Omarchy look & feel on macOS.
#
#   ./install.sh            full run: brew bundle, macOS defaults, stow, services
#   ./install.sh --no-brew  skip brew bundle
#
# Idempotent: re-running only re-links and re-applies settings.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIVE="$HOME/.config-archive/$(date +%Y%m%d-%H%M%S)"
PACKAGES=(aerospace karabiner tmux zsh ghostty sketchybar borders nvim git sol omacos bin)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- 1. Homebrew ---------------------------------------------------------------
if [[ "${1:-}" != "--no-brew" ]]; then
  if ! command -v brew >/dev/null; then
    echo "Homebrew is required: https://brew.sh" >&2
    exit 1
  fi
  log "brew bundle"
  brew bundle --file="$REPO/Brewfile"
fi

# --- 2. macOS defaults ----------------------------------------------------------
log "macOS defaults"
# Hide the Apple menu bar: sketchybar takes its place at the top
defaults write NSGlobalDomain _HIHideMenuBar -bool true
osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true' || true
# No "Displays have separate Spaces" prompt games: AeroSpace manages workspaces itself
defaults write com.apple.spaces spans-displays -bool false
# Faster key repeat, like a Linux desktop
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
killall SystemUIServer 2>/dev/null || true

# --- 3. Move existing configs out of the way, then stow ------------------------
log "stow"
archive() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mkdir -p "$ARCHIVE"
    log "archiving $target -> $ARCHIVE/"
    mv "$target" "$ARCHIVE/"
  fi
}
archive "$HOME/.aerospace.toml"
archive "$HOME/.config/karabiner"
archive "$HOME/.config/tmux"
archive "$HOME/.tmux.conf"
archive "$HOME/.zshrc"
archive "$HOME/.config/zsh"
archive "$HOME/.config/ghostty"
archive "$HOME/.config/sketchybar"
archive "$HOME/.config/borders"
archive "$HOME/.config/nvim"
archive "$HOME/.config/git"

mkdir -p "$HOME/.config" "$HOME/.local/bin"
for pkg in "${PACKAGES[@]}"; do
  [[ -d "$REPO/$pkg" ]] || continue
  stow --dir="$REPO" --target="$HOME" --restow "$pkg"
done

# --- 4. Secrets file for zsh (never committed) ---------------------------------
if [[ ! -f "$HOME/.zshrc.local" ]]; then
  log "creating ~/.zshrc.local for secrets and machine-specific exports"
  cat > "$HOME/.zshrc.local" <<'LOCAL'
# ~/.zshrc.local — machine-specific exports and secrets. Not tracked by git.
LOCAL
fi

# --- 4b. terminaltexteffects for the screensaver ---------------------------------
if ! command -v tte >/dev/null; then
  log "installing terminaltexteffects"
  uv tool install terminaltexteffects >/dev/null
fi

# --- 5. tmux-256color terminfo --------------------------------------------------
if ! infocmp tmux-256color >/dev/null 2>&1; then
  log "installing tmux-256color terminfo"
  /opt/homebrew/opt/ncurses/bin/infocmp -x tmux-256color > /tmp/tmux-256color.info
  tic -x /tmp/tmux-256color.info
fi

# --- 6. Services ----------------------------------------------------------------
# GUI apps inherit this shell's environment via `open`. TERM/TMUX must not leak in:
# Pearcleaner switches to CLI mode when TERM is set, and tmux refuses to nest with TMUX set.
# Everything AeroSpace or Sol launches later inherits their environment, so start them clean.
launch() { env -u TERM -u TERM_PROGRAM -u TMUX -u TMUX_PANE -u COLORTERM open -a "$@"; }
log "services"
brew services start sketchybar >/dev/null || true
brew services start borders    >/dev/null || true
launch AeroSpace
sleep 3; aerospace reload-config || true
launch Karabiner-Elements
[[ -d /Applications/Sol.app ]] && launch Sol

# --- 7. Wallpaper (Omarchy's Tokyo Night default) --------------------------------
WALL="$REPO/themes/tokyo-night/wallpaper.jpg"
if [[ ! -f "$WALL" ]]; then
  log "downloading wallpaper"
  curl -fsSL -o "$WALL.webp" https://raw.githubusercontent.com/basecamp/omarchy/HEAD/themes/tokyo-night/backgrounds/0-winding-road.webp
  sips -s format jpeg "$WALL.webp" --out "$WALL" >/dev/null && rm -f "$WALL.webp"
fi
log "wallpaper"
osascript -e "tell application \"System Events\" to set picture of every desktop to \"$WALL\""

log "done — log out and back in (or restart AeroSpace) if the menu bar is still visible"
