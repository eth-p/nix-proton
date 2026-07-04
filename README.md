# nix-proton

A Nix flake for managing the installation of prebuilt Proton packages and
creating local protonfixes.


## Guides

**Home-Manager:**

 - [Creating local protonfixes.](./docs/hm-protonfixes.md)

**NixOS:**

 - [Managing system-wide Proton installations on NixOS.](./docs/nixos-proton.md)

**Other:**

 - [Installing Proton on other Linux operating systems.](./docs/diy-proton.md)


## Proton Packages

[proton-cachyos]: https://github.com/CachyOS/proton-cachyos

|Path|Variant|Platform|
|:--|:--|:--|
|`packages.${system}.proton-cachyos-bin-${version}`|[proton-cachyos]|x86_64, aarch64|
|`packages.${system}.proton-cachyos-bin-x86-64-v3-${version}`|[proton-cachyos]|x86_64|

>[!TIP]
> If your selected platform has a build of the latest version, you can use
> `latest` as the `${version}`.

To find the full list of packages, use `nix flake show github:eth-p/nix-proton`.

To find available packages for a specific variant, use `nix search github:eth-p/nix-proton proton-cachyos-bin`.
