{ config, lib, pkgs, nixgl, ... }:

let
  # Same Mesa/nixpkgs as the applications; no host-driver autodetection or ROCm.
  graphics = import nixgl {
    inherit pkgs;
    enable32bits = false;
    enableIntelX86Extensions = false;
  };
  nixGL = graphics.nixGLCommon graphics.nixGLMesa;
  profile = config.home.profileDirectory;
in
{
  home.packages = [ nixGL ];

  home.file.".local/bin/start-hyprland-nix" = {
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      set -eu
      . ${lib.escapeShellArg "${profile}/etc/profile.d/hm-session-vars.sh"}
      export PATH="${profile}/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin"
      export XDG_DATA_DIRS="${profile}/share:/usr/local/share:/usr/share"
      exec ${pkgs.hyprland}/bin/start-hyprland --path ${pkgs.hyprland}/bin/Hyprland "$@"
    '';
  };

  # SDDM does not discover home-profile sessions. Install these reviewed files
  # into /usr/local/share/wayland-sessions explicitly as an administrator.
  xdg.dataFile."wayland-sessions/hyprland-nix.desktop".text = ''
    [Desktop Entry]
    Name=Hyprland (Nix)
    Comment=Home Manager session with Nix Mesa
    Exec=${config.home.homeDirectory}/.local/bin/start-hyprland-nix
    TryExec=${config.home.homeDirectory}/.local/bin/start-hyprland-nix
    Type=Application
    DesktopNames=Hyprland
  '';

  xdg.dataFile."wayland-sessions/hyprland-arch-fallback.desktop".text = ''
    [Desktop Entry]
    Name=Hyprland (Arch fallback)
    Comment=Arch compositor and desktop utilities with the shared configuration
    Exec=/usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/bin /usr/bin/start-hyprland --no-nixgl --path /usr/bin/Hyprland
    TryExec=/usr/bin/start-hyprland
    Type=Application
    DesktopNames=Hyprland
  '';
}
