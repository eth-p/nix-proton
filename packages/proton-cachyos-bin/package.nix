{
  stdenvNoCC,
  fetchurl,

  withVersion,
  withDownload,
  ...
}: stdenvNoCC.mkDerivation
{
  name = "proton-cachyos-bin";
  version = withVersion;

  src = fetchurl {
    inherit (withDownload) sha256;
    url = "https://github.com/CachyOS/proton-cachyos/releases/download/${withDownload.release}/${withDownload.file}";
  };
}
