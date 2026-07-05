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
