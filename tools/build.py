#!/usr/bin/env python3
"""
Compiles every plugin in plugins/*/scripting/ into build/, laid out like a server's left4dead2/
folder, together with each plugin's translations/ and configs/. Windows and Linux.

    python3 tools/build.py                  build everything
    python3 tools/build.py lef_teams_panel  build one plugin
"""
import glob
import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lefbuild import REPO, compile_plugin  # noqa: E402


def build_plugin(plugin_dir, out_sm):
    """Compiles one of our plugins into out_sm (an addons/sourcemod folder). Returns success."""
    ok = True
    name = os.path.basename(plugin_dir.rstrip("/\\"))
    for sp in sorted(glob.glob(os.path.join(plugin_dir, "scripting", "*.sp"))):
        smx = os.path.join(out_sm, "plugins", os.path.splitext(os.path.basename(sp))[0] + ".smx")
        print(f"==> {name}: {os.path.basename(sp)}")
        good, output = compile_plugin(sp, smx)
        if output:
            print(output)
        ok = ok and good
    for sub in ("translations", "configs"):
        src = os.path.join(plugin_dir, sub)
        if os.path.isdir(src):
            shutil.copytree(src, os.path.join(out_sm, sub), dirs_exist_ok=True)
    return ok


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    out_sm = os.path.join(REPO, "build", "addons", "sourcemod")
    ok = True
    for plugin_dir in sorted(glob.glob(os.path.join(REPO, "plugins", "*", ""))):
        if only and os.path.basename(plugin_dir.rstrip("/\\")) != only:
            continue
        ok = build_plugin(plugin_dir, out_sm) and ok
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
