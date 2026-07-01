# Creates a scoped package set containing multiple versions of Proton.
#
# The `init` function must return at least one attribute:
#
#   makeProton: A function creating a derivation for a Proton version.
#
{
  lib,

  stdenvNoCC,
  callPackage,
  newScope, # inherit from parent scope
}:
let
  manifestsLib = callPackage ../lib/nix/nix-proton-manifests.nix { };
  system = stdenvNoCC.hostPlatform.system;
in
manifestFile: init:
(lib.makeScope newScope (
  self:
  (init self)
  // (
    let
      manifest = manifestsLib.onlyForSystem (manifestsLib.load manifestFile) system;

      createProtonPackage =
        verName: verInfo: download:
        self.makeProton {
          version = verName;
          download = download;
        };

      protonPackages = manifestsLib.forEachDownload manifest system createProtonPackage;
    in
    protonPackages // {
      latest = protonPackages."${manifest.proton.latest}".overrideAttrs (oldAttrs: {
        protonDisplayName = "${manifest.proton.variant} Latest";
      });
    }
  )
))
