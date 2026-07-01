{
  lib,
}:
let
  # Manifest structure:
  #
  # {
  #   # Latest version number.
  #   latest.version = "11.0-20260506";
  #
  #   version.${version} = {
  #   }
  #
  #   version.${version}.download.${system}.${variant} = {
  #     release = "cachyos-11.0-20260506-slr";
  #     file = "proton-cachyos-11.0-20260506-slr-x86_64.tar.xz";
  #     sha256 = "sha256-Yy9Npm5J/O1x0DyHROPRkhREa27pHihqZvL4fRtNQ9A=";
  #   }
  # }


  load =
    src:
    if lib.isPath src then
      lib.fromTOML (lib.readFile src)
    else
      throw "unsupported manifest source type: ${builtins.typeOf src}";
in
{
  inherit load;
}
