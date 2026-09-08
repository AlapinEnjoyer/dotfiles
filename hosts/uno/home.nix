{
  imports = [
    ../../modules/terminal
    ../../modules/programs/ghostty.nix
    ../../modules/linux/desktop.nix
    ../../modules/linux/session.nix
  ];

  home.username = "ayrton";
  home.homeDirectory = "/home/ayrton";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
