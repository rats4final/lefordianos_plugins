#!/usr/bin/env python3
"""
Prints one of Valve's own VScripts from a game install, decrypted. L4D2 ships its scripts as .nuc
files inside the .vpk archives, encrypted with ICE (key "SDhfi878"); a newer copy in update/ wins over
the base game's, as in the game.

    python3 tools/extract_vscript.py <game folder> c9m2_lots_finale > c9m2_lots_finale.nut
    (game folder = the one with left4dead2/, update/, left4dead2_dlc1/...)

Used to rebuild plugins/lef_tanktime/vscripts/ on top of today's scripts after a game update: copy
the output and put the mutation19 changes back (see that folder's file headers).
Windows and Linux.
"""
import os
import struct
import sys

SMOD = [[333, 313, 505, 369], [379, 375, 319, 391], [361, 445, 451, 397], [397, 425, 395, 505]]
SXOR = [[0x83, 0x85, 0x9b, 0xcd], [0xcc, 0xa7, 0xad, 0x41], [0x4b, 0x2e, 0xd4, 0x33], [0xea, 0xcb, 0x2e, 0x04]]
PBOX = [0x00000001, 0x00000080, 0x00000400, 0x00002000, 0x00080000, 0x00200000, 0x01000000, 0x40000000,
        0x00000008, 0x00000020, 0x00000100, 0x00004000, 0x00010000, 0x00800000, 0x04000000, 0x20000000,
        0x00000004, 0x00000010, 0x00000200, 0x00008000, 0x00020000, 0x00400000, 0x08000000, 0x10000000,
        0x00000002, 0x00000040, 0x00000800, 0x00001000, 0x00040000, 0x00100000, 0x02000000, 0x80000000]
KEYROT = [0, 1, 2, 3, 2, 1, 3, 0, 1, 3, 2, 0, 3, 1, 0, 2]
def gf_mult(a, b, m):
    res = 0
    while b:
        if b & 1: res ^= a
        a <<= 1; b >>= 1
        if a >= 256: a ^= m
    return res
def gf_exp7(b, m):
    if b == 0: return 0
    x = gf_mult(b, b, m); x = gf_mult(b, x, m); x = gf_mult(x, x, m)
    return gf_mult(b, x, m)
def perm32(x):
    res = 0; i = 0
    while x:
        if x & 1: res |= PBOX[i]
        i += 1; x >>= 1
    return res
SBOX = [[0] * 1024 for _ in range(4)]
for i in range(1024):
    col = (i >> 1) & 0xff; row = (i & 0x1) | ((i & 0x200) >> 8)
    SBOX[0][i] = perm32(gf_exp7(col ^ SXOR[0][row], SMOD[0][row]) << 24)
    SBOX[1][i] = perm32(gf_exp7(col ^ SXOR[1][row], SMOD[1][row]) << 16)
    SBOX[2][i] = perm32(gf_exp7(col ^ SXOR[2][row], SMOD[2][row]) << 8)
    SBOX[3][i] = perm32(gf_exp7(col ^ SXOR[3][row], SMOD[3][row]))
def schedule(key):
    kb = [0] * 4
    for i in range(4): kb[3 - i] = (key[i * 2] << 8) | key[i * 2 + 1]
    sched = []
    for i in range(8):
        kr = KEYROT[i]; isk = [0, 0, 0]
        for j in range(15):
            for k in range(4):
                curr = kb[(kr + k) & 3]; bit = curr & 1
                isk[j % 3] = (isk[j % 3] << 1) | bit
                kb[(kr + k) & 3] = (curr >> 1) | ((bit ^ 1) << 15)
        sched.append(isk)
    return sched
def F(p, sk):
    tl = ((p >> 16) & 0x3ff) | (((p >> 14) | (p << 18)) & 0xffc00)
    tr = (p & 0x3ff) | ((p << 2) & 0xffc00)
    al = sk[2] & (tl ^ tr); ar = al ^ tr; al ^= tl
    al ^= sk[0]; ar ^= sk[1]
    return SBOX[0][al >> 10] | SBOX[1][al & 0x3ff] | SBOX[2][ar >> 10] | SBOX[3][ar & 0x3ff]
def decrypt_block(blk, sched):
    l = int.from_bytes(blk[:4], "big"); r = int.from_bytes(blk[4:], "big")
    for i in range(7, 0, -2):
        l ^= F(r, sched[i]); r ^= F(l, sched[i - 1])
    return r.to_bytes(4, "big") + l.to_bytes(4, "big")
def decrypt(data, key=b"SDhfi878"):
    sched = schedule(key); out = bytearray(); n = len(data) // 8 * 8
    for i in range(0, n, 8): out += decrypt_block(data[i:i + 8], sched)
    return bytes(out) + data[n:]


def read_cstr(f):
    b = bytearray()
    while True:
        c = f.read(1)
        if c in (b"", b"\0"): return b.decode("latin1")
        b += c
def entries(dirpath):
    with open(dirpath, "rb") as f:
        sig, ver = struct.unpack("<II", f.read(8))
        tree = struct.unpack("<I", f.read(4))[0]
        if ver == 2: f.read(16)
        hdr = f.tell()
        while True:
            ext = read_cstr(f)
            if not ext: break
            while True:
                path = read_cstr(f)
                if not path: break
                while True:
                    name = read_cstr(f)
                    if not name: break
                    crc, pre, arch, off, length, term = struct.unpack("<IHHIIH", f.read(18))
                    preload = f.read(pre)
                    yield f"{path}/{name}.{ext}", arch, off, length, preload, hdr + tree

# Later folders win (update/ holds Valve's newer versions).
ARCHIVES = ["left4dead2", "left4dead2_dlc1", "left4dead2_dlc2", "left4dead2_dlc3", "update"]


def read_entry(dirpath, arch, off, length, preload, dataoff):
    data = preload
    if length:
        base = dirpath[:-len("_dir.vpk")]
        src = dirpath if arch == 0x7FFF else f"{base}_{arch:03d}.vpk"
        with open(src, "rb") as a:
            a.seek(off + (dataoff if arch == 0x7FFF else 0))
            data += a.read(length)
    return data


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    game, name = sys.argv[1], sys.argv[2]
    name = name[:-4] if name.endswith((".nut", ".nuc")) else name
    found = None
    for folder in ARCHIVES:
        dirpath = os.path.join(game, folder, "pak01_dir.vpk")
        if not os.path.isfile(dirpath):
            continue
        for path, arch, off, length, preload, dataoff in entries(dirpath):
            if path in (f"scripts/vscripts/{name}.nuc", f"scripts/vscripts/{name}.nut"):
                data = read_entry(dirpath, arch, off, length, preload, dataoff)
                found = (folder, decrypt(data) if path.endswith(".nuc") else data)
    if not found:
        sys.exit(f"scripts/vscripts/{name} not found in {game}")
    print(f"// from {found[0]}/pak01_dir.vpk", file=sys.stderr)
    sys.stdout.write(found[1].decode("latin1"))


if __name__ == "__main__":
    main()
