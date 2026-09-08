{ config, lib, pkgs, ... }:

{
  imports = [ ./fzf.nix ];

  home.file.".p10k.zsh".source = ../../../config/p10k.zsh;
  xdg.configFile."zsh/completions".source = ./completions;

  programs.zoxide = {
    enable = lib.mkDefault true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = lib.mkDefault true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "emacs";
    autocd = true;

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 5000;
      save = 5000;
      append = true;
      share = true;
      ignoreSpace = true;
      ignoreDups = true;
      ignoreAllDups = true;
      saveNoDups = true;
      findNoDups = true;
      ignorePatterns = [
        "ask"
        "ask *"
        "venv"
        "source */.venv/bin/activate"
        "source .venv/bin/activate"
      ];
    };

    completionInit = ''
      ZSH_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
      mkdir -p "$ZSH_CACHE_DIR"

      fpath=(
        "${config.xdg.configHome}/zsh/completions"
        "${config.home.profileDirectory}/share/zsh/site-functions"
        "${pkgs.zsh-completions}/share/zsh/site-functions"
        $fpath
      )

      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      zstyle ':completion:*' menu no
      if [[ -n "$LS_COLORS" ]]; then
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      fi

      autoload -Uz compinit
      compinit -d "$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"
    '';

    shellAliases = {
      vi = "nvim";
      v = "nvim";
      ls = "eza --color=always --icons=always";
      ll = "eza --color=always --long --git --icons=always";
      la = "eza --color=always --long --git --icons=always -a";
      lt = "eza --color=always --long --git --icons=always --tree --level=2";
      c = "clear";
      ".." = "cd ..";
      "..." = "cd ../..";
      venv = "source ./.venv/bin/activate";
      tf = "tofu";
      terraform = "tofu";
      tg = "terragrunt";
      opc = "opencode";
      vsc = "code .";
      pn = "pnpm";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --decorate";
      gsw = "git switch";
    };
    shellGlobalAliases.NE = "2>/dev/null";

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
        # Prefer Nix over inherited shims before mise activates selected tools.
        path=("$HOME/.local/bin" "${config.home.profileDirectory}/bin" $path)
      '')
      # fzf-tab must follow compinit (570) and precede autosuggestions (700).
      (lib.mkOrder 600 ''
        # The pinned source uses pure Zsh, avoiding native-module ABI differences.
        source ${pkgs.zsh-fzf-tab.src}/fzf-tab.plugin.zsh
      '')
      # Generate tool completions after Home Manager's mise activation (1000).
      (lib.mkOrder 1050 ''
        if (( $+commands[uv] )); then
          eval "$(uv generate-shell-completion zsh)"
        fi
        if (( $+commands[gh] )); then
          eval "$(gh completion -s zsh)"
        fi

        source ${./functions.zsh}
        alias -s md='glow -w 100'

        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ${../../../config/p10k.zsh}
      '')
    ];
  };
}
