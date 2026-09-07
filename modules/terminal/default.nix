{ pkgs, ... }:

{
  imports = [
    ./mise.nix
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
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';
}
