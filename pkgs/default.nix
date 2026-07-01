{
  pkgs ? (import <nixpkgs> { }),
  lib ? pkgs.lib,
  newScope ? pkgs.newScope,
}:
lib.makeScope newScope (self: {
  # Helpers that can be overridden to change how Proton is fetched/built.
  # See project README for examples.
  fetchGitHubReleaseAsset = self.callPackage ./fetchGitHubReleaseAsset.nix { };
  mkProtonPackageSet = self.callPackage ./mkProtonPackageSet.nix { };

  # Proton package sets:
  proton-cachyos-bin = self.callPackage ./proton-cachyos-bin { };
})
