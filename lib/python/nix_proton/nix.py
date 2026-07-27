import re
import subprocess
from .util import SubprocessException

NIX_HASH_EXECUTABLE = "nix-hash"
BASH_EXECUTABLE = "bash"
CURL_EXECUTABLE = "curl"


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
