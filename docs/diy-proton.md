# Installing Proton on Other Linux Operating Systems

Instructions and documentation for using nix-proton to add custom Proton
installations to Steam on other Linux distros without using home-manager.

>[!CAUTION]
> If you are using NixOS (the operating system),
> [this is the guide you want](./nixos-proton.md)!

## Overview

The general idea for using nix-proton to install Proton is using `nix profile`
to install the packages, and then symlinking them from `~/.nix-profile` into
Steam's `compatibilitytools.d` directory.


## Assisted Installation

This flake provides the `nix-proton-link` tool to automatically manage symlinks
to Proton installations in your Nix user profile.

Using the tool removes the need to manage symlinks manually, automating the
process of creating and deleting symlinks for every installed Proton package.

 1. Install a Proton package.

    ```
    nix profile add github:eth-p/nix-proton#proton-cachyos-bin-latest
    ```

 2. Run the `nix-proton-link` tool.

    ```
    nix run github:eth-p/nix-proton#nix-proton-link
    ```


## Manual Installation

>[!TIP]
> If you are able to set the environment variables used to launch Steam, you
> can instead set `STEAM_EXTRA_COMPAT_TOOLS_PATHS` to
> `$HOME/.nix-profile/share/steam/compatibilitytools.d`.


 1. Install a Proton package.

    ```
    nix profile add github:eth-p/nix-proton#proton-cachyos-bin-latest
    ```

 2. Link every Proton package into Steam's `compatibilitytools.d` directory.

    ```
    ln -t ~/.steam/steam/compatibilitytools.d -s ~/.nix-profile/share/steam/compatibilitytools.d/*
    ```

 3. Remove any broken links to uninstalled Proton packages. (Optional)
