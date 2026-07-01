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
  # onlyForSystem :: string -> manifest -> manifest
  onlyForSystem =
    system: manifest:
    manifest
    // {
      version = lib.attrsets.filterAttrs (_: v: v.download ? ${system}) manifest.version;
    };

  # Creates an attrset for each download in the manifest for the specified
  # system.
  #
  # forEachDownload :: string -> (download -> 'a) -> manifest -> 'a
  forEachDownload =
    system: fn: manifest:
    lib.attrsets.mapAttrs (vName: vInfo: fn vName vInfo vInfo.download.${system}) manifest.version;

  # Creates an attrset for each download in the manifest for the specified
  # system.
  #
  # forEachDownload :: string -> (download -> nameValuePair 'a) -> manifest -> 'a
  forEachDownload' =
    system: fn: manifest:
    lib.attrsets.mapAttrs' (vName: vInfo: fn vName vInfo vInfo.download.${system}) manifest.version;

in
{
  inherit
    load
    onlyForSystem
    forEachDownload
    forEachDownload'
    ;
}
