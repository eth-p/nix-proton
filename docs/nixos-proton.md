# Installing Proton on NixOS

Instructions and documentation for using nix-proton to add custom Proton
installations to Steam on NixOS.

>[!CAUTION]
> This only applies to NixOS, the operating system. <br>
> If you are only using Nix as a package manager,
> [this is the guide you want](./diy-proton.md)!


## Flake-Based Configuration

 1. Add `github:eth-p/nix-proton` to the flake inputs.

    ```nix
    inputs = {
      url = "github:eth-p/nix-proton";
    };
    ```

 2. Add `nix-proton` to the `output` function arguments.

    ```nix
    outputs = { nix-proton, ... }: {
      # ...
    }
    ```

 3. Add the NixOS module to your `nixosSystem`.

    ```nix
    nixosConfigurations.my-system = nixpkgs.lib.nixosSystem {
      modules = [
        nix-proton.nixosModules.proton
        # ...
      ];
    };
    ```

 4. Add nix-proton packages as steam extraPkgs:

    ```nix
    # inside your device configuration module
    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraPkgs = pkgs': with pkgs'.nix-proton; [
          proton-cachyos-bin-latest
        ];
      };
    };
    ```
