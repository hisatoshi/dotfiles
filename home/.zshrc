# 環境依存の事前処理の実行
[[ -f "${HOME}/.zshrc.pre.zsh" ]] && builtin source "${HOME}/.zshrc.pre.zsh"

export EDITOR=nvim
export VISUAL=nvim
export COLORTERM=truecolor

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/app:$PATH"
export PATH="$HOME/bin:$PATH"

# Rust
. $HOME/.cargo/env

# GO
export GOPATH=$HOME/go
export GOBIN=$HOME/go/bin
export PATH=$PATH:$(go env GOPATH)/bin

# moonbit
export PATH="$HOME/.moon/bin:$PATH"

# Plugin Maneger
eval "$(sheldon source)"

# Sorin-like prompt
source ~/.config/zsh/prompt.zsh

# Completion: Prezto-like menu selection
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
eval "$(dircolors -b)"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" 'ma=30;46'

# activate zoxide
eval "$(zoxide init zsh)"

# activate fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

zj() {
  # -l: 全候補, --score: スコア付き出力（例: "42.1 /path/to/dir"）
  # fzf: スコア列を隠してパスだけ見てもOK（--with-nth=2..）
  local dir
  dir=$(
    zoxide query -l --score \
    | awk '{score=$1; $1=""; sub(/^ /, ""); print score "\t" $0}' \
    | fzf --no-sort --tac --with-nth=2.. --prompt="zoxide> " \
          --header="Enter: 移動 / Ctrl-c: 中止" \
    | cut -f2-
  ) || return
  [ -n "$dir" ] && cd "$dir"
}

# Auto-start tmux on login, attach to existing session if available
if command -v tmux &>/dev/null && [[ -z "$TMUX" && -z "$VSCODE_PID" ]]; then
  cd ~
  if tmux has-session 2>/dev/null; then
    exec tmux attach-session
  else
    exec tmux new-session
  fi
fi

# 環境依存の事後処理の実行
[[ -f "${HOME}/.zshrc.post.zsh" ]] && builtin source "${HOME}/.zshrc.post.zsh"
