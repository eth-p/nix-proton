nix-proton:
{ ... }:
{
  outputs = {
    nixpkgs.overlays = [ nix-proton.overlays.proton ];
  };
}
