#!/usr/bin/env python3
"""
Builds the lite config package: everything listed in configs/lite/manifest.txt, laid out like a
server's left4dead2/ folder, in build/lite/left4dead2/. Copy that folder over the server's.
Windows and Linux (needs the reference repos, see tools/fetch_refs.py, and our compiler,
see tools/get_sourcemod.py).

    python3 tools/build_lite.py

For each plugin it also finds the gamedata and translation files it needs, by reading the
plugin's source for LoadGameConfigFile(...) and LoadTranslations(...). Then it checks that every
gamedata file has Windows and Linux entries and every extension has both .dll and .so builds.
"""
import glob
import os
import re
import shlex
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lefbuild import REFS, REPO, compile_plugin, ref  # noqa: E402

MANIFEST = os.path.join(REPO, "configs", "lite", "manifest.txt")
OUT = os.path.join(REPO, "build", "lite", "left4dead2")
SM = os.path.join(OUT, "addons", "sourcemod")
PLUGIN_DIR = os.path.join(SM, "plugins", "lefordianos")

# Shipped with SourceMod itself; never copied from the reference repos.
CORE_TRANSLATIONS = {
    "common.phrases", "core.phrases", "adminhelp.phrases", "adminmenu.phrases", "antiflood.phrases",
    "basebans.phrases", "basecomm.phrases", "basecommands.phrases", "basefuncommands.phrases",
    "basefunvotes.phrases", "basetriggers.phrases", "basevotes.phrases", "clientprefs.phrases",
    "funcommands.phrases", "funvotes.phrases", "mapchooser.phrases", "nextmap.phrases",
    "nominations.phrases", "playercommands.phrases", "plugin.basecommands", "reservedslots.phrases",
    "rockthevote.phrases", "sounds.phrases", "sqladmins.phrases",
}
CORE_GAMEDATA = {"sdktools.games", "sdkhooks.games", "core.games", "funcommands.games", "left4dhooks.l4d2"}

# Gamedata that only exists for one platform on purpose (the plugin fixes a one-platform bug and
# simply doesn't load on the other).
ONE_PLATFORM_GAMEDATA = {"chainsaw_fix"}  # Harry's l4d2_chainsaw_fix: Linux-only crash

# Where our patched copies of other people's plugins keep their gamedata/translations.
FALLBACK_ROOTS = ["L4D2-Competitive-Rework"]

warnings = []
contents = []


def warn(msg):
    warnings.append(msg)
    print("  WARNING: " + msg)


def copy_file(src, dst_rel):
    dst = os.path.join(OUT, dst_rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)


def copy_dir(src, dst_rel):
    shutil.copytree(src, os.path.join(OUT, dst_rel), dirs_exist_ok=True)


def repo_root(path):
    """The reference repo a path belongs to (first folder under REFS), or this repo."""
    path = os.path.abspath(path)
    if path.startswith(os.path.abspath(REPO) + os.sep):
        return REPO
    rel = os.path.relpath(path, REFS)
    return os.path.join(REFS, rel.split(os.sep)[0])


def plugin_sources(sp):
    """The main .sp plus files in a folder named like it (e.g. scripting/lilac/*.sp)."""
    files = [sp]
    sub = os.path.splitext(sp)[0]
    if os.path.isdir(sub):
        files += glob.glob(os.path.join(sub, "**", "*.sp"), recursive=True)
    return files


def wanted_names(sp, call_regex):
    """Quoted names passed to the calls matched by call_regex, resolving simple #defines."""
    text = "".join(open(f, encoding="utf-8", errors="replace").read() for f in plugin_sources(sp))
    # #defines, including ones joined with SourcePawn's "..." operator:
    #   #define PLUGIN_NAME "x"   #define TRANSLATION_FILE PLUGIN_NAME ... ".phrases"
    raw = dict(re.findall(r'#define\s+(\w+)[ \t]+([^\n]+)', text))

    def resolve(expr, depth=0):
        out = ""
        for part in expr.split("..."):
            part = part.split("//")[0].strip()
            if part.startswith('"') and part.endswith('"') and len(part) >= 2:
                out += part[1:-1]
            elif part in raw and depth < 5:
                value = resolve(raw[part], depth + 1)
                if value is None:
                    return None
                out += value
            else:
                return None
        return out

    names = set()
    for arg in re.findall(call_regex + r'\(\s*([^,)]+)', text):
        value = resolve(arg.strip())
        if value:
            names.add(value)
    return names


