#!/usr/bin/env python3
"""
Copies the built lite package (build/lite/left4dead2/) into a checkout of the owner's server repo
(github.com/rats4final/l4d2-server, cloned next to this one by default), so the server repo always
carries the current config. Then commit there, and `git pull` on the server.

    python3 tools/build_lite.py
    python3 tools/sync_server.py [path to l4d2-server]     (default: ../l4d2-server)

It remembers what it copied in <server repo>/lefordianos-package.txt, so a file that leaves the
package is also removed from the server repo next time. It never touches files the package doesn't
ship (server.cfg, custom.cfg, admins.cfg, the roster, secrets...). A plugin the owner moved to
addons/sourcemod/plugins/disabled/ stays there: its package copy is skipped.
Windows and Linux.
"""
import filecmp
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lefbuild import REPO  # noqa: E402

PKG = os.path.join(REPO, "build", "lite", "left4dead2")
LIST_NAME = "lefordianos-package.txt"
PLUGINS = "addons/sourcemod/plugins/"


def package_files():
    files = []
    for root, _, names in os.walk(PKG):
        for name in names:
            files.append(os.path.relpath(os.path.join(root, name), PKG).replace(os.sep, "/"))
    return sorted(files)


def disabled_on_server(game, rel):
    """True if the owner moved this plugin to plugins/disabled/ on the server."""
    if not (rel.startswith(PLUGINS) and rel.endswith(".smx")):
        return False
    return os.path.isfile(os.path.join(game, PLUGINS, "disabled", os.path.basename(rel)))


def main():
    server = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "..", "l4d2-server"))
    game = os.path.join(server, "l4d2", "left4dead2")
    if not os.path.isdir(PKG):
        sys.exit("No package yet. Run: python3 tools/build_lite.py")
    if not os.path.isdir(game):
        sys.exit(f"{server} doesn't look like the server repo (no l4d2/left4dead2/). "
                 "Clone it: git clone https://github.com/rats4final/l4d2-server.git")

    list_path = os.path.join(server, LIST_NAME)
    old = set()
    if os.path.isfile(list_path):
        with open(list_path, encoding="utf-8") as f:
            old = {line.strip() for line in f if line.strip() and not line.startswith("#")}

    new, skipped = [], []
    added = updated = 0
    for rel in package_files():
        if disabled_on_server(game, rel):
            skipped.append(rel)
            continue
        new.append(rel)
        src, dst = os.path.join(PKG, rel), os.path.join(game, rel)
        if os.path.isfile(dst):
            if filecmp.cmp(src, dst, shallow=False):
                continue
            updated += 1
        else:
            added += 1
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)

    removed = []
    for rel in sorted(old - set(new) - set(skipped)):
        path = os.path.join(game, rel)
        if os.path.isfile(path):
            os.remove(path)
            removed.append(rel)
            parent = os.path.dirname(path)
            while parent != game and os.path.isdir(parent) and not os.listdir(parent):
                os.rmdir(parent)
                parent = os.path.dirname(parent)

    with open(list_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("# Files under l4d2/left4dead2/ that come from the lefordianos_plugins lite package.\n"
                "# Written by tools/sync_server.py there; don't edit these files here, they get replaced.\n")
        f.writelines(rel + "\n" for rel in new)

    print(f"{len(new)} package files -> {game}")
    print(f"  {added} new, {updated} updated, {len(removed)} removed (left the package)")
    for rel in removed:
        print(f"  removed {rel}")
    for rel in skipped:
        print(f"  skipped {rel} (in plugins/disabled/ on the server)")
    if not old:
        print("  (first sync: nothing removed; old copies of the same plugins elsewhere stay)")
    print(f"\nNext: review and commit in {server} (git status), then git pull on the server.")


if __name__ == "__main__":
    main()
