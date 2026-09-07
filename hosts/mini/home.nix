{
  imports = [
    ../../modules/terminal
    ../../modules/darwin
  ];

  # MUST match the local macOS account, not the flake's public label.
  home.username = "ayrton";
  home.homeDirectory = "/Users/ayrton";

  home.stateVersion = "26.05";
}
