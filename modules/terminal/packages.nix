{ pkgs, ... }:

{
  home.packages = with pkgs; [
    just
    bat
    fd
    ripgrep
    eza
    glow
  ];
}
