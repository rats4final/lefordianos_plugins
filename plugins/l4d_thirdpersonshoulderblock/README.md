[Español](README.es.md)

# l4d_thirdpersonshoulderblock (patched)

**Thirdpersonshoulder Block** by Don, from L4D2-Competitive-Rework
(`addons/sourcemod/scripting/l4d_thirdpersonshoulderblock.sp`, version 1.5). Every few seconds it checks
each player on a team for the third person camera (`c_thirdpersonshoulder`), which lets you look around
corners. With `l4d_tpsblock_action 1` (default) the player is moved to spectators; with 0, kicked.

## Our change (1.5-lef1)

Upstream only said "In order to play enter c_thirdpersonshoulder 0 on your console" in chat, right as the
player was moved, so people didn't know **why** they were in spectators. Now the player is told in chat
**and in the hint box** that it's because their third person camera is on (or their game hides that
cvar), what to type (`c_thirdpersonshoulder 0`) and how to come back (`!survivors` / `!infected`).
English and Spanish phrases in `translations/`.

Nothing else changed.
