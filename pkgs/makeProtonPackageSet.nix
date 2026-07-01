# Creates a scoped package set containing multiple versions of Proton.
#
# The `init` function must return at least two attributes:
#
#   manifest: A path to the manifest of Proton versions.
#   makeProton: A function creating a derivation for a Proton version.
#
{
  pkgs,
  lib,

  newScope, # inherit from parent scope
}:
let
  manifestsLib = pkgs.callPackage ../lib/nix/nix-proton-manifests.nix { };
  system = pkgs.stdenv.hostPlatform.system;
in
init:
(lib.makeScope newScope init).overrideScope (
  final: prev:
  let
    manifest = manifestsLib.onlyForSystem (manifestsLib.load final.manifest) system;

    createProtonPackage =
      verName: verInfo: download:
      prev.makeProton {
        version = verName;
        download = download;
      };

  in
  manifestsLib.forEachDownload manifest system createProtonPackage
)
