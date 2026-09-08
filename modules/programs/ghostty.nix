{ lib, pkgs, ... }:

{
  home.packages = [ pkgs.nerd-fonts.martian-mono ];

  programs.ghostty = {
    enable = lib.mkDefault true;
    package = lib.mkDefault (
      if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty
    );
    systemd.enable = lib.mkDefault false;
    # Keep Ghostty's automatic shell integration rather than adding shell hooks.
    enableBashIntegration = lib.mkDefault false;
    enableFishIntegration = lib.mkDefault false;
    enableZshIntegration = lib.mkDefault false;

    settings = lib.mapAttrs (_: lib.mkDefault) {
      confirm-close-surface = false;
      copy-on-select = "clipboard";
      theme = "Monokai Classic";
      background-opacity = 0.9;
      background-blur = true;
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration-features = "no-cursor, ssh-terminfo, ssh-env";
      font-family = "MartianMono Nerd Font";
      font-size = 18;
      term = "xterm-256color";
      keybind = [ "shift+enter=text:\\n" ]
        ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "cmd+backspace=text:\\x15";
      env = [ "OPENCODE_ENABLE_EXA=1" ];
    };
  };
}
