{
  pkgs,
  lib,
  newScope, # inherit from parent scope

  extendWithProtonPackages,

  manifest ? ./manifest.toml,
  suffix ? "",
}:
extendWithProtonPackages (
  lib.makeScope newScope (self: {
    manifest = manifest;
    makeProton = self.callPackage ./makeProton.nix {
      suffix = if suffix == "" then "" else "-${suffix}";
    };
  })
)
