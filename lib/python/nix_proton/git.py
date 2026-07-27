import subprocess
from .util import SubprocessException

GIT_EXECUTABLE = "git"


def cli(*args, repo: str = None) -> str:
    """
    Runs the git command-line executable.
    """
    cmd = [GIT_EXECUTABLE]
    if repo is not None:
        cmd.extend(["-C", repo])
    cmd += list(args)
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise SubprocessException(cmd, proc)

    return proc.stdout.strip()


def has_changes(
    paths: list[str] = None,
    repo: str = None,
    staged: bool = False,
) -> bool:
    """
    Returns true if the repo has any uncommitted changes.
    """
    cmd = [
        "diff",
        "--quiet",
        "--exit-code",
        "--ignore-submodules",
    ]

    if staged:
        # Include staged changes?
        cmd.append("--staged")

    if paths is not None:
        cmd.append("--")
        cmd.extend(paths)

    try:
        cli(*cmd, repo=repo)
        return False
    except SubprocessException as e:
        if e.returncode != 1:
            raise
        return True


def add(
    paths: list[str],
    repo: str = None,
) -> bool:
    """
    Stages files to commit.
    """
    cmd = ["add", "--"]

    cli(*cmd, *paths, repo=repo)


def commit(
    message: str,
    repo: str = None,
) -> bool:
    """
    Creates a new commit.
    """
    cmd = [
        "commit",
        "--message",
        message,
    ]

    cli(*cmd, repo=repo)
