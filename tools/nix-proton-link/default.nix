{
  bash,
  coreutils,
  gnused,

  lib,
  stdenvNoCC,
  makeWrapper,
}:
stdenvNoCC.mkDerivation rec {
  pname = "nix-proton-link";
  version = "0.0.1";

  srcs = [
    ./nix-proton-link.bash
    ./nix-proton-link.1
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    bash
    gnused
    coreutils
  ];

  buildPhase = ''
    runHook preBuild

    src1=$(cut -d' ' -f1 <<<"$srcs")
    src2=$(cut -d' ' -f2 <<<"$srcs")

    cp $src1 nix-proton-link.bash
    cp $src2 nix-proton-link.1

    chmod +x nix-proton-link.bash

    substituteInPlace nix-proton-link.1 \
      --replace-fail '@version@' ${lib.escapeShellArg version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/man/man1
    cp nix-proton-link.bash $out/bin/nix-proton-link
    cp nix-proton-link.1 $out/share/man/man1

    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup

    substituteInPlace $out/bin/nix-proton-link \
      --replace-fail '"$HERE"/nix-proton-link.1' $out/share/man/man1/nix-proton-link.1

    wrapProgram $out/bin/nix-proton-link \
      --prefix PATH ${
        lib.makeBinPath [
          bash
          coreutils
          gnused
        ]
      }

    runHook postFixup
  '';

  dontUnpack = true;

  meta = {
    mainProgram = "nix-proton-link";
    description = "Link Steam compatibility tools.";
    homepage = "https://github.com/eth-p/nix-proton";
    license = lib.licenses.mit;
  };
}
