{
  stdenvNoCC,
  fetchurl,
  lib,
  xz,
}:
{
  version,
  variant,
  download,
  withGithubReleaseDownloadURL ? "https://github.com/CachyOS/proton-cachyos/releases/download",
}:
stdenvNoCC.mkDerivation {
  name = "proton-cachyos-bin-${version}-${variant}";
  version = version;

  src = fetchurl {
    inherit (download) sha256;
    url = "${withGithubReleaseDownloadURL}/${download.release}/${download.file}";
  };

  nativeBuildInputs = [
    xz
  ];

  # unpackPhase = ''
  #   runHook preUnpack

  #   mkdir proton
  #   xz --decompress <$src | tar --directory=proton --extract --strip-components=1

  #   runHook postUnpack
  # '';

  installPhase = ''
    runHook preInstall

    protonName="proton-$(cat version)"
    protonDir="share/steam/compatibilitytools.d/$protonName"

    mkdir -p "$out/$protonDir"
    mv -t "$out/$protonDir" * .*

    runHook postInstall
  '';

  passthru = {
    inherit variant;
  };

  dontPatchELF = true;
  dontPatchShebangs = true;
  noAuditTmpdir = true;

  meta = {
    description = "A Proton fork introducing experimental features, third-party tools and more.";
    homepage = "https://github.com/CachyOS/proton-cachyos";
    platforms = lib.platforms.linux;
    systems = [ "x86_64-linux" ];
    sourceProvenance = lib.sourceTypes.binaryNativeCode;
    license = with lib.licenses; [
      bsd3 # https://github.com/CachyOS/proton-cachyos/blob/cachyos_main/LICENSE.proton
    ];
  };
}
