# ~/.zshrc — omacos
# Powerlevel10k instant prompt — keep at the very top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="/opt/homebrew/bin:$PATH"
export EDITOR=nvim
export RIPGREP_CONFIG_PATH=~/.ignore

# Oh My Zsh + Powerlevel10k
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# Omarchy: aliases, zoxide cd, tmux layouts (tdl/tdlm/tsl), zsh plugins, history
source "$HOME/.config/zsh/omarchy.zsh"

# Personal aliases
alias ll='eza -lhaGF --icons --git'
alias rz='source ~/.zshrc'
alias tree='erd -I'
alias lg='lazygit'
alias tj='tjournal'
alias tm='task-master'
alias s='fd --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs /opt/homebrew/bin/nvim'

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Machine-specific PATH entries, completions and secrets — never committed.
[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local
