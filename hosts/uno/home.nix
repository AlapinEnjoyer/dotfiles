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

  # Same identity as the mini; preserves the existing default branch and editor.
  programs.git = {
    enable = true;
    settings.user = {
      name = "AlapinEnjoyer";
      email = "120122957+AlapinEnjoyer@users.noreply.github.com";
    };
    settings.init.defaultBranch = "main";
    settings.core.editor = "v";
  };
}
