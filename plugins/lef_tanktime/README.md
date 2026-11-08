[Español](README.es.md)

# lef_tanktime — Lefordianos Tank!Time!

The **Taaannnk!!** mutation (`mutation19`) for versus: every infected is a tank. A port of
Merc1less' [Tank!Time!](https://forums.alliedmods.net/showthread.php?t=248745) 1.2.3, which makes
that mutation playable in versus. Left 4 Dead 2.

**Only active in mutation19.** In every other mode it does nothing, and its map changes stay off.

## How the mode plays

- Up to **4 tanks** on the infected team. They spawn together **15 s** after the survivors leave the
  saferoom; each dead tank comes back **30 s** later. Bot tanks fill empty places; a player who joins
  the infected takes over a bot tank, or the next spawn.
- **Both halves use the same tank spots.** Tanks spawning in known bad places (per map) are moved to
  good ones. The witch spawns at the same spot in both halves.
- **Finales**: the game allows a single bot tank, so the human tanks share 4 tanks' worth of health.
- Survivors: **`!slayme`** while incapacitated (saves the team time); crawling to the saferoom is on.
- An **info panel** shows the tank you aim at (survivors: its name; infected: its health).
- `!ttcfg` shows the options in use.

## Settings (`cfg/sourcemod/lef_tanktime.cfg`)

| Cvar | Default | What |
|---|---|---|
| `lef_tanktime_options` | `55` | Add up: 1 bot tanks, 2 crawling, 4 info panel, 8 tank health when it incaps you, 16 tank and witch every map, 32 no "regular" tank from the director, 64 shotgun mode, 128 shotgun mode keeps tier 1. Read when the mode starts. |
| `lef_tanktime_spawn_time` | `15` | Seconds after leaving the saferoom before the tanks spawn |
| `lef_tanktime_respawn_time` | `30` | Seconds before a dead tank spawns again |
| `lef_tanktime_tank_health` | `0` | Tank health (0 = the game's) |
| `lef_tanktime_bigguns_limit` | `2` | Shotgun mode: big guns per round |
| `lef_tanktime_regular_tank_color` | `255 0 0 255` | Color of the director's "regular" tank |
| `lef_tanktime_restart_command` | (empty) | Run when a round starts during the intro (empty = restart the map) |

Per-map data (bot tank names, bad spawn areas, finale spawn limits): `addons/sourcemod/configs/lef_tanktime.cfg`.

## What comes with it

- **Map changes** (`stripper/maps/`, 22 maps): entities that only switch on when this plugin fires
  the `relay_tt_mutation19` relay, i.e. in mutation19 (faster finale doors and events, the elevator
  in c1m1/c4m2/c8m4...). `tools/make_stripper.py` appends them to our Stripper files.
- **Finale VScripts** (`vscripts/`, 6 scripts, shipped as `scripts/vscripts/`): **today's Valve
  scripts** plus Tank!Time!'s changes inside `if mutation19` (6 gas cans in c1m4/c6m3, no director
  tank in c9m2, bosses allowed early in c7m3). Tank!Time!'s own copies were based on older Valve
  scripts and would have undone later fixes (e.g. `GetGameModeBase()`, c9m2's finale music) in every
  mode; ours are identical to the game's outside mutation19.
- **lef_mode_plugins** turns off the versus plugins that would fight it (tank rotation, spawn order,
  boss chances, tank announcements); see its README.

## What changed from the original

- **Left4DHooks** (`L4D_ReplaceTank`, `L4D_TakeOverZombieBot`) instead of its own gamedata
  signatures, which break when the game updates. New syntax, colors.inc, en/es translations,
  `lef_tanktime_*` cvars, map data in `configs/lef_tanktime.cfg`.
- **Bugs fixed:** its chat listener swallowed every chat message starting with `!` while the mode was
  on (other plugins' commands too), now `!slayme`/`!ttcfg` are normal commands; the info panel timer
  stacked up every round; "FixedFirstSpawnPos" was read and thrown away; shotgun mode missed the
  SG552 spawns; an error (out of bounds) when every respawn slot was busy.
- **Map fixes:** in c11m3 its Stripper file pointed the fuel barricade at a relay that didn't exist
  (`relay_event_default` instead of `relay_minifinale_default`), so in **every** mode the fire would
  never stop after breaking it. In c5m2 an output named the wrong relay (only mattered in mutation19).
- The relay fires at round start (the owner's own build of the original did this instead of waiting
  1 second); director settings are applied again after each map's configs.

## Needs

Left4DHooks, colors.inc, Stripper:Source (for the map changes). Not yet tested with players
(2026-11-08).

Original plugin, map changes and VScripts: **Merc1less** (Tank!Time!, AlliedModders). Spanish phrases
partly from Torpedo's translation.
