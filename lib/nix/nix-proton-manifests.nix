{
  lib,
}:
let

  # Loads a manifest into its attrset equivalent.
  # Only supports loading from TOML files.
  #
  # load :: path -> manifest
  load =
    src:
    if lib.isPath src then
      lib.fromTOML (lib.readFile src)
    else
      throw "unsupported manifest source type: ${builtins.typeOf src}";

  # Removes any versions that do not support the specified platform.
  #
  # onlyForSystem :: manifest -> string -> manifest
  onlyForSystem =
    manifest: system:
    manifest
    // {
      version = lib.attrsets.filterAttrs (_: v: v.download ? ${system}) manifest.version;
    };

  # Creates an attrset for each download in the manifest for the specified
  # system.
  #
  # forEachDownload :: manifest -> string -> (download -> 'a) -> 'a
  forEachDownload =
    manifest: system: fn:
    lib.attrsets.mapAttrs (vName: vInfo: fn vName vInfo vInfo.download.${system}) manifest.version;

in
{
  inherit
    load
    onlyForSystem
    forEachDownload
    ;
}
