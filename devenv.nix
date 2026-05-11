# Devenv Config
# Reference: https://devenv.sh/reference/options/
# ==============================================================================
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  packages = [
    pkgs.git

    # formatting
    pkgs.treefmt
    pkgs.nixfmt
    pkgs.tombi
    pkgs.yq-go
  ];

  # Disable the default enterShell task.
  enterShell = lib.mkForce "";
}
