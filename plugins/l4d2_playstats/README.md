[Español](README.es.md)

# l4d2_playstats (patched)

**Player Statistics** by Tabun and A1m`, from L4D2-Competitive-Rework
(`addons/sourcemod/scripting/l4d2_playstats.sp`, version 1.1.4, upstream commit `f8df6a13`).

End-of-round stats (MVP, accuracy, skills, friendly fire), kept even when players disconnect.

## Our change (1.1.4-lef1)

The tables are written to the console in 4 KB blocks, at most 10 of them, 4 rows each. They list every
player tracked this session (up to 64, including people who already left), so after a long night the
friendly-fire table needed an 11th block: "Array index out-of-bounds (index 10, limit 10)". Now there is
room for 32 blocks (`MAXCHUNKS`), enough for 64 players plus headers. Nothing else changed.
