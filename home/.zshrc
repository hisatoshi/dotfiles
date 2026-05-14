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

#
bindkey -e

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

gs() {
  local branch base
  # lazygitと同じマージ先: main > master > develop
  for b in main master develop; do
    if git show-ref --verify --quiet "refs/heads/$b"; then
      base="$b"; break
    fi
  done
  base="${base:-HEAD}"

  branch=$( {
    git branch --merged "$base" | grep -v '^\*' | sed 's/^ *//' | while read -r b; do
      [[ "$b" == "$base" ]] && continue
      printf "\033[32m●\t%s\033[0m\n" "$b"
    done
    git branch --no-merged "$base" | sed 's/^ *//' | while read -r b; do
      printf "\033[33m○\t%s\033[0m\n" "$b"
    done
    git branch -r | grep -v HEAD | sed 's/^ *origin\///' | while read -r b; do
      git show-ref --verify --quiet "refs/heads/$b" && continue
      printf "\033[90m◇\t%s\033[0m\n" "$b"
    done
  } | awk -F'\t' '!seen[$2]++' \
    | fzf --ansi --prompt="switch> " --delimiter='\t' \
        --preview="git log --color=always --format='%C(auto)%h%d %s %C(dim)%cr' -30 {2} 2>/dev/null || git log --color=always --format='%C(auto)%h%d %s %C(dim)%cr' -30 origin/{2} 2>/dev/null" \
    | cut -f2) || return
  [[ -z "$branch" ]] && return
  git switch "$branch" 2>/dev/null || git switch --create "$branch" "origin/$branch"
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
