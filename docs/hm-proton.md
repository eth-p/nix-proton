# Installing Proton with Home-Manager

Instructions and documentation for using the nix-proton [home-manager] module
to add custom Proton installations to Steam.

[home-manager]: https://github.com/nix-community/home-manager

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

 3. Add the `proton` home-manager module to your `homeManagerConfiguration`.

    ```nix
    homeConfigurations.my-user = home-manager.lib.homeManagerConfiguration {
      modules = [
        nix-proton.homeManagerModules.proton
        # ...
      ];
    }
    ```

 4. Enable `nix-proton` and add packages:

    ```nix
    # inside your home-manager config module
    outputs = {
      nix-proton = {
        enable = true;
        packages = with pkgs.nix-proton; [
          proton-cachyos-bin-latest
        ];
      };
    };
    ```

## Options

> **`nix-proton.enable`** (*bool*): <br>
> Default: `false` <br>
>
> Install Proton packages and them to Steam.

> **`nix-proton.packages`** (*list of packages*): <br>
> Default: `[]` <br>
>
> The list of Proton packages to install.
>
> <sub>Example:</sub>
>
> ```nix
> nix-proton.packages = with pkgs.nix-proton; [
>   proton-cachyos-bin-latest
> ];
> ```
