# Post-build hook for rewriting the internal tool name and display name
# specified inside the compatibilitytool.vdf file.
#
# To use the hook, add it to `nativeBuildInputs` and set the following
# attributes inside the derivation:
#
#   {
#     protonDisplayName = "Some Proton";
#     protonToolNAme = "some-proton";
#   }
{
  lib,
  makeSetupHook,
  writeScript,

  # Programs used by the hook:
  jq,

  # From nix-proton:
  nixProtonTools,
}:
makeSetupHook {
  name = "change-proton-name-hook";

  substitutions = {
    vdfConvert = lib.getExe nixProtonTools.vdf-convert;
    jq = lib.getExe jq;
  };
} ./changeProtonName.sh
