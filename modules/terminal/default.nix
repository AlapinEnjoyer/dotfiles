{ pkgs, ... }:

{
  imports = [
    ./mise.nix
    ./opencode.nix
    ./tmux.nix
    ./zsh
  ];

  home.packages = with pkgs; [
    just
    bat
    fd
    ripgrep
    eza
    glow
    btop
    ncdu
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';
}
