{
  pkgs ? (import <nixpkgs> { }),
  lib ? pkgs.lib,
  newScope ? pkgs.newScope,
}:
lib.makeScope newScope (self: {
  # Helpers that can be overridden to change how Proton is fetched/built.
  # See project README for examples.
  fetchGitHubReleaseAsset = self.callPackage ./fetchGitHubReleaseAsset.nix { };
  makeProtonPackageSet = self.callPackage ./makeProtonPackageSet.nix { };
  extendWithProtonPackages = self.callPackage ./extendWithProtonPackages.nix { };

  # Proton package sets:
  proton-cachyos-bin = self.callPackage ./proton-cachyos-bin { };
  proton-cachyos-bin-x86-64-v3 = self.proton-cachyos-bin.override {
    manifest = ./proton-cachyos-bin/manifest-x86-64-v3.toml;
    suffix = "x86-64-v3";
  };
})
