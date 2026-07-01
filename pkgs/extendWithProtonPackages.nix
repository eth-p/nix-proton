# Extends the initial package set to add Proton packages from a manifest file.
# The initial package set must have `manifest` and `makeProton` attributes.
{
  callPackage,
  stdenvNoCC,
}:
scope:
scope.overrideScope (
  _: prev:
  let
    manifestsLib = callPackage ../lib/nix/nix-proton-manifests.nix { };
    manifest = manifestsLib.onlyForSystem (manifestsLib.load prev.manifest) system;
    system = stdenvNoCC.hostPlatform.system;

    createProtonPackage =
      verName: verInfo: download:
      prev.makeProton {
        version = verName;
        download = download;
      };
  in
  manifestsLib.forEachDownload manifest system createProtonPackage
)
