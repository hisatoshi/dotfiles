export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/home/zoe/app:$PATH"
export PATH="/home/zoe/bin:$PATH"

eval "$(sheldon source)"

# Completion: Prezto-like menu selection
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
eval "$(dircolors -b)"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" 'ma=30;46'
eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# python
# source ~/.python/3.13/bin/activate

# Auto-start tmux on login, attach to existing session if available
if command -v tmux &>/dev/null && [[ -z "$TMUX" && -z "$VSCODE_PID" ]]; then
  cd ~
  if tmux has-session 2>/dev/null; then
    exec tmux attach-session
  else
    exec tmux new-session
  fi
fi

