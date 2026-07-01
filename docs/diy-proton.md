# Installing Proton on Other Linux Operating Systems

Instructions and documentation for using nix-proton to add custom Proton
installations to Steam on other Linux distros without using home-manager.

>[!CAUTION]
> If you are using NixOS (the operating system),
> [this is the guide you want](./nixos-proton.md)!


## Manual Configuration

 1. Install a Proton package.

    ```
    nix profile add github:eth-p/nix-proton#proton-cachyos-bin-latest
    ```

 2. Link the Proton packages into Steam's `compatibilitytools.d` directory.

    ```
    ln -t ~/.steam/steam/compatibilitytools.d -s ~/.nix-profile/share/steam/compatibilitytools.d/*
    ```

>[!TIP]
> If you are able to set the environment variables used to launch Steam, you
> can instead set `STEAM_EXTRA_COMPAT_TOOLS_PATHS` to
> `$HOME/.nix-profile/share/steam/compatibilitytools.d`.
