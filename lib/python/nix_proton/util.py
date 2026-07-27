import subprocess


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
