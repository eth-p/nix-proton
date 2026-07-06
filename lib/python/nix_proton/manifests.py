import tomlkit
import os
import subprocess

from .nix import normalize_package_name


class _ModelBase:
    data: dict

    def __init__(self, data: dict):
        self.data = data

    def __contains__(self, key: str):
        return key in self.data

    def __getitem__(self, key: str) -> any:
        return self.data[key]

    def __setitem__(self, key: str, value: any):
        self.data[key] = value

    def __repr__(self) -> str:
        return repr(self.data)

    def get(self, *args, **kwargs) -> any:
        return self.data.get(*args, **kwargs)


class _ContainerBase:
    data: dict

    def __init__(self, data: dict):
        self.data = data

    def __contains__(self, key: str):
        return key in self.data

    def __getitem__(self, key: str) -> any:
        return self._wrap(self.data[key])

    def __setitem__(self, key: str, value: any):
        self.data[key] = value

    def __repr__(self) -> str:
        return repr(self.data)


class Manifest:
    """
    A nix-proton manifest file.
    """

    file: str
    data: dict

    version: "ManifestVersions"

    def __init__(self, file: os.PathLike, data: str):
        self.file = str(file)
        self.data = tomlkit.parse(data)

        self.data.setdefault("version", {})
        self.version = ManifestVersions(self.data["version"])

    def __repr__(self) -> str:
        return f"<nix-proton manifest @ {self.file}>"

    @property
    def latest_version(self) -> str | None:
        return self.data["proton"].get("latest", None)

    @latest_version.setter
    def latest_version(self, version: str) -> str:
        self.data["proton"]["latest"] = version

    def is_latest(self, version: str) -> bool:
        return self.latest_version == version


class ManifestVersions(_ContainerBase):
    """
    Container for `version` table.
    """

    def __init__(self, data: dict):
        super().__init__(data)
        self._wrap = Version

    def __repr__(self) -> str:
        return f"<nix-proton manifest.version: {self.data}>"

    def setup(self, version: str, package=None) -> "Version":
        """
        Creates a new version entry in the manifest for the specified version
        if it doesn't already exist.
        """
        self.data.setdefault(version, {})
        version_obj = self[version]
        if version_obj.package is None:
            version_obj.package = package or normalize_package_name(version)
        return self[version]


class Version(_ModelBase):
    """
    Model for `version.${version}`
    """

    def __init__(self, data: dict):
        super().__init__(data)

    @property
    def package(self) -> str | None:
        return self.data.get("package", None)

    @property
    def download(self) -> str | None:
        return VersionDownload(self.data.setdefault("download", {}))

    @package.setter
    def package(self, name: str) -> str:
        self["package"] = name

    def set_download(self, system: str, data: any):
        self.data.setdefault("download", {})[system] = data


class VersionDownload(_ModelBase):
    """
    Model for `version.${version}.download` table.
    """

    def __init__(self, data: dict):
        super().__init__(data)

    @property
    def package(self) -> str | None:
        return self.data.get("package", None)

    @package.setter
    def package(self, name: str) -> str:
        self["package"] = name

    def set_download(self, system: str, data: any):
        self.data.setdefault("download", {})[system] = data


def load(file: os.PathLike) -> Manifest:
    with open(file) as f:
        file_contents = f.read()
        return Manifest(file, file_contents)


def update(manifest: Manifest):
    new_contents = tomlkit.dumps(manifest.data)
    with open(manifest.file, "w") as f:
        f.write(new_contents)

    # Reformat the file.
    subprocess.run(
        ["tombi", "format", "--quiet", "--", manifest.file], check=True
    )
