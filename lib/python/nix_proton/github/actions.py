from .util import cli
from .model import Repo
from .model import Release
from .model import ReleaseAsset
from ..nix import sha256_to_sri, url_to_sri


def get_repo(owner: str, name: str) -> Repo:
    return Repo(
        {
            "owner": owner,
            "name": name,
        }
    )


def get_releases(
    repo: Repo,
    include_drafts: bool = False,
    include_prereleases: bool = False,
    limit: int = 100,
    fields: list[str] = ["tagName", "isLatest", "publishedAt"],
) -> list[Release]:
    """
    Fetches the latest releases of a repo.
    """
    flags = [
        f"--repo={repo.owner}/{repo.name}",
        f"--limit={limit}",
        f"--json={','.join(fields)}",
    ]

    if not include_drafts:
        flags.append("--exclude-drafts")
    if not include_prereleases:
        flags.append("--exclude-pre-releases")

    releases_json = cli("release", "list", *flags, decode=True)
    releases = [Release(data) for data in releases_json]
    return list(reversed(sorted(releases, key=lambda rel: rel.published_at)))


def get_release_assets(repo: Repo, tag: str) -> list[ReleaseAsset]:
    """
    Fetches the assets for a specific release.
    """
    flags = [f"--repo={repo.owner}/{repo.name}", "--json=assets"]
    release_json = cli("release", "view", *flags, tag, decode=True)
    assets = [ReleaseAsset(data) for data in release_json["assets"]]
    return assets


def get_release_asset_nix_hash(
    repo: Repo, asset: ReleaseAsset
) -> list[ReleaseAsset]:
    """
    Gets the nix SRI hash for a release asset.
    """
    if asset.digest.startswith("sha256:"):
        return sha256_to_sri(asset.digest)

    return url_to_sri(asset.url)
