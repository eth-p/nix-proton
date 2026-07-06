{
  fetchGitHubReleaseAsset,
  lib,

  # From nix-proton:
  makeProtonBinDerivation,

  # Overrideable options:
  suffix ? "",
}:
{
  version,
  download,

  protonDisplayName ? null,
  protonToolName ? null,
}:
makeProtonBinDerivation {
  pname = "proton-ge-bin${suffix}";
  version = version;

  src = fetchGitHubReleaseAsset (
    {
      repo = "GloriousEggroll/proton-ge-custom";
    }
    // download
  );

  # Options for changeProtonName hook:
  inherit protonDisplayName;
  inherit protonToolName;

  meta = {
    description = "Glorious Eggroll's Proton fork with improved compatibility and additional features.";
    homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
    platforms = lib.platforms.linux;
    sourceProvenance = lib.sourceTypes.binaryNativeCode;
    license = with lib.licenses; [
      bsd3 # https://github.com/GloriousEggroll/proton-ge-custom/blob/master/LICENSE.proton
    ];
  };
}