def find_files(root, filename, folder_hint):
    """All copies of filename under root that live in a folder named folder_hint (any depth)."""
    hits = []
    for path in glob.glob(os.path.join(root, "**", filename), recursive=True):
        parts = os.path.relpath(path, root).split(os.sep)
        if folder_hint in parts and "/.git/" not in path.replace(os.sep, "/"):
            hits.append(path)
    return hits


def locate(sp, root, filename, folder_hint):
    """Looks in the plugin's repo, then next to the .sp, then in the fallback repos."""
    hits = find_files(root, filename, folder_hint)
    if not hits and os.path.isfile(os.path.join(os.path.dirname(sp), filename)):
        hits = [os.path.join(os.path.dirname(sp), filename)]
    for fallback in FALLBACK_ROOTS:
        if hits:
            break
        hits = find_files(os.path.join(REFS, fallback), filename, folder_hint)
    return hits


def copy_dependencies(sp, label):
    root = repo_root(sp)
    # Gamedata
    # Old style LoadGameConfigFile("x") and new style new GameData("x") / new GameDataWrapper("x").
    for name in wanted_names(sp, r"(?:LoadGameConfigFile|new\s+GameData\w*)"):
        name = name[:-4] if name.endswith(".txt") else name
        if name in CORE_GAMEDATA:
            continue
        hits = locate(sp, root, name + ".txt", "gamedata")
        if not hits:
            if not os.path.isfile(os.path.join(SM, "gamedata", name + ".txt")):
                warn(f"{label}: gamedata '{name}.txt' not found")
            continue
        copy_file(hits[0], os.path.join("addons", "sourcemod", "gamedata", name + ".txt"))
    # Translations (base file + language folders)
    for name in wanted_names(sp, r"Load(?:Plugin)?Translations?"):
        name = name[:-4] if name.endswith(".txt") else name
        if name in CORE_TRANSLATIONS:
            continue
        hits = locate(sp, root, name + ".txt", "translations")
        if not hits:
            if not os.path.isfile(os.path.join(SM, "translations", name + ".txt")):
                warn(f"{label}: translation '{name}.txt' not found")
            continue
        for hit in hits:
            parts = hit.split(os.sep)
            lang_rel = parts[len(parts) - 1 - parts[::-1].index("translations") + 1:] if "translations" in parts else [os.path.basename(hit)]
            copy_file(hit, os.path.join("addons", "sourcemod", "translations", *lang_rel))


def plugin_dest(name, subdir):
    return os.path.join(PLUGIN_DIR, subdir, name + ".smx") if subdir else os.path.join(PLUGIN_DIR, name + ".smx")


def handle(kind, args):
    if kind == "file":
        src, dst = args
        if not os.path.isfile(ref(src)):
            return warn(f"missing file {src}")
        copy_file(ref(src), dst)
    elif kind == "dir":
        src, dst = args
        if not os.path.isdir(ref(src)):
            return warn(f"missing folder {src}")
        copy_dir(ref(src), dst)
    elif kind == "smx":
        smx, sp = ref(args[0]), ref(args[1])
        subdir = args[2] if len(args) > 2 else ""
        name = os.path.splitext(os.path.basename(smx))[0]
        if not os.path.isfile(smx):
            return warn(f"missing {args[0]}")
        dst = plugin_dest(name, subdir)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(smx, dst)
        contents.append(os.path.relpath(dst, OUT))
        if os.path.isfile(sp):
            copy_dependencies(sp, name)
        else:
            warn(f"{name}: source {args[1]} not found, gamedata/translations not checked")
    elif kind == "sp":
        sp = ref(args[0])
        subdir = args[1] if len(args) > 1 else ""
        name = os.path.splitext(os.path.basename(sp))[0]
        dst = plugin_dest(name, subdir)
        ok, output = compile_plugin(sp, dst)
        if not ok:
            print(output)
            return warn(f"{name}: failed to compile")
        contents.append(os.path.relpath(dst, OUT))
        copy_dependencies(sp, name)
    elif kind == "ours":
        plugin = os.path.join(REPO, "plugins", args[0])
        for sp in sorted(glob.glob(os.path.join(plugin, "scripting", "*.sp"))):
            name = os.path.splitext(os.path.basename(sp))[0]
            dst = plugin_dest(name, "")
            ok, output = compile_plugin(sp, dst)
            if not ok:
                print(output)
                warn(f"{name}: failed to compile")
                continue
            contents.append(os.path.relpath(dst, OUT))
            copy_dependencies(sp, name)
        for sub in ("translations", "configs"):
            if os.path.isdir(os.path.join(plugin, sub)):
                copy_dir(os.path.join(plugin, sub), os.path.join("addons", "sourcemod", sub))
    else:
        warn(f"unknown manifest entry '{kind}'")


