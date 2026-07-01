{
  pkgs,

  manifestFile,
  packageFile,
}:
let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;
  manifest = (lib.fromTOML (lib.readFile manifestFile));
  versions = manifest.version;
  traceMe = x: builtins.trace x x;

  # versionsForSystem :: string -> attrset
  versionsForSystem =
    system: lib.attrsets.filterAttrs (_: verInfo: verInfo.download ? ${system}) versions;
in
lib.makeScope pkgs.newScope (
  self:
  let
    # mkProtonPackage :: string -> string -> attrset -> derivation
    mkProtonPackage =
      verName: variant: dlInfo:
      self.callPackage packageFile {
        protonVersion = verName;
        protonVariant = variant;
        downloadInfo = dlInfo;
      };

    # mkProtonPackage :: string -> attrset -> attrset of derivation
    mkProtonPackagesForVersion =
      verName: verInfo:
      lib.attrsets.mapAttrs' (variant: dlInfo: {
        name = variant;
        value = mkProtonPackage verName variant dlInfo;
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
  lib.attrsets.mapAttrs' (verName: verInfo: {
    name = verName;
    value = pivotVariants (mkProtonPackagesForVersion verName verInfo);
  }) (traceMe (versionsForSystem system))
)
