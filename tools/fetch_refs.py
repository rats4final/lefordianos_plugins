#!/usr/bin/env python3
"""
Clones the reference repos listed in tools/refs.txt next to this repo (or into $REFS), checked
out at the pinned commits, so the build tools and docs find them. Needs git. Windows and Linux.

    python3 tools/fetch_refs.py            clone missing repos at the pinned commits
    python3 tools/fetch_refs.py --update   also move existing ones to the pinned commits
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lefbuild import HERE, REFS  # noqa: E402


def git(*args, cwd=None):
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)


def main():
    update = "--update" in sys.argv
    with open(os.path.join(HERE, "refs.txt")) as f:
        entries = [l.split() for l in f if l.strip() and not l.lstrip().startswith("#")]

    for name, url, commit in entries:
        target = os.path.join(REFS, name)
        if not os.path.isdir(os.path.join(target, ".git")):
            print(f"==> cloning {name}")
            r = git("clone", "-q", url, target)
            if r.returncode != 0:
                print(r.stderr.strip())
                continue
        elif not update:
            print(f"==> {name} already there (use --update to move it to the pinned commit)")
            continue
        if git("fetch", "-q", "origin", commit, cwd=target).returncode != 0:
            git("fetch", "-q", "origin", cwd=target)
        r = git("-c", "advice.detachedHead=false", "checkout", "-q", commit, cwd=target)
        print(f"    {name} @ {commit[:9]}" if r.returncode == 0 else f"    {name}: {r.stderr.strip()}")


if __name__ == "__main__":
    main()
