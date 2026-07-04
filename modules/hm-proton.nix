nix-proton:
{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (nix-proton.packages.${system}) nix-proton-link;
  cfg = config.nix-proton;
  system = pkgs.stdenvNoCC.hostPlatform.system;
in
{
  options.nix-proton = {
    enable = lib.mkEnableOption "Install Proton packages and them to Steam";
    packages = lib.mkOption {
      type = with lib.types; listOf package;
      description = "The list of Proton packages to install";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      nix-proton.overlays.proton
    ];

    home.packages = cfg.packages;

    home.activation.linkProtonPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.getExe nix-proton-link} -c -t \
        ${lib.escapeShellArg "${config.home.homeDirectory}/.steam/root/compatibilitytools.d"} \
        ${lib.escapeShellArg "${config.home.profileDirectory}/share/steam/compatibilitytools.d"}
    '';
  };
}
