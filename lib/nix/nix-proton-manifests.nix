# Manifest structure:
#
# {
#   # Latest version number.
#   latest.version = "11.0-20260506";
#
#   # Describes a version of Proton.
#   version.${version} = {};
#
#   # The download info. This is passed directly to the fetcher.
#   version.${version}.download.${system}.default = {};
#   version.${version}.download.${system}.${variant} = {};
# }
{
  lib,
}:
let

  # Loads a manifest into its attrset equivalent.
  # Only supports loading from TOML files.
  #
  # load :: path -> attrset
  load =
    src:
    if lib.isPath src then
      lib.fromTOML (lib.readFile src)
    else
      throw "unsupported manifest source type: ${builtins.typeOf src}";

  # Returns a set of versions in the provided manifest.
  #
  # versionsIn :: manifest -> attrset[versionInfo]
  versionsInManifest = manifest: manifest.version;

  # Returns a set of versions in the provided manifest that have builds for the
  # specified platform.
  #
  # versionsInForSystem :: manifest  -> string -> attrset[versionInfo]
  versionsInManifestForSystem =
    manifest: system:
    lib.attrsets.filterAttrs (ver: info: info.download ? ${system}) (versionsInManifest manifest);

  # Returns a list of systems that have builds of the provided version.
  #
  # systemsForVersion :: versionInfo -> [string]
  systemsForVersion = versionInfo: lib.attrsets.attrNames versionInfo.download;

  # Returns a list of variants for the provided version and platform.
  #
  # variantsInVersionForSystem :: versionInfo -> attrset[variantDownload]
  variantsInVersionForSystem = versionInfo: system: versionInfo.download.${system};

  # Runs the provided function for every provided version in the version set.
  # Use `versionsIn` or `supportedVersionsIn`.
  #
  # forEachVersion :: attrset[versionInfo] -> (string -> versionInfo -> any) -> attrset
  forEachVersion = versions: fn: lib.attrsets.mapAttrs fn versions;

  # Runs the provided function for every provided variant in the variant set.
  #
  # forEachVariant :: attrset[variantDownload] -> (string -> variantDownload -> any) -> attrset
  forEachVariant = variants: fn: lib.attrsets.mapAttrs fn variants;

in
{
  inherit
    load
    versionsInManifest
    versionsInManifestForSystem
    systemsForVersion
    variantsInVersionForSystem
    forEachVersion
    forEachVariant
    ;
}
