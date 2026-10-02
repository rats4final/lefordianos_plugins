#!/usr/bin/env python3
"""
Builds our Stripper:Source configs from ZoneMod's, minus what we don't want.

Reads ZoneMod's stripper folder (from the competitive reference repo), removes the sections and
blocks listed in a rules file, and writes the result in server layout, ready to copy.

    python3 tools/make_stripper.py                 # uses the defaults below
    python3 tools/make_stripper.py --rules configs/lite/stripper_rules.txt \
                                   --out configs/lite/left4dead2/cfg/stripper/lefordianos

ZoneMod's files are split into sections, each with a boxed header:

    ; =====================================================
    ; ==                 EXPLOITS BLOCKED                ==
    ; ==      Block intentionally performed exploits     ==
    ; =====================================================

and inside a section, changes ("blocks") start with a comment line like "; --- Fix the door".
A rule removes a whole section (by its name) or a single block (by the start of its "; ---" title).

Stripper detail this script takes care of: a "{...}" entry without its own "filter:", "add:" or
"modify:" line uses the last one above it. Removing a section could silently change the mode of the
next entries, so the script re-inserts the mode line wherever that would happen.

Works the same on Windows and Linux (Python 3.8+).
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
DEFAULT_SRC = os.path.join(REPO, "..", "L4D2-Competitive-Rework", "cfg", "stripper", "zonemod")
DEFAULT_RULES = os.path.join(REPO, "configs", "lite", "stripper_rules.txt")
DEFAULT_OUT = os.path.join(REPO, "configs", "lite", "left4dead2", "cfg", "stripper", "lefordianos")

MODE_RE = re.compile(r"^\s*(filter|remove|add|modify)\s*:\s*$", re.IGNORECASE)
BOX_RE = re.compile(r"^;\s*={5,}\s*$")
NAME_RE = re.compile(r"^;\s*==\s*(.*?)\s*==\s*$")
BANNER_RE = re.compile(r"^;\s*#{5,}")
BLOCK_RE = re.compile(r"^;\s*---\s*(.*)$")


def read_rules(path):
    """Rules file: [section] headers, then 'target: item | item | ...' lines. '#' or '//' = comment."""
    rules = {"global-exclude-sections": [], "map-exclude-sections": {}, "map-exclude-blocks": {}}
    current = None
    with open(path, encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#") or line.startswith("//"):
                continue
            if line.startswith("[") and line.endswith("]"):
                current = line[1:-1].strip().lower()
                if current not in rules:
                    sys.exit(f"{path}: unknown section [{current}]")
                continue
            if current == "global-exclude-sections":
                rules[current].append(line.upper())
            elif current in ("map-exclude-sections", "map-exclude-blocks"):
                if ":" not in line:
                    sys.exit(f"{path}: expected 'map: item | item', got: {line}")
                name, items = line.split(":", 1)
                values = [i.strip() for i in items.split("|") if i.strip()]
                if current == "map-exclude-sections":
                    values = [v.upper() for v in values]
                rules[current].setdefault(name.strip().lower(), []).extend(values)
            else:
                sys.exit(f"{path}: line outside a [section]: {line}")
    return rules


def split_chunks(lines):
    """
    Splits a stripper file into chunks: ("banner"|"section"|"block"|"text", name, lines).
    A section chunk is just its boxed header; the blocks that follow carry the section's name.
    """
    chunks = []
    depth = 0
    i = 0
    section = None
    cur = None  # current chunk being filled

    def start(kind, name):
        nonlocal cur
        cur = {"kind": kind, "name": name, "section": section, "lines": []}
        chunks.append(cur)

    start("text", None)
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if depth == 0:
            # Boxed section header: "; ====" + "; == NAME ==" (+ description) + "; ===="
            if BOX_RE.match(stripped) and i + 1 < len(lines) and NAME_RE.match(lines[i + 1].strip()):
                section = NAME_RE.match(lines[i + 1].strip()).group(1).upper()
                start("section", section)
                j = i + 1
                while j < len(lines) and not BOX_RE.match(lines[j].strip()):
                    j += 1
                cur["lines"].extend(lines[i:j + 1])
                i = j + 1
                start("text", None)
                continue
            if BANNER_RE.match(stripped):
                section = None
                start("banner", None)
                cur["lines"].append(line)
                i += 1
                start("text", None)
                continue
            # A "; ---" comment starts a new block, unless it directly follows another comment
            # line of the same block header.
            m = BLOCK_RE.match(stripped)
            if m:
                title = m.group(1).strip()
                header_only = cur["kind"] == "block" and all(
                    l.strip().startswith(";") or not l.strip() for l in cur["lines"])
                if header_only:
                    cur["titles"].append(title)   # another title line of the same block
                else:
                    start("block", title)
                    cur["titles"] = [title]
        cur["lines"].append(line)
        if not stripped.startswith(";"):
            depth += line.count("{") - line.count("}")
        i += 1
    return chunks


def mode_of(line):
    m = MODE_RE.match(line)
    return m.group(1).lower() if m else None


def filter_file(lines, drop_sections, drop_blocks):
    """Returns (new_lines, removed_descriptions)."""
    chunks = split_chunks(lines)
    removed = []

    # Decide which chunks to drop.
    drop = [False] * len(chunks)
    for idx, c in enumerate(chunks):
        sec = c["section"] if c["kind"] != "section" else c["name"]
        if sec and sec in drop_sections and c["kind"] in ("section", "block", "text"):
            drop[idx] = True
            if c["kind"] == "section":
                removed.append(f"section {sec}")
        elif c["kind"] == "block":
            titles = c.get("titles", [c["name"]])
            for prefix in drop_blocks:
                if any(t.lower().startswith(prefix.lower()) for t in titles):
                    drop[idx] = True
                    removed.append(f"block \"{c['name']}\"")
                    break

    # Emit, re-inserting mode lines where removing chunks would change an entry's mode.
    out = []
    mode = None          # mode in the original file at this point
    emitted_mode = None  # mode as seen by the output so far
    depth = 0
    for idx, c in enumerate(chunks):
        if drop[idx]:
            for line in c["lines"]:
                if depth == 0 and mode_of(line):
                    mode = mode_of(line)
                if not line.strip().startswith(";"):
                    depth += line.count("{") - line.count("}")
            continue
        for line in c["lines"]:
            s = line.strip()
            if depth == 0 and mode_of(line):
                mode = mode_of(line)
                emitted_mode = mode
            elif depth == 0 and s.startswith("{") and mode is not None and emitted_mode != mode:
                out.append(f"{mode}:\n")
                emitted_mode = mode
            out.append(line)
            if not s.startswith(";"):
                depth += line.count("{") - line.count("}")
    return out, removed


def check_braces(lines, path):
    depth = 0
    for n, line in enumerate(lines, 1):
        if line.strip().startswith(";"):
            continue
        depth += line.count("{") - line.count("}")
        if depth < 0:
            sys.exit(f"{path}:{n}: unbalanced braces after filtering")
    if depth != 0:
        sys.exit(f"{path}: unbalanced braces after filtering")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--src", default=DEFAULT_SRC, help="ZoneMod stripper folder")
    ap.add_argument("--rules", default=DEFAULT_RULES)
    ap.add_argument("--out", default=DEFAULT_OUT)
    args = ap.parse_args()

    rules = read_rules(args.rules)
    src_maps = os.path.join(args.src, "maps")
    out_maps = os.path.join(args.out, "maps")
    os.makedirs(out_maps, exist_ok=True)

    report = []
    jobs = [("global_filters.cfg", os.path.join(args.src, "global_filters.cfg"), os.path.join(args.out, "global_filters.cfg"),
             set(rules["global-exclude-sections"]), [])]
    for name in sorted(os.listdir(src_maps)):
        if not name.lower().endswith(".cfg"):
            continue
        key = name[:-4].lower()
        jobs.append((name, os.path.join(src_maps, name), os.path.join(out_maps, name),
                     set(rules["map-exclude-sections"].get(key, [])), rules["map-exclude-blocks"].get(key, [])))

    seen_maps = set()
    for name, src, dst, drop_sections, drop_blocks in jobs:
        with open(src, encoding="utf-8", errors="replace", newline="") as f:
            lines = f.readlines()
        new, removed = filter_file(lines, drop_sections, drop_blocks)
        check_braces(new, dst)
        with open(dst, "w", encoding="utf-8", newline="") as f:
            f.writelines(new)
        seen_maps.add(name[:-4].lower())
        wanted = len(drop_sections) + len(drop_blocks)
        found = len(removed)
        if removed:
            report.append(f"{name}: removed " + ", ".join(removed))
        if found < wanted:
            report.append(f"WARNING {name}: {wanted} rule(s), only {found} matched - check the names in the rules file")

    for key in list(rules["map-exclude-sections"]) + list(rules["map-exclude-blocks"]):
        if key not in seen_maps:
            report.append(f"WARNING: rules mention {key}, but ZoneMod has no file for it")

    print(f"Wrote {len(jobs)} files to {args.out}")
    for line in report:
        print("  " + line)
    if any(l.startswith("WARNING") for l in report):
        sys.exit(1)


if __name__ == "__main__":
    main()
