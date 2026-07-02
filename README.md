# nix-proton

A flake of prebuilt Proton packages and a [home-manager module
for generating local protonfixes](./docs/hm-protonfixes.md).

[proton-cachyos]: https://github.com/CachyOS/proton-cachyos

## Usage



## Packages

|Path|Proton|Platform|
|:--|:--|:--|
|`packages.${system}.proton-cachyos-bin-${version}`|[proton-cachyos]|x86_64, aarch64|
|`packages.${system}.proton-cachyos-bin-x86-64-v3-${version}`|[proton-cachyos]|x86_64|

>[!TIP]
> If your selected platform has a build of the latest version, you can use
> `latest` as the `${version}`.

To find specific versions, you can use `nix flake show github.com/eth-p/nix-proton`.
