{ lib, ... }:

let
  preview = "if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi";
in
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    colors = {
      fg = "#f8f8f2";
      bg = "#282a36";
      hl = "#bd93f9";
      "fg+" = "#f8f8f2";
      "bg+" = "#44475a";
      "hl+" = "#bd93f9";
      info = "#ffb86c";
      prompt = "#50fa7b";
      pointer = "#ff79c6";
      marker = "#ff79c6";
      spinner = "#ffb86c";
      header = "#6272a4";
    };
    fileWidgetOptions = [ "--preview '${preview}'" ];
    changeDirWidgetOptions = [ "--preview 'eza --tree --color=always {} | head -200'" ];
  };

  programs.zsh.initContent = ''
    show_file_or_dir_preview=${lib.escapeShellArg preview}
    zstyle ':fzf-tab:complete:(cd|z):*' fzf-preview 'eza --tree --color=always $realpath | head -200'
  '';
}
