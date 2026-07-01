# Manifest structure:
#
# {
#   # Latest version number.
#   latest.version = "11.0-20260506";
#
#   # Describes a version of Proton.
#   version.${version} = {
#     systems = ["x86_64-linux"];
#   };
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

  # Returns a list of versions in the provided manifest.
  #
  # versionsList :: attrset -> [string]
  versionsList = manifest: lib.attrsets.attrNames manifest.version;

  #
  getVersion = manifest: version: manifest.version.${version};
in
{
  inherit load versionsList getVersion;
}
