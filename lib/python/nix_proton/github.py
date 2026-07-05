import subprocess
import json

GH_EXECUTABLE = "gh"


class GitHubException(Exception):
    """
    Failed to execute the 'gh' command-line executable.
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


def cli(*args, decode=False):
    """
    Runs the GitHub command-line executable.
    """
    cmd = [GH_EXECUTABLE] + list(args)
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise GitHubException(cmd, proc)

    if decode:
        return json.loads(proc.stdout)
    else:
        return proc.stdout


class Repo:
    """
    A GitHub repository.
    """

    owner: str
    repo: str

    _repoFlag: str

    def __init__(self, owner: str, repo: str):
        self.owner = owner
        self.repo = repo
        self._repoFlag = f"--repo={self.owner}/{self.repo}"

    def __str__(self) -> str:
        return f"github:{self.owner}/{self.repo}"

    def get_releases(
        self,
        include_drafts: bool = False,
        include_prereleases: bool = False,
        limit: int = 100,
        fields: list[str] = ["tagName", "isLatest", "publishedAt"],
    ) -> list[dict]:
        flags = [
            self._repoFlag,
            f"--limit={limit}",
            f"--json={','.join(fields)}",
        ]
        if not include_drafts:
            flags.append("--exclude-drafts")
        if not include_prereleases:
            flags.append("--exclude-pre-releases")

        releases = cli("release", "list", *flags, decode=True)
        return list(
            reversed(sorted(releases, key=lambda rel: rel["publishedAt"]))
        )

    def get_release_assets(self, release: str) -> dict:
        flags = [self._repoFlag, "--json=assets"]
        return cli("release", "view", *flags, decode=True)
