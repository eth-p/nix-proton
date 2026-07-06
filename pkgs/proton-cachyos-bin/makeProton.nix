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
  pname = "proton-cachyos-bin${suffix}";
  version = version;

  src = fetchGitHubReleaseAsset (
    {
      repo = "CachyOS/proton-cachyos";
    }
    // download
  );

  # Options for changeProtonName hook:
  inherit protonDisplayName;
  inherit protonToolName;

  meta = {
    description = "A Proton fork introducing experimental features, third-party tools and more.";
    homepage = "https://github.com/CachyOS/proton-cachyos";
    platforms = lib.platforms.linux;
    sourceProvenance = lib.sourceTypes.binaryNativeCode;
    license = with lib.licenses; [
      bsd3 # https://github.com/CachyOS/proton-cachyos/blob/cachyos_main/LICENSE.proton
    ];
  };
}
