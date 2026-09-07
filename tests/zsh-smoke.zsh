# Source in a fresh interactive shell after loading the configuration under test.
# All OpenCode calls below are stubbed; no model requests are made.
() {
  local tool function_name output
  local failures=0

  for tool in bat fd rg eza glow zoxide tmux just mise uv gh ask; do
    if [[ -z ${_comps[$tool]} ]]; then
      print -u2 -- "Missing completion: $tool"
      (( failures++ ))
    fi
  done

  for function_name in ask zo zcompreset p10k _fzf_comprun fzf-tab-complete fzf-tab-lscolors::from-mode _zsh_autosuggest_start _zsh_highlight; do
    if (( ! $+functions[$function_name] )); then
      print -u2 -- "Missing function: $function_name"
      (( failures++ ))
    fi
  done

  # Fzf handles its ** trigger, then delegates ordinary Tab to fzf-tab.
  if [[ $(bindkey '^I') != *fzf-completion* || $fzf_default_completion != fzf-tab-complete || $(bindkey '^R') != *fzf-history-widget* ]]; then
    print -u2 'Missing fzf Tab or Ctrl-R binding'
    (( failures++ ))
  fi
  if [[ $(bindkey '^P') != *history-search-backward* || $(bindkey '^N') != *history-search-forward* ]]; then
    print -u2 'History search bindings changed'
    (( failures++ ))
  fi
  if [[ $(bindkey '\ec') != *fzf-cd-widget* ]]; then
    print -u2 'Missing fzf Esc then c directory binding'
    (( failures++ ))
  fi
  if [[ $HISTSIZE != 5000 || $SAVEHIST != 5000 || ! -o sharehistory || ! -o histignorealldups ]]; then
    print -u2 'History configuration changed'
    (( failures++ ))
  fi
  if [[ $FZF_DEFAULT_OPTS != *'#282a36'* || $FZF_CTRL_T_OPTS != *'bat -n'* || $FZF_ALT_C_OPTS != *'eza --tree'* ]]; then
    print -u2 'Fzf colors or previews missing'
    (( failures++ ))
  fi
  if (( $+functions[zinit] )); then
    print -u2 'Zinit is still loaded'
    (( failures++ ))
  fi

  # Stub commands in a subshell, preserving the real interactive functions.
  if ! (
    opencode() { print -r -- "${(j:|:)@}"; }
    glow() {
      local line
      while IFS= read -r line; do print -r -- "$line"; done
    }

    ask >/dev/null 2>&1
    [[ $? == 2 ]] || exit 1
    ask --model >/dev/null 2>&1
    [[ $? == 2 ]] || exit 1
    ask -m --thinking prompt >/dev/null 2>&1
    [[ $? == 2 ]] || exit 1

    output=$(ask --model test/model --title 'two words' 'hello world')
    [[ $output == 'run|-m|test/model|--agent|ask|-c|--title|two words|hello world' ]] || exit 1

    opencode() { return 7; }
    ask 'test failure propagation' >/dev/null
    [[ $? == 7 ]] || exit 1

    fzf() { print -r -- "${(j:|:)@}"; }
    output=$(_fzf_comprun export)
    [[ $output == "--preview|eval 'echo \${}'" ]] || exit 1

    _arguments() { state=model; return 1; }
    _describe() {
      [[ $1 == model && $2 == _ask_models ]] || return 1
      print -r -- "${_ask_models[1]}"
    }
    autoload -Uz _ask
    output=$(_ask)
    [[ $output == "${_ask_models[1]}" ]] || exit 1
  ); then
    print -u2 'Custom function or completion tests failed'
    (( failures++ ))
  fi

  if (( failures )); then
    print -u2 -- "$failures shell checks failed"
    return 1
  fi
  print 'Shell smoke checks passed (no remote requests).'
}
