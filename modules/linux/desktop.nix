{ config, lib, pkgs, ... }:

{
  xdg.enable = lib.mkDefault true;
  fonts.fontconfig.enable = lib.mkDefault true;

  # User-space dependencies only; Arch still owns services, PAM and the session.
  # Waybar 0.15.0 sends legacy workspace dispatches rejected by Lua Hyprland.
  home.packages = with pkgs; [
    hyprland
    hyprshot
    rofi
    wlogout
    kdePackages.dolphin
    blueman
    networkmanagerapplet
    hypridle
    hyprpaper
    brightnessctl
    playerctl
    pavucontrol
    wireplumber # wpctl client, not a Home Manager service
    bash
    coreutils
    findutils
    gnugrep
    gnused
    curl
    procps
    noto-fonts-color-emoji
    noto-fonts
    fira
    colloid-icon-theme
  ];

  # Pinned Hyprland 0.55.4 passes --verify-config with these native Lua sources.
  xdg.configFile = {
    "hypr/hyprland.lua".source = ../../config/hypr/hyprland.lua;
    "hypr/conf" = {
      source = ../../config/hypr/conf;
      recursive = true;
    };
    "hypr/hypridle.conf".source = ../../config/hypr/hypridle.conf;
    "hypr/hyprlock.conf".source = ../../config/hypr/hyprlock.conf;
    "hypr/hyprpaper.conf".source = ../../config/hypr/hyprpaper.conf;
    "fontconfig/conf.d/99-emoji.conf".source = ../../config/fontconfig/conf.d/99-emoji.conf;
    "backgrounds".source = ../../backgrounds/.config/backgrounds;
    "waybar" = {
      source = ../../config/waybar;
      recursive = true;
    };
    "wlogout/icons" = {
      source = ../../wlogout/.config/wlogout/icons;
      recursive = true;
    };
    # Do not link the entire rofi directory: background.rasi is runtime state.
    "wlogout/layout".source = ../../config/wlogout/layout;
    "wlogout/style.css".source = ../../config/wlogout/style.css;
    "rofi/config.rasi".source = ../../config/rofi/config.rasi;
    "rofi/colors.rasi".source = ../../config/rofi/colors.rasi;
  };

  home.file.".scripts/change-wallpaper.sh" = {
    source = ../../scripts/change-wallpaper.sh;
    executable = true;
  };

  # Seed a regular file for rofi before the first wallpaper IPC call succeeds.
  # Never overwrite existing state or follow a pre-existing (even dangling) link.
  home.activation.rofiBackground = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    background=${lib.escapeShellArg "${config.xdg.configHome}/rofi/background.rasi"}
    if [ ! -e "$background" ] && [ ! -L "$background" ]; then
      run ${pkgs.coreutils}/bin/install -m 644 \
        ${../../config/rofi/background.rasi} "$background"
    fi
  '';
}
