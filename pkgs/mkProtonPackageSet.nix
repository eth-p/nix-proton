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
  manifestsLib = import ../lib/nix/nix-proton-manifests.nix { inherit lib; };
  system = pkgs.stdenv.hostPlatform.system;
in
manifestSrc: init:
lib.makeScope newScope (
  self:
  let
    manifest = manifestsLib.load manifestSrc;
    versions = manifest.version;

    # versionsForSystem :: string -> attrset
    versionsForSystem =
      system: lib.attrsets.filterAttrs (_: verInfo: verInfo.download ? ${system}) versions;

    # mkProtonPackage :: string -> attrset -> attrset of derivation
    mkProtonPackagesForVersion =
      verName: verInfo:
      lib.attrsets.mapAttrs' (variant: dlInfo: {
        name = variant;
        value = self.mkProton {
          version = verName;
          variant = variant;
          download = dlInfo;
        };
      }) verInfo.download.${system};

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
  // lib.attrsets.mapAttrs' (verName: verInfo: {
    name = verName;
    value = pivotVariants (mkProtonPackagesForVersion verName verInfo);
  }) (versionsForSystem system)
)
