{
  pkgs ? (import <nixpkgs> { }),
}:
pkgs.lib.makeScope pkgs.newScope (self: {
  # Helpers that can be overridden to change how Proton is fetched/built.
  # See project README for examples.
  mkProtonPackageSet = self.callPackage ./mkProtonPackageSet.nix { };
  fetchGitHubReleaseAsset = self.callPackage ./fetchGitHubReleaseAsset.nix { };

  # Proton package sets:
  proton-cachyos-bin = self.callPackage ./proton-cachyos-bin { };
})
