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
from os.path import join
from nix_proton.updater import GitHubReleaseUpdater
from nix_proton import manifests
from nix_proton import feedback
from nix_proton import github


class Updater(GitHubReleaseUpdater):
    repo = github.get_repo("GloriousEggroll", "proton-ge-custom")
    manifest = manifests.load(join(here, "manifest.toml"))

    assert_num_assets_added = 2

    @override
    def get_version_name(self) -> str:
        v = self.release.tag
        v = v.removeprefix("GE-Proton")
        return v

    @override
    def process_asset(self):
        file = self.asset.name
        tag = self.release.tag

        # x86_64-linux
        if file == f"{tag}.tar.gz":
            self.add_download_to_manifest(system="x86_64-linux")
            return

        # aarch64-linux
        if file == f"{tag}-aarch64.tar.gz":
            self.add_download_to_manifest(system="aarch64-linux")
            return

        # unknown arch
        if file.endswith(".tar.gz"):
            feedback.unknown_asset(file)
            raise Exception(f"New proton-ge-custom package: {file}")


if __name__ == "__main__":
    updater = Updater()
    updater.run()
