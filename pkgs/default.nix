{
  pkgs ? (import <nixpkgs> { }),
  lib ? pkgs.lib,
  newScope ? pkgs.newScope,
}:
lib.recurseIntoAttrs (
  lib.makeScope newScope (self: {
    # Internal tools:
    nixProtonTools = self.callPackage ../tools { };

    # Helpers that can be overridden to change how Proton is fetched/built.
    fetchGitHubReleaseAsset = self.callPackage ./fetchGitHubReleaseAsset.nix { };
    makeProtonPackageSet = self.callPackage ./makeProtonPackageSet.nix { };
    makeProtonBinDerivation = self.callPackage ./makeProtonBinDerivation.nix { };
    changeProtonName = self.callPackage ./hooks/changeProtonName.nix { };

    # Proton package sets:
    proton-cachyos-bin = self.callPackage ./proton-cachyos-bin { };
    proton-cachyos-bin-x86-64-v3 = self.proton-cachyos-bin.override {
      manifest = ./proton-cachyos-bin/manifest-x86-64-v3.toml;
      suffix = "x86-64-v3";
    };

    proton-ge-custom-bin = self.callPackage ./proton-ge-custom-bin { };
  })
)
