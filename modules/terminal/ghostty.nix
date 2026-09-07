{ pkgs, ... }:

{
  # Home Manager copies packaged fonts to ~/Library/Fonts/HomeManager on macOS.
  home.packages = [ pkgs.nerd-fonts.martian-mono ];

  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    systemd.enable = false;
    # Keep Ghostty's automatic shell integration rather than adding shell hooks.
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;

    settings = {
      confirm-close-surface = false;
      copy-on-select = "clipboard";
      theme = "Monokai Classic";
      background-opacity = 0.85;
      background-blur = true;
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration-features = "no-cursor, ssh-terminfo, ssh-env";
      font-family = "MartianMono Nerd Font";
      font-size = 18;
      keybind = [
        "cmd+backspace=text:\\x15"
        "shift+enter=text:\\n"
      ];
    };
  };
}
