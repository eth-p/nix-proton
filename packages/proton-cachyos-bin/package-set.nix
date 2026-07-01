{ pkgs }:
let
  inherit (pkgs) lib;
  system = lib.stdenv.hostPlatform.system;
  protons = (lib.fromTOML (lib.readFile ./protons.toml));
  latest = protons.latest.version;
  versions = protons.version;
in
lib.makeScope pkgs.newScope (
  self:
  let
    protonPackages = map (
      { name, value }:
      self.callPackage ./package.nix {
        withVersion = name;
        withDownload = value.dl.${system};
      }
    ) (lib.attrsToList versions);
  in
  (
    protonPackages
    // {
      latest = protonPackages."${latest}";
    }
  )
)
