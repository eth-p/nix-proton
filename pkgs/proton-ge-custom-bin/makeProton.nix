{
  stdenvNoCC,
  fetchGitHubReleaseAsset,
  lib,

  gnutar,
  gzip,

  # From nix-proton:
  changeProtonName,

  # Overrideable options:
  suffix ? "",
}:
{
  version,
  download,

  protonDisplayName ? null,
  protonToolName ? null,
}:
stdenvNoCC.mkDerivation {
  pname = "proton-ge-bin${suffix}";
  version = version;

  src = fetchGitHubReleaseAsset (
    {
      repo = "GloriousEggroll/proton-ge-custom";
    }
    // download
  );

  nativeBuildInputs = [
    gnutar
    gzip
    changeProtonName
  ];

  unpackPhase = ''
    runHook preUnpack

    mkdir proton

    gunzip -k -c $src |
      tar --directory=proton --extract --strip-components=1

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    compatToolsDir=share/steam/compatibilitytools.d
    protonName=proton-$(head -n1 proton/version | cut -d' ' -f2 | tr -cd '[[:alnum:]\.\-]')
    protonDirName=''${protonDirName:-$protonName}

    mkdir -p $out/$compatToolsDir
    mv proton $out/$compatToolsDir/$protonDirName

    runHook postInstall
  '';

  # Options for changeProtonName hook:
  inherit protonDisplayName;
  inherit protonToolName;

  # Proton is expected to run inside the Steam Linux Runtime.
  # Avoid patching/fixuping anything extracted from the tarball.
  dontPatchELF = true;
  dontPatchShebangs = true;
  dontStrip = true;
  dontFixup = true;
  noAuditTmpdir = true;

  passthru = {
    isProton = true;
  };

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
