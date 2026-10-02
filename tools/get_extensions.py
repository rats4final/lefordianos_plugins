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

# Each extension: version, download URL(s) ({version}, {os}), and where files in the zip go:
# (zip path prefix, destination) pairs; "include" = headers, anything else = path on the server.
# Files not matching a prefix, 64-bit builds (L4D2 servers are 32-bit) and other games' builds are skipped.
EXTENSIONS = {
    # REST in Pawn: HTTP + JSON (https://github.com/ErikMinekus/sm-ripext). Used by lef_steam_bans.
    "ripext": {
        "version": "1.3.2",
        "urls": ["https://github.com/ErikMinekus/sm-ripext/releases/download/{version}/sm-ripext-{version}-linux.zip",
                 "https://github.com/ErikMinekus/sm-ripext/releases/download/{version}/sm-ripext-{version}-windows.zip"],
        "map": [("addons/sourcemod/scripting/include/", "include"),
                ("addons/sourcemod/extensions/", "addons/sourcemod/extensions/"),
                ("addons/sourcemod/configs/", "addons/sourcemod/configs/")],
    },
    # Actions (https://github.com/Vinillia/actions.ext). Newer than the competitive repo's build:
    # Harry Potter's l4d_afk_commands needs BehaviorAction.GetHandleEntity. 3.9.2 keeps every older
    # native (4.x removed some); one zip has both Windows and Linux.
    "actions": {
        "version": "3.9.2",
        "urls": ["https://github.com/Vinillia/actions.ext/releases/download/v{version}/actions.ext.zip"],
        "map": [("actions.ext/scripting/include/", "include"),
                ("actions.ext/extensions/actions.ext.2.l4d2.", "addons/sourcemod/extensions/actions.ext.2.l4d2."),
                ("actions.ext/gamedata/", "addons/sourcemod/gamedata/")],
    },
}

ROOT = os.path.join(HERE, "extensions")


def main():
    for name, ext in EXTENSIONS.items():
        version = ext["version"]
        dest = os.path.join(ROOT, name)
        stamp = os.path.join(dest, "VERSION")
        if os.path.isfile(stamp) and open(stamp).read().strip() == version:
            print(f"{name} {version} already in {dest}")
            continue

        shutil.rmtree(dest, ignore_errors=True)
        for url in ext["urls"]:
            link = url.format(version=version)
            print(f"Downloading {link}")
            archive = zipfile.ZipFile(io.BytesIO(fetch(link)))
            for member in archive.infolist():
                path = member.filename
                if member.is_dir() or "/x64/" in path:
                    continue
                for prefix, target in ext["map"]:
                    if path.startswith(prefix):
                        rest = path[len(prefix):]
                        out = (os.path.join(dest, "include", rest) if target == "include"
                               else os.path.join(dest, "package", target + rest))
                        os.makedirs(os.path.dirname(out), exist_ok=True)
                        with open(out, "wb") as f:
                            f.write(archive.read(member))
                        break

        with open(stamp, "w") as f:
            f.write(version + "\n")
        print(f"{name} {version} ready in {dest}")


if __name__ == "__main__":
    main()
