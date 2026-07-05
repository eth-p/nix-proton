import re
import subprocess

NIX_HASH_EXECUTABLE = "nix-hash"
BASH_EXECUTABLE = "bash"
CURL_EXECUTABLE = "curl"


class SubprocessException(Exception):
    """
    Failed to execute a subprocess.
    """

    cmd: list[str]
    returncode: int
    message: str

    def __init__(self, cmd: list[str], proc: subprocess.CompletedProcess):
        self.cmd = cmd
        self.returncode = proc.returncode
        self.message = proc.stderr

    def __str__(self) -> str:
        lines = [
            f"{' '.join(self.cmd)}",
            f"Exited with code {self.returncode}.",
        ]
        if self.message != "":
            lines += ["STDERR:"]
            lines += [f"\u2502   {line}" for line in self.message.splitlines()]
        return "\n".join(lines)


def normalize_package_name(name: str) -> str:
    """
    Normalizes a string into a nix-friendly package name.
    """
    return re.sub("[^0-9a-z-]+", "-", name.lower())


def sha256_to_sri(digest: str) -> str:
    """
    Uses nix-hash to convert a sha256 hash to a nix SRI hash.
    """
    if not digest.startswith("sha256:"):
        raise Exception(f"Digest '{digest}' must start with 'sha256:'")

    cmd = [NIX_HASH_EXECUTABLE, "--to-sri", digest]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise SubprocessException(cmd, proc)

    return proc.stdout.strip()


def url_to_sri(url: str) -> str:
    """
    Downloads a file and uses nix-hash to create a nix SRI hash of it.
    """
    script = f"""
        {CURL_EXECUTABLE} --silent --fail --location --output - "$1" |
            {NIX_HASH_EXECUTABLE} --type sha256 --base32 --sri --flat /dev/stdin
    """
    cmd = [BASH_EXECUTABLE, "-c", script, "--", url]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise SubprocessException(cmd, proc)

    return proc.stdout.strip()
