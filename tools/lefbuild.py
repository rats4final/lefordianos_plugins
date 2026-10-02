"""
Shared helpers for our build tools: where things are, and how to compile a plugin.
Works on Windows and Linux.
"""
import os
import platform
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
REFS = os.path.abspath(os.environ.get("REFS", os.path.join(REPO, "..")))
IS_WINDOWS = platform.system() == "Windows"


def ref(path):
    """A manifest path: '@repo/...' is inside this repo, anything else is relative to REFS."""
    if path.startswith("@repo/"):
        return os.path.join(REPO, path[len("@repo/"):])
    return os.path.join(REFS, path)


def sourcemod_dir():
    return os.path.join(HERE, "sourcemod", "current")


def find_spcomp():
    exe = "spcomp64.exe" if IS_WINDOWS else "spcomp64"
    own = os.path.join(sourcemod_dir(), exe)
    if os.path.isfile(own):
        return own, os.path.join(sourcemod_dir(), "include")
    if not IS_WINDOWS:
        comp = os.path.join(REFS, "L4D2-Competitive-Rework", "addons", "sourcemod", "scripting", "sourcemod")
        if os.path.isfile(os.path.join(comp, "spcomp64")):
            print("Note: tools/sourcemod not found, using the competitive repo's compiler "
                  "(run: python3 tools/get_sourcemod.py)", file=sys.stderr)
            return os.path.join(comp, "spcomp64"), os.path.join(comp, "include")
    sys.exit("No SourceMod compiler found. Run: python3 tools/get_sourcemod.py")


def base_includes(sm_include):
    """Third-party headers from the reference repos. Order matters: newest Left4DHooks first."""
    dirs = [
        os.path.join(REFS, "Left4DHooks", "sourcemod", "scripting", "include"),
        os.path.join(REFS, "L4D2-Competitive-Rework", "addons", "sourcemod", "scripting", "include"),
        os.path.join(REFS, "Multi-Colors", "addons", "sourcemod", "scripting", "include"),
        sm_include,
    ]
    return [d for d in dirs if os.path.isdir(d)]


def local_includes(sp_path):
    """include/ folders next to the source and in its parent folders, closest first."""
    found = []
    d = os.path.dirname(os.path.abspath(sp_path))
    stop = os.path.abspath(REFS)
    while True:
        for cand in (os.path.join(d, "include"), os.path.join(d, "scripting", "include")):
            if os.path.isdir(cand) and cand not in found:
                found.append(cand)
        if d == stop or os.path.dirname(d) == d:
            break
        d = os.path.dirname(d)
    return found


def run_spcomp(spcomp, args):
    cmd = [spcomp] + args
    # The compiler sometimes loses its executable bit when a repo is copied around.
    if not IS_WINDOWS and not os.access(spcomp, os.X_OK):
        cmd = ["/lib64/ld-linux-x86-64.so.2"] + cmd
    return subprocess.run(cmd, capture_output=True, text=True)


def compile_plugin(sp_path, out_smx, extra_includes=()):
    """Compiles one .sp. Returns (ok, compiler output)."""
    spcomp, sm_include = find_spcomp()
    includes = list(extra_includes) + local_includes(sp_path) + base_includes(sm_include)
    os.makedirs(os.path.dirname(out_smx), exist_ok=True)
    args = [f"-i{d}" for d in includes] + [sp_path, f"-o{out_smx}", "-v0"]
    result = run_spcomp(spcomp, args)
    output = (result.stdout + result.stderr).strip()
    return result.returncode == 0 and os.path.isfile(out_smx), output
