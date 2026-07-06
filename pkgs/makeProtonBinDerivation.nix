{
  stdenvNoCC,
  lib,

  gnutar,
  gzip,
  xz,

  # From nix-proton:
  changeProtonName,
}:
inputs:
stdenvNoCC.mkDerivation (
  {
    nativeBuildInputs = (
      [
        gnutar
        gzip
        xz
        changeProtonName
      ]
      ++ (inputs.nativeBuildInputs or [ ])
    );

    unpackPhase = ''
      runHook preUnpack

      decompress_archive() {
        case "$(basename -- "$1")" in
          *.xz)
            xz --decompress <"$1"
            ;;
          *.gz)
            gunzip -k -c "$1"
            ;;
        esac
      }

      mkdir proton
      decompress_archive $src |
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

    meta = (
      {
        sourceProvenance = lib.sourceTypes.binaryNativeCode;
      }
      // (inputs.meta or { })
    );
  }
  // (lib.removeAttrs inputs [
    "nativeBuildInputs"
    "meta"
  ])
)
