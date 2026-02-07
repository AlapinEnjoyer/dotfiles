# ============================================================
# Powerlevel10k instant prompt (must stay near the top)
# ============================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================
# Zinit (plugin manager)
# ============================================================
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# ============================================================
# Completion system (load early on Arch)
# ============================================================
autoload -Uz compinit
compinit

# ============================================================
# Theme
# ============================================================
zinit ice depth=1
zinit light romkatv/powerlevel10k

# ============================================================
# Zsh plugins
# ============================================================
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# ============================================================
# Powerlevel10k config
# ============================================================
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ============================================================
# Keybindings
# ============================================================
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# ============================================================
# History
# ============================================================
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt auto_cd

# ============================================================
# Completion styling
# ============================================================
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu no
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always $realpath'

# ============================================================
# fzf
# ============================================================
eval "$(fzf --zsh)"

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
# Zoxide (better cd)
# ============================================================
eval "$(zoxide init zsh)"

zo() {
  local dir
  dir="$(zoxide query --interactive "$@")" || return

  [[ -n "$dir" ]] && cd "$dir"
}

# ============================================================
# Aliases
# ============================================================
alias ls='eza --color=always --icons=always'
alias ll='eza --color=always --long --git --icons=always'
alias la='eza --color=always --long --git --icons=always -a'
alias lt='eza --color=always --long --git --icons=always --tree --level=2'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias venv='source ./.venv/bin/activate'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gsw='git switch'

# Editors
alias v='nvim'

# ============================================================
# PATH
# ============================================================
export PATH="$HOME/.local/bin:$PATH"

# ============================================================
# Word deletion: stop at /
# ============================================================
slash-backward-kill-word() {
  local WORDCHARS="${WORDCHARS:s@/@}"
  zle backward-kill-word
}
zle -N slash-backward-kill-word
bindkey '^[^?' slash-backward-kill-word

eval "$(mise activate zsh)"
eval "$(uv generate-shell-completion zsh)"