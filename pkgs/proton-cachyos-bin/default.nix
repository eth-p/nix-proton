# Boilerplate for nix-proton's mkProtonPackageSet.
{ mkProtonPackageSet }:
mkProtonPackageSet ./manifest.toml (self: {
  mkProton = self.callPackage ./mkProton.nix { };
})
