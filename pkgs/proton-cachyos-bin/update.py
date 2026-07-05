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
from nix_proton import nix

repo = github.get_repo("CachyOS", "proton-cachyos")
manifest_reg = manifests.load(path.join(here, "manifest.toml"))
manifest_x86_64_v3 = manifests.load(path.join(here, "manifest-x86-64-v3.toml"))
expected_assets_per_release = 3


def release_tag_to_version(tag: str) -> str:
    v = tag.removeprefix("cachyos-")
    v = v.removesuffix("-slr")
    return v


def add_release_binary(
    release: github.Release,
    version: str,
    asset: github.ReleaseAsset,
    system: str,
    manifest: manifests.Manifest,
):
    feedback.known_asset(asset.name)
    manifest.version[version].download[system] = {
        "release": release.tag,
        "file": asset.name,
        "sha256": github.get_release_asset_nix_hash(repo, asset),
    }


def add_release(release: github.Release, version: str):
    assets = github.get_release_assets(repo, release.tag)
    assets_added = 0
    asset: github.ReleaseAsset  # set by for loop

    def add_asset(**kwargs):
        nonlocal assets_added, assets
        add_release_binary(release, version, asset, **kwargs)
        assets_added += 1

    for asset in assets:
        # x86_64-linux
        if asset.name.endswith("-slr-x86_64.tar.xz"):
            add_asset(system="x86_64-linux", manifest=manifest_reg)
            continue

        # x86_64-linux (x86-64-v3)
        if asset.name.endswith("-slr-x86_64_v3.tar.xz"):
            add_asset(system="x86_64-linux", manifest=manifest_x86_64_v3)
            continue

        # aarch64-linux
        if asset.name.endswith("-slr-arm64.tar.xz"):
            add_asset(system="aarch64-linux", manifest=manifest_reg)
            continue

        # unknown arch
        if asset.name.endswith(".tar.xz"):
            feedback.unknown_asset(asset.name)
            raise Exception(f"New proton-cachyos package: {asset.name}")

        # unsupported/unknown asset
        feedback.unknown_asset(asset.name)

    if assets_added < expected_assets_per_release:
        raise Exception(
            f"Expected at least {expected_assets_per_release},"
            f" but only found {assets_added} (of {len(assets)})"
        )


def run():
    for release in github.get_releases(repo):
        feedback.checking_github_release(release)

        tag = release["tagName"]
        is_latest = release["isLatest"]
        version = release_tag_to_version(tag)
        package_name = nix.normalize_package_name(version)

        feedback.detail("Version", version)

        # If the manifest has this version as the latest already, that means it
        # and all previous releases were processed already during a previous
        # run of this script.
        if manifest_reg.is_latest(version):
            feedback.caught_up()
            return

        # Since it's a newer version than when the manifest was last updated,
        # it needs to be added to the manifest.
        for manifest in [manifest_reg, manifest_x86_64_v3]:
            manifest.version.setup(version, package=package_name)

        add_release(release, version)

        # If the GitHub release is marked as the latest version, the manifest
        # needs to be updated accordingly.
        if is_latest:
            manifest_reg.latest_version = version
            manifest_x86_64_v3.latest_version = version


if __name__ == "__main__":
    run()
    manifests.update(manifest_reg)
    manifests.update(manifest_x86_64_v3)