def check_platforms():
    for path in sorted(glob.glob(os.path.join(SM, "gamedata", "**", "*.txt"), recursive=True)):
        text = open(path, encoding="utf-8", errors="replace").read().lower()
        has_linux = '"linux"' in text
        has_windows = '"windows"' in text
        name = os.path.relpath(path, SM)
        if os.path.splitext(os.path.basename(path))[0] in ONE_PLATFORM_GAMEDATA:
            continue
        if has_linux != has_windows:
            warn(f"{name} has {'only Linux' if has_linux else 'only Windows'} entries")
    exts = {os.path.splitext(f)[0] for f in os.listdir(os.path.join(SM, "extensions"))
            if f.endswith((".so", ".dll"))} if os.path.isdir(os.path.join(SM, "extensions")) else set()
    for ext in sorted(exts):
        for suffix in (".so", ".dll"):
            if not os.path.isfile(os.path.join(SM, "extensions", ext + suffix)):
                warn(f"extension {ext} has no {suffix} build")


def check_cfg_ascii():
    """
    The game's own cfg reader (exec, server.cfg, autoexec) breaks a line at any non-ASCII byte, so an
    accent inside a // comment turns the rest of that comment into a command ("Unknown command" spam,
    and a real command if the words happen to match one). Stripper's map files are read by Stripper,
    not the game, so they may keep accents.
    """
    for path in sorted(glob.glob(os.path.join(OUT, "cfg", "**", "*.cfg"), recursive=True)):
        rel = os.path.relpath(path, OUT)
        if rel.split(os.sep)[1] == "stripper":
            continue
        with open(path, "rb") as f:
            for number, line in enumerate(f, 1):
                if not line.isascii():
                    warn(f"{rel}:{number} has non-ASCII characters (accents break game cfg files)")
                    break


LANG_ES_LINE = re.compile(r'^(\s*)"es"(\s+)(".*")\s*$')


def add_latam_spanish():
    """
    SourceMod gives players with Steam in "Spanish - Latin America" the language code "las", a
    different language from Spain's "es", and doesn't fall back from one to the other. Without this
    they'd see English everywhere. So every Spanish translation in the package also becomes Latin
    American Spanish: translations/es/x.txt -> translations/las/x.txt, and inside single-file
    translations each "es" line gets a "las" copy.
    """
    root = os.path.join(OUT, "addons", "sourcemod", "translations")
    es_dir, las_dir = os.path.join(root, "es"), os.path.join(root, "las")
    if os.path.isdir(es_dir):
        for name in os.listdir(es_dir):
            target = os.path.join(las_dir, name)
            if os.path.exists(target):
                continue
            with open(os.path.join(es_dir, name), encoding="utf-8", errors="replace") as f:
                lines = f.readlines()
            os.makedirs(las_dir, exist_ok=True)
            with open(target, "w", encoding="utf-8", newline="") as f:
                f.writelines(LANG_ES_LINE.sub(r'\1"las"\2\3', l.rstrip("\r\n")) + "\n" for l in lines)
    for name in os.listdir(root):
        path = os.path.join(root, name)
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
        if '"es"' not in text or '"las"' in text:
            continue
        out = []
        for line in text.splitlines():
            out.append(line)
            m = LANG_ES_LINE.match(line)
            if m:
                out.append(f'{m.group(1)}"las"{m.group(2)}{m.group(3)}')
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write("\n".join(out) + "\n")


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)
    with open(MANIFEST, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            kind, *args = shlex.split(line)
            print(f"{kind:5} {args[0]}")
            handle(kind, args)

    add_latam_spanish()
    check_platforms()
    check_cfg_ascii()

    listing = os.path.join(os.path.dirname(OUT), "CONTENTS.txt")
    with open(listing, "w", encoding="utf-8") as f:
        f.write("# Plugins in this package (all go in addons/sourcemod/plugins/lefordianos/)\n")
        f.writelines(p.replace(os.sep, "/") + "\n" for p in sorted(contents))
    print(f"\n{len(contents)} plugins -> {OUT}")
    print(f"List: {listing}")
    if warnings:
        print(f"\n{len(warnings)} warning(s):")
        for w in warnings:
            print("  - " + w)
        sys.exit(1)


if __name__ == "__main__":
    main()
