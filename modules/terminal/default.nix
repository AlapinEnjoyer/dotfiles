{
  imports = [
    ./packages.nix
    ./mise.nix
    ./tmux.nix
    ./ghostty.nix
    ./zsh
  ];

  programs.home-manager.enable = true;
  home.sessionPath = [ "$HOME/.local/bin" ];

  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';
}
