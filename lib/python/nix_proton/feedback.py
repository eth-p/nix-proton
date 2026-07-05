def checking_release(id: str):
    print()
    print(f"\x1b[1;34m==> Release {id}\x1b[m")


def checking_github_release(release: dict):
    checking_release(release["tagName"])
    if release["isLatest"]:
        print("\x1b[34mThis is the latest GitHub release.\x1b[m")


def known_asset(name: str):
    print(f"\x1b[32mAdd:\x1b[m     {name}")


def unknown_asset(name: str):
    print(f"\x1b[2mSkip:\x1b[m    {name}")


def detail(name: str, value: str):
    print(f"\x1b[34m{name}: \x1b[m{value}")


def caught_up():
    print("Stopping. This release was the last seen version.")
