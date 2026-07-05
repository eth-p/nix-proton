#!/usr/bin/env python3
# ruff: noqa:E402
# ------------------------------------------------------------------------------
# Adds new proton-cachyos versions to the manifests in proton-cachyos-bin.
# This should be run through `nix develop` to ensure the correct tools are
# available.
# ------------------------------------------------------------------------------
import sys, os  # noqa:E401
from functools import reduce

compose = lambda fs: lambda v: reduce(lambda a, f: f(a), fs, v)  # noqa:E731
here = os.path.dirname(os.path.realpath(__file__))
project_root = (compose([os.path.dirname] * 2))(here)
sys.path.append(os.path.join(project_root, "lib", "python"))
# ------------------------------------------------------------------------------
from os import path
from nix_proton import github
from nix_proton import manifests
from nix_proton import feedback

repo = github.Repo("CachyOS", "proton-cachyos")
manifest_reg = manifests.load(path.join(here, "manifest.toml"))
manifest_x86_64_v3 = manifests.load(path.join(here, "manifest-x86-64-v3.toml"))


def release_tag_to_version(tag: str) -> str:
    v = tag.removeprefix("cachyos-")
    v = v.removesuffix("-slr")
    return v


def add_release(release: dict, tag: str, version: str):
    assets = repo.get_release_assets(tag)
    print(release)
    print(assets)



def run():
    for release in repo.get_releases():
        tag = release["tagName"]
        is_latest = release["isLatest"]
        version = release_tag_to_version(tag)

        feedback.release(tag)
        feedback.version(version)

        if manifest_reg.is_latest(version):
            feedback.caught_up()
            # return

        add_release(release, tag, version)

        if is_latest:
            # TODO: Update manifest
            pass

        break
    pass


if __name__ == "__main__":
    run()
    manifests.update(manifest_reg)
    manifests.update(manifest_x86_64_v3)
