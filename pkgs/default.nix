{
  pkgs ? (import <nixpkgs> { system = builtins.currentSystem; }),
}: let
  mkProtonPackageSet = pkgs.callPackage ../lib/nix/proton-package-set.nix;
  in
{
  proton-cachyos-bin = pkgs.callPackage ../lib/nix/proton-package-set.nix {
    manifestFile = ./proton-cachyos-bin/manifest.toml;
    packageFile = ./proton-cachyos-bin/package.nix;
  };
}
