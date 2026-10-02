#!/usr/bin/env python3
"""
Downloads the SourceMod compiler and include files we build with into tools/sourcemod/.
The version is pinned in tools/SOURCEMOD_VERSION so everyone builds with the same one.
Picks the Windows or Linux build automatically.

    python3 tools/get_sourcemod.py            download the pinned version
    python3 tools/get_sourcemod.py latest     download the newest 1.12 build and pin it
"""
import io
import os
import shutil
import sys
import tarfile
import urllib.request
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lefbuild import HERE, IS_WINDOWS  # noqa: E402

BRANCH = "1.12"
DROP = f"https://sm.alliedmods.net/smdrop/{BRANCH}"


def fetch(url):
    # The download server rejects Python's default User-Agent (HTTP 403), so send a normal one.
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (lefordianos_plugins build tools)"})
    with urllib.request.urlopen(req) as r:
        return r.read()


def main():
    pin = os.path.join(HERE, "SOURCEMOD_VERSION")
    version = open(pin).read().strip()
    osname = "windows" if IS_WINDOWS else "linux"

    if len(sys.argv) > 1 and sys.argv[1] == "latest":
        name = fetch(f"{DROP}/sourcemod-latest-{osname}").decode().strip()
        version = name[len("sourcemod-"):].rsplit("-", 1)[0]
        with open(pin, "w") as f:
            f.write(version + "\n")

    root = os.path.join(HERE, "sourcemod")
    dest = os.path.join(root, version)
    exe = os.path.join(dest, "spcomp64.exe" if IS_WINDOWS else "spcomp64")

    if os.path.isfile(exe):
        print(f"SourceMod {version} already in {dest}")
    else:
        ext = "zip" if IS_WINDOWS else "tar.gz"
        url = f"{DROP}/sourcemod-{version}-{osname}.{ext}"
        print(f"Downloading {url}")
        data = fetch(url)
        os.makedirs(dest, exist_ok=True)
        prefix = "addons/sourcemod/scripting/"
        if IS_WINDOWS:
            archive = zipfile.ZipFile(io.BytesIO(data))
            members = [(m, m.filename) for m in archive.infolist()]
            read = lambda m: archive.read(m)  # noqa: E731
        else:
            archive = tarfile.open(fileobj=io.BytesIO(data), mode="r:gz")
            members = [(m, m.name) for m in archive.getmembers() if m.isfile()]
            read = lambda m: archive.extractfile(m).read()  # noqa: E731
        for member, name in members:
            if not name.startswith(prefix):
                continue
            rel = name[len(prefix):]
            if rel.startswith("include/") or rel in ("spcomp64", "spcomp64.exe"):
                target = os.path.join(dest, rel)
                os.makedirs(os.path.dirname(target), exist_ok=True)
                with open(target, "wb") as f:
                    f.write(read(member))
        if not IS_WINDOWS:
            os.chmod(exe, 0o755)

    # "current" points at the pinned version (a copy on Windows, where symlinks need admin rights).
    current = os.path.join(root, "current")
    if os.path.islink(current) or os.path.isfile(current):
        os.remove(current)
    elif os.path.isdir(current):
        shutil.rmtree(current)
    if IS_WINDOWS:
        shutil.copytree(dest, current)
    else:
        os.symlink(version, current)
    print(f"SourceMod {version} ready in {current}")


if __name__ == "__main__":
    main()
