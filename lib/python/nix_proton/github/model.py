from datetime import datetime
from functools import cache


class _ModelBase:
    _data: dict

    def __init__(self, data: dict):
        self._data = data

    def __contains__(self, key: str):
        return key in self.data

    def __getitem__(self, key: str) -> any:
        return self._data[key]

    def __repr__(self) -> str:
        return repr(self._data)


class ReleaseAsset(_ModelBase):
    """
    Data model for a release asset.
    """

    @property
    def name(self) -> bool:
        return self["name"]

    @property
    def url(self) -> str:
        return self["url"]

    @property
    def digest(self) -> str | None:
        return self["digest"]


class Release(_ModelBase):
    """
    Data model for a release.
    """

    @property
    def is_latest(self) -> bool:
        return self["isLatest"]

    @property
    def tag(self) -> str:
        return self["tagName"]

    @property
    @cache
    def published_at(self) -> str:
        return datetime.strptime(self["publishedAt"], "%Y-%m-%dT%H:%M:%SZ")


class Repo(_ModelBase):
    """
    Data model for a repository.
    """

    @property
    def owner(self) -> str:
        return self["owner"]

    @property
    def name(self) -> str:
        return self["name"]

    def __str__(self) -> str:
        return f"github:{self.owner}/{self.repo}"
