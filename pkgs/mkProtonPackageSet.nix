{
  pkgs,
}:
let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  dir,
  manifestFile ? "${dir}/manifest.toml",
  manifest ? (lib.fromTOML (lib.readFile manifestFile)),
}:
lib.makeScope pkgs.newScope (
  self:
  let
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
  {
    mkProton = self.callPackage "${dir}/mkProton.nix" { };
  }
  // lib.attrsets.mapAttrs' (verName: verInfo: {
    name = verName;
    value = pivotVariants (mkProtonPackagesForVersion verName verInfo);
  }) (versionsForSystem system)
)
