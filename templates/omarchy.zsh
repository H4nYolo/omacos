# ~/.config/zsh/omarchy.zsh
# Omarchy default/bash/aliases – macOS/zsh-Port
# In ~/.zshrc einbinden:  source ~/.config/zsh/omarchy.zsh
#
# brew install eza fzf bat zoxide tmux neovim
# Omarchy sourced diese Datei in bash; sie läuft unverändert in zsh.
# Änderungen ggü. Original sind mit "# mac:" markiert.

# ---------------------------------------------------------------- File system
if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

if [[ "$TERM" == "xterm-kitty" ]]; then
  alias ff="fzf --preview 'case \$(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
else
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
fi
alias eff='$EDITOR "$(ff)"'

# mac: BSD-find kennt kein -printf -> stat -f statt find -printf
sff() {
  if [ $# -eq 0 ]; then echo "Usage: sff <destination> (e.g. sff host:/tmp/)"; return 1; fi
  local file
  file=$(find . -type f -exec stat -f '%m%t%N' {} + | sort -rn | cut -f2- | ff) \
    && [ -n "$file" ] && scp "$file" "$1"
}

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
  alias cd="zd"
  zd() {
    if (( $# == 0 )); then
      builtin cd ~ || return
    elif [[ -d $1 ]]; then
      builtin cd "$1" || return
    else
      if ! z "$@"; then
        echo "Error: Directory not found"
        return 1
      fi
      printf "\U000F17A9 "
      pwd
    fi
  }
fi

# mac: Omarchy überschreibt open() mit xdg-open. macOS hat `open` nativ -> weglassen.

# ---------------------------------------------------------------- Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ---------------------------------------------------------------- Tools
alias c='opencode'
alias cx='printf "\033[2J\033[3J\033[H" && claude --permission-mode bypassPermissions'
alias cy='codex -s danger-full-access -a never'
alias d='docker'
alias r='rails'
alias t='tmux attach || tmux new -s Work'
alias ic='tdl c'
alias ix='tdl cx'
alias icx='tdl c cx'
alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'
n() { if [ "$#" -eq 0 ]; then command nvim . ; else command nvim "$@"; fi; }

# ---------------------------------------------------------------- Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# ---------------------------------------------------------------- Tmux layouts
# Nachbau der Omarchy-Layoutfunktionen (tdl / tdlm / tsl). Verhalten wie im
# Omarchy-Manual beschrieben: Editor links, KI rechts, Terminal darunter.
# Müssen innerhalb einer tmux-Session laufen.

_tmux_require() {
  if [ -z "$TMUX" ]; then echo "Run this inside a tmux session (alias: t)"; return 1; fi
}

# tdl <ai> [<second_ai>]  – Dev layout: editor | ai (+ second ai) / terminal
tdl() {
  _tmux_require || return 1
  local ai="${1:-cx}" ai2="$2" dir="$PWD"
  tmux new-window -c "$dir" -n "$(basename "$dir")"
  tmux send-keys "n" C-m                          # Pane 1: Editor (nvim)
  tmux split-window -h -l 45% -c "$dir"           # Pane 2: KI rechts
  tmux send-keys "$ai" C-m
  if [ -n "$ai2" ]; then
    tmux split-window -v -c "$dir"                # Pane 3: zweite KI
    tmux send-keys "$ai2" C-m
  fi
  tmux split-window -v -l 30% -c "$dir"           # Terminal unten rechts
  tmux select-pane -t 1
}

# tdlm <ai> [<second_ai>]  – ein tdl-Window pro Unterverzeichnis
tdlm() {
  _tmux_require || return 1
  local sub
  for sub in */; do
    [ -d "$sub" ] || continue
    ( cd "$sub" && tdl "$@" )
  done
}

# tsl <count> <command>  – Swarm: <count> Panes, alle starten <command>
tsl() {
  _tmux_require || return 1
  local count="$1"; shift
  local cmd="$*"
  if [ -z "$count" ] || [ -z "$cmd" ]; then echo "Usage: tsl <count> <command>"; return 1; fi
  tmux new-window -c "$PWD" -n "swarm"
  local i
  for (( i = 1; i < count; i++ )); do
    tmux split-window -c "$PWD"
    tmux select-layout tiled
  done
  for (( i = 1; i <= count; i++ )); do
    tmux send-keys -t "$i" "$cmd" C-m
  done
  tmux select-pane -t 1
}

# ---------------------------------------------------------------- zsh plugins
# brew install zsh-autosuggestions zsh-syntax-highlighting
# Autosuggestions = graue Vorschläge aus der History (→ oder Ende annimmt, Ctrl+→ wortweise)
_brew_prefix="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}"
if [ -f "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  bindkey '^[[F' end-of-line          # Ende
  bindkey '^[[1;5C' forward-word      # Ctrl+→ : nur ein Wort annehmen
fi
# Syntax-Highlighting muss als letztes geladen werden
if [ -f "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
unset _brew_prefix

# History-Verhalten wie gewohnt: groß, geteilt, ohne Duplikate
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
