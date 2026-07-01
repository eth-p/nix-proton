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
        lib.nameValuePair verInfo.package (
          self.makeProton {
            version = verName;
            download = download;
            protonDisplayName = "${manifest.proton.name} ${verName}";
          }
        );

      protonPackages = manifestsLib.forEachDownload' manifest system createProtonPackage;
      latestPackageSupportsCurrentSystem = manifest.version ? ${manifest.proton.latest};
      latestPackage = protonPackages."${manifest.version.${manifest.proton.latest}.package}";
    in
    protonPackages
    // (lib.optionalAttrs latestPackageSupportsCurrentSystem {
      latest =
        latestPackage.overrideAttrs
          (oldAttrs: {
            protonDirName = "${manifest.proton.variant}-latest";
            protonToolName = "${manifest.proton.variant}-latest";
            protonDisplayName = "${manifest.proton.name} Latest";
          });
    })
  )
))
