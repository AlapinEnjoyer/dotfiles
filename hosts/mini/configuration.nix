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
      # Start non-destructively; tighten this after the inventory is stable.
      cleanup = "none";
    };

    brews = [
      "btop"
      "exiv2"
      "ncdu"
      "neovim"
      "nvtop"
      "smartmontools"
      "talosctl"
      "tlrc"
      "usage"
    ];

    casks = [
      "affinity"
      "anki"
      "appcleaner"
      "betterdisplay"
      "blender"
      "bruno"
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
