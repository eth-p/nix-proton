{
  # From nix-proton:
  makeProtonPackageSet,

  # Overrideable options:
  manifest ? ./manifest.toml,
  suffix ? "",
}:
makeProtonPackageSet manifest (self: {
  makeProton = self.callPackage ./makeProton.nix {
    suffix = if suffix == "" then "" else "-${suffix}";
  };
})
