# ============================================================
# Powerlevel10k instant prompt (must stay near the top)
# ============================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================
# Environment
# ============================================================
#eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(mise activate zsh)"

export PATH="$HOME/.local/bin:$PATH"

# ============================================================
# Zinit (plugin manager)
# ============================================================
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

zinit ice depth=1
zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# ============================================================
# Completions
# ============================================================
autoload -Uz compinit && compinit
eval "$(uv generate-shell-completion zsh)"

# ============================================================
# Powerlevel10k (prompt) config
# ============================================================
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ============================================================
# History
# ============================================================
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history
HISTDUP=erase
HISTORY_IGNORE='(ask|ask *)'

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt auto_cd

# ============================================================
# Keybindings
# ============================================================
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Word deletion: stop at /
slash-backward-kill-word() {
  local WORDCHARS="${WORDCHARS:s@/@}"
  zle backward-kill-word
}
zle -N slash-backward-kill-word
bindkey '^[^?' slash-backward-kill-word


# ============================================================
# Completion styling
# ============================================================
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu no
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always $realpath'

# ============================================================
# Shell integrations
# ============================================================
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"

# ============================================================
# FZF config
# ============================================================
export FZF_DEFAULT_OPTS='
--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
--color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
--color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
--color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
'

show_file_or_dir_preview='
if [ -d {} ]; then
  eza --tree --color=always {} | head -200
else
  bat -n --color=always --line-range :500 {}
fi
'

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)     fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export) fzf --preview "eval 'echo \${}'" "$@" ;;
    unset)  fzf --preview "eval 'echo \${}'" "$@" ;;
    ssh)    fzf --preview 'dig {}' "$@" ;;
    *)      fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# ============================================================
# Functions
# ============================================================
# Functions
zo() {
  local dir
  dir="$(zoxide query --interactive "$@")" || return
  [ -n "$dir" ] && cd "$dir"
}


# Ask function with optional model selection
_ask_models=(
  opencode/big-pickle
  opencode/gpt-5-nano
  opencode/mimo-v2-flash-free
  opencode/minimax-m2.5-free
  opencode/nemotron-3-super-free
  github-copilot/claude-sonnet-4.6
  github-copilot/claude-opus-4.6
  github-copilot/gemini-3-flash-preview
  github-copilot/gemini-3-pro-preview
  github-copilot/gemini-3.1-pro-preview
  github-copilot/gpt-4.1
  github-copilot/gpt-4o
  github-copilot/gpt-5-mini
  github-copilot/gpt-5.3-codex
  github-copilot/gpt-5.4
  myprovider/self
)

ask() {
  local model="github-copilot/gpt-4o"
  if [[ "$1" == -m ]]; then
    model="$2"
    shift 2
  fi
  opencode run -m "$model" --agent ask -c "$*" | glow -w 100 -
}

_ask_completion() {
  local state
  _arguments \
    '(-m)-m[model]:model:->model' \
    '*:prompt' && return
  case $state in
    model) _describe 'model' _ask_models ;;
  esac
}
compdef _ask_completion ask

# ============================================================
# Aliases
# ============================================================
# Aliases
alias ls='eza --color=always --icons=always'
alias ll='eza --color=always --long --git --icons=always'
alias la='eza --color=always --long --git --icons=always -a'
alias lt='eza --color=always --long --git --icons=always --tree --level=2'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias venv='source ./.venv/bin/activate'
alias tf='tofu'
alias terraform='tofu'
alias tg='terragrunt'
alias opc='opencode'
alias vsc='code .'
alias vi='nvim'

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gsw='git switch'

# Suffix Aliases
alias -s md='glow -w 100'

# Global aliases
alias -g NE='2>/dev/null'

# Editors
alias v='nvim'

# If you installed ROCm
export ROCM_PATH=/opt/rocm
