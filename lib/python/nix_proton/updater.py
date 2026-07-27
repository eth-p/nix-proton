from abc import ABC
from abc import abstractmethod
from argparse import ArgumentParser
from os.path import dirname, abspath
from . import git
from . import github
from . import manifests, manifests as _manifests
from . import feedback
from . import nix


class GitHubReleaseUpdater(ABC):
    """
    Base class for implementing an update script based on GitHub releases.
    """

    args_parser: ArgumentParser  # parsed into args

    # May be defined as class attributes.
    repo: github.Repo
    manifest: manifests.Manifest
    manifests: list[manifests.Manifest]

    commit_prefix: str = None
    assert_num_assets_added: int | None = None
    assert_min_assets_added: int | None = None

    # Mutated per iteration.
    releases: list[github.Release]
    release: github.Release
    version: str
    package: str
    assets: list[github.ReleaseAsset]
    assets_added: int
    asset: github.ReleaseAsset

    def __init__(
        self,
        repo: github.Repo = None,
        manifest: manifests.Manifest = None,
        manifests: list[manifests.Manifest] = None,
    ):
        self.repo = repo or type(self).repo
        self.manifest = manifest or type(self).manifest

        self.args_parser = ArgumentParser()
        self.init_argparse()

        if manifests is not None:
            self.manifests = manifests

        elif not hasattr(self, "manifests"):
            self.manifests = [self.manifest]
            cls = type(self)
            for attr in dir(cls):
                if attr.startswith("manifest_"):
                    attr_val = getattr(cls, attr)
                    if isinstance(attr_val, _manifests.Manifest):
                        self.manifests.append(attr_val)

        if self.commit_prefix is None:
            self.commit_prefix = self.manifest.data["proton"]["variant"]

    @property
    def manifest_files(self) -> list[str]:
        return [abspath(m.file) for m in self.manifests]

    def should_process_release(self, release: github.Release) -> bool:
        """
        If this returns False, the updater will not process this specific
        release.
        """
        return True

    def should_stop(self) -> bool:
        """
        If this returns True, the updater will stop at this release.
        """
        # If the manifest has this version already, all previous releases
        # were already processed during a previous run of this script.
        return self.version in self.manifest.version

    def after_assets_processsed(self):
        """
        Called after all assets have been processed.
        Use this to check that the correct number of assets were added.
        """
        if self.assert_num_assets_added is not None:
            if self.assets_added != self.assert_num_assets_added:
                raise Exception(
                    f"Expected exactly {self.assert_num_assets_added} prebuilt"
                    f" packages, but only found {self.assets_added}"
                    f" (of {len(self.assets)})"
                )

        if self.assert_min_assets_added is not None:
            if self.assets_added < self.assert_min_assets_added:
                raise Exception(
                    f"Expected at least {self.assert_min_assets_added} prebuilt"
                    f" packages, but only found {self.assets_added}"
                    f" (of {len(self.assets)})"
                )

    def after_releases_processsed(self):
        """
        Called after all releases have been processed.
        """
        pass

    @abstractmethod
    def get_version_name(self) -> str:
        """
        Returns the version string for this release.
        """
        pass

    @abstractmethod
    def process_asset(self):
        """
        Processes the asset.
        """
        pass

    def get_package_name(self) -> str:
        """
        Returns the package name string for this release.
        """
        return nix.normalize_package_name(self.version)

    def add_version_to_manifest(self):
        """
        Adds the target version to all manifests if it doesn't already exist.
        """
        for manifest in self.manifests:
            manifest.version.setup(
                self.version,
                package=self.package,
                date=self.release.published_at,
            )

    def add_download_to_manifest(
        self, system: str, manifest: manifests.Manifest = None
    ):
        """
        Adds the target asset as a download of the target release for specified
        system in the default manifest.
        """
        if manifest is None:
            manifest = self.manifest

        feedback.known_asset(self.asset.name)
        manifest.version[self.version].download[system] = {
            "release": self.release.tag,
            "file": self.asset.name,
            "sha256": github.get_release_asset_nix_hash(self.repo, self.asset),
        }
        self.assets_added += 1

    def set_latest_version_in_manifest(self):
        """
        Sets the latest version in the manifest to the version of the
        release currently being processed.
        """
        for manifest in self.manifests:
            manifest.latest_version = self.version

    def write_manifest(self):
        """
        Writes the manifest back to the disk.
        """
        for manifest in self.manifests:
            manifests.update(manifest)

    def process_release(self):
        self.assets = github.get_release_assets(self.repo, self.release.tag)
        self.assets_added = 0

        for asset in self.assets:
            self.asset = asset

            prev_assets_added = self.assets_added
            self.process_asset()
            if self.assets_added == prev_assets_added:
                feedback.unknown_asset(asset.name)
                continue

        self.after_assets_processsed()

    def _prepare_for_release(self, release: github.Release, show_feedback=True):
        self.release = release
        self.version = self.get_version_name()
        self.package = self.get_package_name()
        self.assets = None
        self.assets_added = None
        self.asset = None
        if show_feedback:
            feedback.checking_github_release(release)
            feedback.detail("Version", self.version)
            feedback.detail("Package", self.package)

    def init_argparse(self):
        self.args_parser.add_argument(
            "--commit",
            action="store_true",
            help="Create a commit for each update",
        )

    def run(self):
        self.args = self.args_parser.parse_args()
        self.releases = github.get_releases(self.repo)
        git_kwargs = {
            "repo": dirname(self.manifest.file),
        }

        # If committing, ensure the repo is clean.
        if self.args.commit:
            if git.has_changes(staged=True, **git_kwargs):
                raise Exception(
                    "Repo has staged changes, cannot --commit updates."
                )

            if git.has_changes(paths=self.manifest_files, **git_kwargs):
                raise Exception(
                    "Repo has uncommitted changes to manifest, "
                    "cannot --commit updates."
                )

        # Find new releases.
        last_processed_release = None
        releases_to_process = []
        for release in self.releases:
            self._prepare_for_release(release, show_feedback=False)
            if not self.should_process_release(release):
                continue

            if self.should_stop():
                last_processed_release = release
                break

            releases_to_process.append(release)

        # And process them from oldest to newest.
        for release in reversed(releases_to_process):
            self._prepare_for_release(release)

            self.add_version_to_manifest()
            self.process_release()

            # If the GitHub release is marked as the latest version, the
            # manifest needs to be updated accordingly.
            if release.is_latest:
                self.set_latest_version_in_manifest()

            # If committing changes is enabled, do that.
            if self.args.commit:
                self.write_manifest()
                git.add(self.manifest_files, **git_kwargs)
                git.commit(
                    message=f"{self.commit_prefix}: Add {self.version}",
                    **git_kwargs,
                )

        # Print info about the previous-latest release.
        self._prepare_for_release(last_processed_release)
        feedback.caught_up()

        # Write the changes.
        self.after_releases_processsed()
        self.write_manifest()
