# nix-proton (protonfixes home-manager module)

Instructions and documentation for using the protonfixes [home-manager] module.

[home-manager]: https://github.com/nix-community/home-manager
[protonfixes]: https://github.com/Open-Wine-Components/umu-protonfixes
[GE-Proton]: https://github.com/gloriouseggroll/proton-ge-custom
[proton-cachyos]: https://github.com/CachyOS/proton-cachyos

>[!IMPORTANT]
> Protonfixes is not available in upstream Proton. <br>
> You need to use a fork with [protonfixes] support:
> - [GE-Proton]
> - [proton-cachyos]

>[!IMPORTANT]
> Creating a local protonfix for a game will override the built-in protonfix. <br>
> See the [UMU-Protonfixes documentation](https://github.com/Open-Wine-Components/umu-protonfixes#local-fixes)
> for more details.

## Usage (Flakes)

 1. Add `github:eth-p/nix-protonf` to the flake inputs.

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

 3. Add the home-manager module to your `homeManagerConfiguration`.

    ```nix
    homeConfigurations.my-user = home-manager.lib.homeManagerConfiguration {
      modules = [
        nix-proton.homeManagerModules.protonfixes
        # ...
      ];
    }
    ```

 4. Create your local protonfixes:

    ```nix
    # inside your home-manager config module
    outputs = {
      protonfixes.localfixes.enable = true;
      protonfixes.localfixes.app."3681010" = {

        name = "Nioh 3";
        alias = [ "4198760" ];

        environmentVariables = {
          PROTON_HIDE_NVIDIA_GPU="1";
        };
      }
    };
    ```

## Options

> **`protonfixes.localfixes.enable`** (*bool*): <br>
> Default: `false` <br>
>
> Create local protonfixes.

> **`protonfixes.localfixes.app.<appid>.name`** (*string*): <br>
> *Required.* <br>
>
> The application name.

> **`protonfixes.localfixes.app.<appid>.alias`** (*list of string*): <br>
> *Required.* <br>
>
> Additional app IDs for this protonfix.

> **`protonfixes.localfixes.app.<appid>.environmentVariables`** (*attribute set of string*): <br>
> Default: `{}` <br>
>
> App environment variables to override.

> **`protonfixes.localfixes.app.<appid>.extraFixes`** (*lines*): <br>
> Default: `""` <br>
>
> Extra Python code to run at the end of the protonfix.
>
> See: https://github.com/Open-Wine-Components/umu-protonfixes/blob/master/util.py
