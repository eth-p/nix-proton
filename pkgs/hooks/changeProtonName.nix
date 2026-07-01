# Fetcher for downloading prebuilt binary packages from GitHub.
{
  lib,
  makeSetupHook,
  writeScript,

  jq,

  # From nix-proton:
  nixProtonTools,
}:
makeSetupHook
  {
    name = "change-proton-name-hook";

    substitutions = {
      vdfConvert = lib.getExe nixProtonTools.vdf-convert;
      jq = lib.getExe jq;
    };
  }
  (
    writeScript "change-proton-name-hook.sh" ''
      # shellcheck disable=SC2016

      changeProtonToolName() {
        @vdfConvert@ to-json <"$1" |
          @jq@ --arg name "$2" '.compatibilitytools.compat_tools | to_entries | .[0].key = $name | from_entries' |
          @vdfConvert@ from-json >"$1.new"

        mv "$1.new" "$1"
      }

      changeProtonDisplayName() {
        @vdfConvert@ to-json <"$1" |
          @jq@ --arg name "$2" '.compatibilitytools.compat_tools |= (. | to_entries | .[0].value.display_name = $name | from_entries)' |
          @vdfConvert@ from-json >"$1.new"

        mv "$1.new" "$1"
      }

      _runProtonNameHooks() {
        if [[ -n "''${protonDisplayName:-}" ]]; then
          changeProtonDisplayName "proton/compatibilitytool.vdf" "$protonDisplayName"
        fi
        if [[ -n "''${protonToolName:-}" ]]; then
          changeProtonToolName "proton/compatibilitytool.vdf" "$protonToolName"
        fi
      }

      appendToVar postBuildHooks _runProtonNameHooks
    ''
  )
