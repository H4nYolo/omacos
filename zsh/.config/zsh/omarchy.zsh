# ~/.config/zsh/omarchy.zsh — omacos
# Omarchy's default/bash/aliases, running in zsh. Sourced from ~/.zshrc.
# Changes against the original are marked "# mac:".
# Needs: brew install eza fzf bat zoxide tmux neovim zsh-autosuggestions zsh-syntax-highlighting

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

# mac: BSD find has no -printf -> stat -f instead
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

# mac: Omarchy overrides open() with xdg-open; macOS has `open` natively -> dropped.

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
alias ic='tdl c'      # dev layout with opencode
alias ix='tdl cx'     # dev layout with claude code
alias icx='tdl c cx'  # dev layout with both
alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'
# n [files]  – nvim, current directory when called without arguments
n() { if [ "$#" -eq 0 ]; then command nvim . ; else command nvim "$@"; fi; }

# ---------------------------------------------------------------- Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# ---------------------------------------------------------------- Tmux layouts
# Re-creations of Omarchy's tdl / tdlm / tsl (default/bash/fns): editor left,
# AI agent right, terminal below. Must run inside a tmux session.

_tmux_require() {
  if [ -z "$TMUX" ]; then echo "Run this inside a tmux session (alias: t)"; return 1; fi
}

# tdl <ai> [<second_ai>]  – dev layout: editor | ai (+ second ai) / terminal
tdl() {
  _tmux_require || return 1
  local ai="${1:-cx}" ai2="$2" dir="$PWD"
  tmux new-window -c "$dir" -n "$(basename "$dir")"
  tmux send-keys "n" C-m                          # pane 1: editor (nvim)
  tmux split-window -h -l 45% -c "$dir"           # pane 2: AI on the right
  tmux send-keys "$ai" C-m
  if [ -n "$ai2" ]; then
    tmux split-window -v -c "$dir"                # pane 3: second AI
    tmux send-keys "$ai2" C-m
  fi
  tmux split-window -v -l 30% -c "$dir"           # terminal bottom right
  tmux select-pane -t 1
}

# tdlm <ai> [<second_ai>]  – one tdl window per subdirectory
tdlm() {
  _tmux_require || return 1
  local sub
  for sub in */; do
    [ -d "$sub" ] || continue
    ( cd "$sub" && tdl "$@" )
  done
}

# tsl <count> <command>  – swarm: <count> panes, each running <command>
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
# Autosuggestions: grey history hints (→ or End accepts, Ctrl+→ one word)
_brew_prefix="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}"
if [ -f "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  bindkey '^[[F' end-of-line          # End
  bindkey '^[[1;5C' forward-word      # Ctrl+→ : accept one word
fi
# Syntax highlighting has to be sourced last
if [ -f "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
unset _brew_prefix

# History: large, shared, no duplicates
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
