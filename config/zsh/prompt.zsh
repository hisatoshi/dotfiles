# Sorin-like prompt (customized)
autoload -Uz vcs_info
setopt prompt_subst

precmd() {
  vcs_info

  # Sorin-style path shortening (requires extended_glob for (#m))
  setopt local_options extended_glob
  local pwd="${PWD/#$HOME/~}"
  if [[ "$pwd" == (#m)[/~] ]]; then
    _prompt_pwd="$MATCH"
    unset MATCH
  else
    _prompt_pwd="${${${${(@j:/:M)${(@s:/:)pwd}##.#?}:h}%/}//\\%/%%}/${${pwd:t}//\\%/%%}"
  fi
}

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '%F{green}●'
zstyle ':vcs_info:git:*' unstagedstr '%F{red}●'
zstyle ':vcs_info:git:*' formats '%F{cyan}%b%c%u%f'
zstyle ':vcs_info:git:*' actionformats '%F{cyan}%b%f|%F{magenta}%a%c%u%f'

PROMPT='%F{blue}${_prompt_pwd}%f %(?.%F{green}.%F{red})❯%f '
RPROMPT='${vcs_info_msg_0_}'
