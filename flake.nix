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
    nixgl = {
      url = "github:nix-community/nixGL";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, darwin, nix-homebrew, nixgl, ... }:
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

      homeConfigurations."ayrton@uno" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit nixgl; };
        modules = [ ./hosts/uno/home.nix ];
      };

      homeConfigurations."ayrton@mini" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        extraSpecialArgs = {
          user = "ayrton";
        };
        modules = [ ./hosts/mini/home.nix ];
      };
    };
}
