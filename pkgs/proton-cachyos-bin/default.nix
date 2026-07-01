{
  pkgs ? (import <nixpkgs> { system = builtins.currentSystem; }),
}:
let
  inherit (pkgs) lib;
in
lib.makeScope pkgs.newScope (self: {
  mkProtonPackageSet = pkgs.callPackage ./mkProtonPackageSet.nix { };
  proton-cachyos-bin = self.mkProtonPackageSet { dir = ./proton-cachyos-bin; };
})
