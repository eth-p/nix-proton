{
  makeProtonPackageSet,

  manifest ? ./manifest.toml,
  suffix ? "",
}:
makeProtonPackageSet (self: {
  manifest = manifest;
  makeProton = self.callPackage ./makeProton.nix {};

  overrideProtonManifest =
    {
      manifest,
    }:
    self.overrideScope (final: prev: {
      manifest = "abcdef";
    });
})
