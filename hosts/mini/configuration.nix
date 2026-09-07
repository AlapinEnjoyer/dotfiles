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
      # Remove undeclared casks and their Homebrew-defined application data.
      cleanup = "zap";
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

  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;

  system.stateVersion = 6;
}
