# Internal tools:
{
  pkgs ? (import <nixpkgs> { }),
  lib ? pkgs.lib,
  newScope ? pkgs.newScope,
}:
lib.dontRecurseIntoAttrs (
  lib.makeScope newScope (self: {
    vdf-convert = self.callPackage ./vdf-convert { };
    nix-proton-link = self.callPackage ./nix-proton-link { };
  })
)
