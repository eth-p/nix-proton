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

      normalizeName = name: lib.strings.replaceStrings [ "." ] [ "_" ] name;
      nameNormalizedProtonPackages = lib.attrsets.mapAttrs' (
        name: pkg: lib.nameValuePair (normalizeName name) pkg
      ) protonPackages;
    in
    nameNormalizedProtonPackages
    // {
      latest = protonPackages."${manifest.proton.latest}".overrideAttrs (oldAttrs: {
        protonDirName = "${manifest.proton.variant}-latest";
        protonDisplayName = "${manifest.proton.name} Latest";
      });
    }
  )
))
