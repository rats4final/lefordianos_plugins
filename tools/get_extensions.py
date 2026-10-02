#!/usr/bin/env python3
"""
Downloads the SourceMod extensions we ship that aren't in the reference repos, into
tools/extensions/<name>/. Versions are pinned here so everyone gets the same build.

Each extension ends up as:
    tools/extensions/<name>/package/addons/...   what goes on the server (Windows .dll AND Linux .so)
    tools/extensions/<name>/include/             headers to compile plugins against

    python3 tools/get_extensions.py
"""
import io
import os
import shutil
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from get_sourcemod import fetch  # noqa: E402
from lefbuild import HERE  # noqa: E402

# name: (version, URL with {version} and {os}, platforms)
EXTENSIONS = {
    # REST in Pawn: HTTP + JSON (https://github.com/ErikMinekus/sm-ripext). Used by lef_steam_bans.
    "ripext": ("1.3.2",
               "https://github.com/ErikMinekus/sm-ripext/releases/download/{version}/sm-ripext-{version}-{os}.zip",
               ("linux", "windows")),
}

ROOT = os.path.join(HERE, "extensions")
INCLUDE_PREFIX = "addons/sourcemod/scripting/include/"


def main():
    for name, (version, url, platforms) in EXTENSIONS.items():
        dest = os.path.join(ROOT, name)
        stamp = os.path.join(dest, "VERSION")
        if os.path.isfile(stamp) and open(stamp).read().strip() == version:
            print(f"{name} {version} already in {dest}")
            continue

        shutil.rmtree(dest, ignore_errors=True)
        for osname in platforms:
            link = url.format(version=version, os=osname)
            print(f"Downloading {link}")
            archive = zipfile.ZipFile(io.BytesIO(fetch(link)))
            for member in archive.infolist():
                path = member.filename
                if member.is_dir() or "/x64/" in path:   # L4D2 servers are 32-bit
                    continue
                if path.startswith(INCLUDE_PREFIX):
                    target = os.path.join(dest, "include", path[len(INCLUDE_PREFIX):])
                elif path.startswith("addons/sourcemod/scripting/"):
                    continue
                else:
                    target = os.path.join(dest, "package", path)
                os.makedirs(os.path.dirname(target), exist_ok=True)
                with open(target, "wb") as f:
                    f.write(archive.read(member))

        with open(stamp, "w") as f:
            f.write(version + "\n")
        print(f"{name} {version} ready in {dest}")


if __name__ == "__main__":
    main()
