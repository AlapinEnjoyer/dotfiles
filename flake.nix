{
  description = "Alapin's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = { nixpkgs, home-manager, darwin, nix-homebrew, ... }:
    {
      darwinConfigurations."ayrton@mini" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          user = "ayrton";
        };
        modules = [
          ./modules/darwin/defaults.nix
          ./hosts/mini/configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          {
            # Nix is already installed and maintained by Determinate.
            nix.enable = false;
          }
        ];
      };

      homeConfigurations."ayrton@mini" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./hosts/mini/home.nix ];
      };
    };
}
