[Español](KNOWLEDGE.es.md)

# Knowledge base

Problems we hit running the server, what causes them (or what we suspect), and what to do. One line
each; the long explanation is in the linked doc. **Status:** *confirmed* = we know the cause and the fix
worked; *suspected* = best guess, still watching; *to verify* = not looked into yet.

When something new comes up, add it here (and in `KNOWLEDGE.es.md`).

## Joining the server

| Symptom | Status | Cause | What to do |
|---|---|---|---|
| "No Steam logon" / "STEAM validation rejected", several players kicked at once | fix confirmed, cause suspected | Steam answers "ticket invalid" (code 8 in the log) for many players at once, 1.5-2 min after a map starts: most likely the server's own connection to Steam dropped | l4dtoolz with `sv_steam_bypass 1` (on in our package). Cost: SteamIDs aren't checked with Steam. [CONNECTION](CONNECTION.md#no-steam-logon--steam-validation-rejected) |
| "Duplicate client connection" then "STEAM validation rejected" | confirmed | The server still holds that player's old connection | Wait a minute, or `kickid <userid>`. [CONNECTION](CONNECTION.md#duplicate-client-connection-then-steam-validation-rejected) |
| "Reservation request with bogus payload data" when the owner starts the lobby | **suspected** | The owner's PC reaches its own server two ways (local and public IP) and mixes them | Firewall rule on the owner's PC blocking the public-IP way. Worked in the first test. [CONNECTION](CONNECTION.md#reservation-request-with-bogus-payload-data-when-the-owner-starts-the-lobby) |
| "The session is no longer available" with `connect` | suspected | The server is still reserved by a lobby that failed | Wait a minute or `sv_cookie 0`; always type the port (`:27016`). [CONNECTION](CONNECTION.md#the-session-is-no-longer-available-with-connect) |
| "Server is enforcing consistency for this file: addons/xxx.vpk" | confirmed | `sv_consistency 1` compares add-ons by path; server and player have the campaign at different paths | Same path on both: everyone uses the Workshop copy (`addons/workshop/<id>.vpk`). [CONNECTION](CONNECTION.md#server-is-enforcing-consistency-for-this-file-addons) |

## Config files

| Symptom | Status | Cause | What to do |
|---|---|---|---|
| "Unknown command" spam with pieces of Spanish words (e.g. `a de RCON`) | confirmed | The engine cuts cfg lines at accented letters | Game cfg files are ASCII only, comments too. `build_lite.py` warns |
| "Unknown command" for `sv_allowdownload`, `sv_downloadurl` | confirmed | L4D2 hides some cvars from cfg files | Set them with `sm_cvar` |
| A setting changed by vote or admin goes back after a map change | confirmed | Every map change re-runs all configs | Put permanent changes in `cfg/lefordianos/custom.cfg` (runs last); our plugins re-apply voted settings themselves |
| A value in a plugin's own `cfg/sourcemod/<plugin>.cfg` has no effect | confirmed | `lefordianos/common.cfg` and `custom.cfg` run after it and win | Change it in `custom.cfg` |
| `auto_all_bot_game_enable` "Unknown command" | confirmed | That cvar doesn't exist in L4D2 | Remove the line |
| `sm_onlyforce 1` breaks the pause vote | confirmed | It only allows admin-forced pauses | Keep `sm_onlyforce 0` |

## Plugins

| Symptom | Status | Cause | What to do |
|---|---|---|---|
| `l4d2_chainsaw_fix` fails to load on Windows | confirmed | It fixes a Linux-only crash; no Windows gamedata on purpose | Harmless; the server repo keeps it in `plugins/disabled/` |
| A plugin fails with missing gamedata / translation | confirmed | Packager missed a file (plugins load gamedata in several ways) | Fixed in `build_lite.py`; if it happens again, check how the plugin loads it |
| A prebuilt plugin fails "requires a newer Actions" | confirmed | Prebuilt `.smx` from other repos need newer extensions | We ship Actions 3.9.2 via `get_extensions.py` |
| Latin American players see English | confirmed | SourceMod gives "Spanish - Latin America" the code `las`, with no fallback to `es` | `build_lite.py` copies every `es` translation to `las` |
| Competitive plugins error about `sv_maxplayers` or Ready-Up | confirmed | They assume l4dtoolz slots / Ready-Up, which we don't run | Patched copies in `plugins/pause`, `plugins/si_class_announce` |
| `cannounce` errors "Language phrase ... not found" (hundreds in `errors_*.log`) | confirmed | With `ServerLang "es"`, SourceMod doesn't fall back to English for the server's own copy of a message (SourceTV, log), and cannounce had no Spanish | Spanish phrases ship in the package since 2026-10-08 |
| Scores reset to 0 after an admin changed or restarted the map | confirmed | The game treats any forced map change as a new match | `lef_match` gives the points back inside the same campaign (2026-10-08, not yet tested with players) |
| "Endless hordes" | **suspected** | `boomer_horde_equalizer_refactored` (off since 2026-10-04), or `l4d2_antibaiter` | Equalizer stays off; antibaiter timer at 30 s |
| No quad caps in our games (in ZoneMod they happen) | to verify | Not the settings: ours match ZoneMod (`l4d2_dominators 0`, `l4d2_fix_spawn_order`, one of each class, the game's default). With the fixed spawn rotation, a quad only comes when both support classes (boomer, spitter) are dead or waiting in the queue while smoker, hunter, jockey and charger are up: ZoneMod teams play for it (supports die or get used early) | Test one map with `sm_cvar sackorder_debug 1` (prints every class pick to chat): "over limit (reason: Dominator limit)" would mean something still blocks the 4th dominator |
| Jockey landing staggers survivors longer than expected | to verify | Probably vanilla (jockey/hunter landings stagger nearby survivors) | If not: suspects `l4d2_getup_slide_fix`, `l4d2_godframes_control_merge` |
