import tomlkit
import os


class Manifest:
    """
    A nix-proton manifest file.
    """

    file: str
    data: dict

    def __init__(self, file: os.PathLike, data: str):
        self.file = str(file)
        self.data = tomlkit.parse(data)

    def __repr__(self) -> str:
        return f"<nix-proton manifest @ {self.file}>"

    def __getitem__(self, key: str):
        return self.data[key]

    def __setitem__(self, key: str, value: any):
        self.data[key] = value

    def is_latest(self, version: str) -> bool:
        return self.data["proton"]["latest"] == version


def load(file: os.PathLike) -> Manifest:
    with open(file) as f:
        file_contents = f.read()
        return Manifest(file, file_contents)


def update(manifest: Manifest):
    new_contents = tomlkit.dumps(manifest.data)
    with open(manifest.file, "w") as f:
        f.write(new_contents)
