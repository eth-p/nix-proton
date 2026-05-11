{
  description = "A home-manager module for creating local protonfixes";

  outputs =
    { ... }:
    {
      homeManagerModules = rec {
        default = protonfixes;
        protonfixes = ./modules/protonfixes.nix;
      };
    };
}
