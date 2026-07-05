# Contributing Guide

Pull requests are welcome!

Please make sure to follow [conventional commits] and format your changes
before committing them.

[conventional commits]: https://www.conventionalcommits.org/en/v1.0.0/#summary


## Formatting Changes

```bash
devenv shell treefmt
```


## Updating Proton Manifests

```bash
nix develop --command pkgs/proton-cachyos-bin/update.py
```
