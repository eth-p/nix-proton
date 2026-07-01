# Internal tools:
{
  pkgs ? (import <nixpkgs> { }),
  lib ? pkgs.lib,
  newScope ? pkgs.newScope,
}:
lib.makeScope newScope (self: {
  vdf-convert = self.callPackage ./vdf-convert { };
})
