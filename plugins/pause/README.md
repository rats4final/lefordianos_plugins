[Español](README.es.md)

# pause (patched)

**Pause plugin** by CanadaRox, Sir, Forgetest and A1m`, from L4D2-Competitive-Rework
(`addons/sourcemod/scripting/pause.sp`, version 6.9.0, upstream commit `f8df6a13`).

`!pause` pauses the game; both teams type `!ready` to unpause; admins have `sm_forcepause` /
`sm_forceunpause`. With `lef_votes`, players can only pause through a vote.

## Our change (6.9.0-lef1)

While paused, the panel showed "players / max players" using `sv_maxplayers`, a cvar that only exists
when l4dtoolz is installed. Without l4dtoolz it threw "Invalid convar handle" every second. Now it uses
`sv_maxplayers` if it exists and the game's own maximum otherwise. Nothing else changed.
