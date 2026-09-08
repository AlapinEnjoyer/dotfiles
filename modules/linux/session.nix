{ config, lib, pkgs, nixgl, ... }:

let
  # Same Mesa/nixpkgs as the applications; Arch owns the AMD host stack and ROCm.
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
      export PATH="${profile}/bin:$HOME/.local/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin"
      export XDG_DATA_DIRS="${profile}/share:/usr/local/share:/usr/share"
      exec ${pkgs.hyprland}/bin/start-hyprland --path ${pkgs.hyprland}/bin/Hyprland "$@"
    '';
  };

  # SDDM does not discover home-profile sessions. It validates TryExec before
  # authentication as its own user, so use a system command there while Exec
  # remains the Home Manager launcher started after authentication as the user.
  xdg.dataFile."wayland-sessions/hyprland-nix.desktop".text = ''
    [Desktop Entry]
    Name=Hyprland (Nix)
    Comment=Home Manager session with Nix Mesa
    Exec=${config.home.homeDirectory}/.local/bin/start-hyprland-nix
    TryExec=/usr/bin/true
    Type=Application
    DesktopNames=Hyprland
  '';
}
