{
  stdenvNoCC,
  fetchGitHubReleaseAsset,
  lib,
  xz,

  # From nix-proton:
  changeProtonName,

  # Overrideable options:
  suffix ? "",
}:
{
  version,
  download,
}:
stdenvNoCC.mkDerivation {
  pname = "proton-cachyos-bin${suffix}";
  version = version;

  src = fetchGitHubReleaseAsset (
    {
      repo = "CachyOS/proton-cachyos";
    }
    // download
  );

  nativeBuildInputs = [
    xz
    changeProtonName
  ];

  unpackPhase = ''
    runHook preUnpack

    mkdir proton
    xz --decompress <$src | tar --directory=proton --extract --strip-components=1

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

  # Proton is expected to run inside the Steam Linux Runtime.
  # Avoid patching/fixuping anything extracted from the tarball.
  dontPatchELF = true;
  dontPatchShebangs = true;
  dontStrip = true;
  dontFixup = true;
  noAuditTmpdir = true;

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
