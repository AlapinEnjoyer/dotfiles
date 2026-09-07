bindkey '^P' history-search-backward
bindkey '^N' history-search-forward
bindkey '^U' backward-kill-line

slash-backward-kill-word() {
  local WORDCHARS="${WORDCHARS:s@/@}"
  zle backward-kill-word
}
zle -N slash-backward-kill-word
bindkey '^[^?' slash-backward-kill-word

zo() {
  local directory
  directory="$(zoxide query --interactive "$@")" || return
  [[ -n "$directory" ]] && cd "$directory"
}

zcompreset() {
  command rm -f -- "$ZSH_CACHE_DIR"/zcompdump-*(N)
  exec zsh
}

_fzf_comprun() {
  local command_name="$1"
  shift

  case "$command_name" in
    cd) fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'" "$@" ;;
    ssh) fzf --preview 'dig {}' "$@" ;;
    *) fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

_ask_models=(
  opencode/gpt-5.6-luna
  openai/gpt-5.6-luna
  opencode/deepseek-v4-flash-free
  github-copilot/gpt-5.6-luna
)

ask() {
  setopt localoptions pipefail
  local model="github-copilot/gpt-5.6-luna"

  if [[ "$1" == -m || "$1" == --model ]]; then
    if [[ -z "$2" || "$2" == -* ]]; then
      print -u2 'Usage: ask [-m|--model model] [options] prompt'
      return 2
    fi
    model="$2"
    shift 2
  fi

  if (( $# == 0 )); then
    print -u2 'Usage: ask [-m|--model model] [options] prompt'
    return 2
  fi

  opencode run -m "$model" --agent ask -c "$@" | glow -w 100 -
}
