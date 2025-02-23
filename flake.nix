{
  description = "nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # pinned versions
    nixpkgs-poetry-1_8_5.url =
      "github:nixos/nixpkgs/c792c60b8a97daa7efe41a6e4954497ae410e0c1";
    nixpkgs-rancher-2_7_0.url =
      "github:NixOS/nixpkgs/976fa3369d722e76f37c77493d99829540d43845";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

  };
  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew
    , homebrew-core, homebrew-cask, homebrew-bundle, nixpkgs-poetry-1_8_5
    , nixpkgs-rancher-2_7_0, neovim-nightly-overlay, ... }@inputs:
    let
      username = "mattiassjodin";
      system = "aarch64-darwin";
      hostname = "Mattiass-MacBook-Pro-2";
      inherit (self) outputs;
    in {
      # Build darwin flake using:
      # darwin-rebuild switch --flake ~/nix
      darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
        system = system;
        specialArgs = { inherit inputs username; };
        modules = [
          # `nix-darwin` config
          ./modules/darwin/default.nix
          ./modules/darwin/system.nix

          # `home-manager` config
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home;
            home-manager.extraSpecialArgs = { inherit inputs username; };
          }
          # `nix-homebrew` config
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = username;

              # Optional: Declarative tap management
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;

              };
              # Optional: Enable fully-declarative tap management
              #
              # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
              mutableTaps = false;
            };
          }
        ];
      };
    };
}
