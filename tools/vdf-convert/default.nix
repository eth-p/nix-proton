{
  python314Packages,
}:
python314Packages.buildPythonApplication {
  pname = "vdf-convert";
  version = "0.0.1";

  propagatedBuildInputs = [ python314Packages.steamodd ];

  format = "other"; # Just a script
  src = ./.;

  installPhase = ''
    install -Dm755 main.py "$out/bin/vdf-convert"
  '';

  meta = {
    mainProgram = "vdf-convert";
  };
}
