def release(tag: str):
    print()
    print(f"\x1b[1;34m==> Release {tag}\x1b[m")


def version(version: str):
    print(f"\x1b[34mVersion: \x1b[m{version}")


def caught_up():
    print("Stopping. This release was the last-seen version.")
