{
  description = "A home-manager module for creating local protonfixes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, self, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      homeManagerModules = rec {
        default = protonfixes;
        protonfixes = ./modules/protonfixes.nix;
      };

      legacyPackages = forEachSystem (
        system: import ./pkgs { pkgs = import nixpkgs { inherit system; }; }
      );

      # Modern `packages` are expected to be flat. Create it by flattening
      # the proton packages from the package sets in legacyPackages.
      packages = forEachSystem (
        system:
        let
          lib = import (nixpkgs + "/lib");
          isPackageSet = v: v ? callPackage && v ? overrideScope;
          isProton = v: lib.isDerivation v && (v.passthru.isProton or false);
          legacyPkgs = self.legacyPackages.${system};
          legacyPackageSets = lib.attrsets.filterAttrs (name: isPackageSet) legacyPkgs;
          extractProtons =
            pkgsetName: pkgset:
            let
              renamePackages = lib.attrsets.mapAttrs' (name: pkg: lib.nameValuePair "${pkgsetName}-${name}" pkg);
              protons = lib.attrsets.filterAttrs (_: isProton) pkgset;
            in
            renamePackages protons;
        in
        lib.attrsets.concatMapAttrs extractProtons legacyPackageSets
      );
    };
}
# https://github.com/ValveSoftware/steam-for-linux/issues/6310#issuecomment-511630263
