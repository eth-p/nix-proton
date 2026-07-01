{
  description = "A home-manager module for creating local protonfixes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
      ];
      forEachSystem = fn: nixpkgs.lib.genAttrs systems (system: fn (import nixpkgs { inherit system; }));
    in
    {
      homeManagerModules = rec {
        default = protonfixes;
        protonfixes = ./modules/protonfixes.nix;
      };

      legacyPackages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
    };
}
# https://github.com/ValveSoftware/steam-for-linux/issues/6310#issuecomment-511630263
