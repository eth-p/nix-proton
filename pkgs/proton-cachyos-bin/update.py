#!/usr/bin/env python3
# ruff: noqa:E402
# ------------------------------------------------------------------------------
# Adds new proton-ge-custom versions to the manifests in proton-ge-custom-bin.
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
from typing import override
from os import path
from nix_proton.updater import GitHubReleaseUpdater
from nix_proton import manifests
from nix_proton import feedback
from nix_proton import github

repo = github.get_repo("CachyOS", "proton-cachyos")
manifest = manifests.load(path.join(here, "manifest.toml"))
manifest_x86_64_v3 = manifests.load(path.join(here, "manifest-x86-64-v3.toml"))
expected_assets_per_release = 3


class Updater(GitHubReleaseUpdater):
    def __init__(self):
        super().__init__(
            repo, manifest, manifests=[manifest, manifest_x86_64_v3]
        )
        self.manifest_x86_64_v3 = manifest_x86_64_v3

    @override
    def get_version_name(self) -> str:
        v = self.release.tag
        v = v.removeprefix("cachyos-")
        v = v.removesuffix("-slr")
        return v

    @override
    def after_assets_processsed(self):
        if self.assets_added < expected_assets_per_release:
            raise Exception(
                f"Expected at least {expected_assets_per_release} prebuilt"
                f" packages, but only found {self.assets_added}"
                f" (of {len(self.assets)})"
            )

    @override
    def process_asset(self):
        file = self.asset.name

        # x86_64-linux
        if file.endswith("-slr-x86_64.tar.xz"):
            self.add_download_to_manifest(
                system="x86_64-linux",
                manifest=self.manifest,
            )
            return

        # x86_64-linux (x86-64-v3)
        if file.endswith("-slr-x86_64_v3.tar.xz"):
            self.add_download_to_manifest(
                system="x86_64-linux",
                manifest=self.manifest_x86_64_v3,
            )
            return

        # aarch64-linux
        if file.endswith("-slr-arm64.tar.xz"):
            self.add_download_to_manifest(
                system="aarch64-linux",
                manifest=self.manifest,
            )
            return

        # unknown arch
        if file.endswith(".tar.xz"):
            feedback.unknown_asset(file)
            raise Exception(f"New proton-cachyos package: {file}")


if __name__ == "__main__":
    updater = Updater()
    updater.run()
