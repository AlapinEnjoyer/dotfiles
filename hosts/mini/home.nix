{ pkgs, user, ... }:

{
  imports = [
    ../../modules/terminal
    ../../modules/terminal/zsh/homebrew.nix
    ../../modules/programs/ghostty.nix
  ];

  home.username = user;
  home.homeDirectory = "/Users/${user}";

  programs.home-manager.enable = true;

  # These tools are installed on the mini, rather than every terminal host.
  home.packages = with pkgs; [
    exiv2
    neovim
    smartmontools
    talosctl
    tlrc
  ];

  programs.git = {
    enable = true;
    settings.user = {
      name = "AlapinEnjoyer";
      email = "120122957+AlapinEnjoyer@users.noreply.github.com";
    };
  };

  home.stateVersion = "26.05";
}
