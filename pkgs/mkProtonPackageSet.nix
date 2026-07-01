# Creates a scoped package set containing multiple versions of Proton.
#
# Parameters:
#
#   1. A reference to the manifest.toml file.
#
#   2. A function to instantiate the helpers within the scope.
#      The `mkProton` helper MUST be added to the scope.
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
manifestSrc: init:
lib.makeScope newScope (
  self:
  let
    manifest = manifestsLib.load manifestSrc;
    supportedVersions = manifestsLib.versionsInManifestForSystem manifest system;

    createProtonPackage =
      verName: verInfo: variantName: variantDownload:
      self.mkProton {
        version = verName;
        variant = variantName;
        download = variantDownload;
      };

    # mkProtonPackage :: string -> attrset -> attrset of derivation
    createProtonVersions =
      verName: verInfo:
      let
        variants = manifestsLib.variantsInVersionForSystem verInfo system;
      in
      manifestsLib.forEachVariant variants (createProtonPackage verName verInfo);

    # pivotVariants :: attrset -> derivation & attrset
    # Returns the default variant with all other variants accessible as attributes.
    pivotVariants =
      variantPkgs:
      let
        defaultVariant = variantPkgs.default;
        otherVariants = lib.attrsets.filterAttrs (name: _: name != "default") variantPkgs;
      in
      defaultVariant // otherVariants;
  in
  (init self)
  // lib.attrsets.mapAttrs (
    verName: verInfo: pivotVariants (createProtonVersions verName verInfo)
  ) supportedVersions
)
