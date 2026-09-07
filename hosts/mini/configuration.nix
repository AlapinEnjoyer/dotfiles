{ user, ... }:

{
  system.primaryUser = user;

  # Home Manager owns completion initialization and Powerlevel10k.
  programs.zsh = {
    enableCompletion = false;
    enableBashCompletion = false;
    promptInit = "";
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = user;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      # Keep the cask inventory declarative without deleting application data.
      cleanup = "uninstall";
    };

    casks = [
      "affinity"
      "anki"
      "appcleaner"
      "betterdisplay"
      "blender"
      "discord"
      "docker-desktop"
      "geekbench"
      "godot"
      "obsidian"
      "stats"
      "tailscale-app"
      "visual-studio-code"
      "vlc"
      "zen"
      "zotero"
    ];
  };

  system.stateVersion = 6;
}
