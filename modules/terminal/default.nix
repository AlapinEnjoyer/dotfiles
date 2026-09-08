{ pkgs, ... }:

{
  imports = [
    ./mise.nix
    ./opencode
    ./tmux.nix
    ./zsh
  ];

  home.packages = with pkgs; [
    just
    bat
    fd
    ripgrep
    eza
    glow
    btop
    ncdu
    jq
    gh
    ffmpeg
    opentofu
    terragrunt
    neovim
    viu
    tealdeer
    wget
  ];

  # Multi-user Nix installs its daemon client outside the user profile.
  home.sessionPath = [
    "$HOME/.local/bin"
    "/nix/var/nix/profiles/default/bin"
  ];

  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';
}
