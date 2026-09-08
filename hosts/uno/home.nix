{ pkgs, ... }:

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

  # ROCm Core SDK remains Arch-owned; Uno's RX 9070 uses the TheRock path.
  home.sessionVariables = {
    ROCM_PATH = "/opt/rocm/core";
    ROCM_HOME = "/opt/rocm/core";
  };
  home.sessionPath = [
    "/opt/rocm/core/bin"
    "/opt/rocm/core/lib/llvm/bin"
  ];

  home.packages = with pkgs; [
    fastfetch
    nvtopPackages.amd
  ];

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
