[Español](README.es.md)

# lef_boss_spawns — Lefordianos Boss Spawns

Makes versus tanks and witches **fair and known for both teams**. Left 4 Dead 2, versus only.

## The problems it fixes

- **Surprise tanks.** The first survivor team runs into a tank nobody announced; the second
  team knows it's coming and plays safe. Now the flow is announced to everyone when survivors
  leave the saferoom.
- **Different spots for each team.** Vanilla can spawn the tank *before* a drop (like a manhole)
  for one team and *after* it for the other. Now the second half's tank and witch spawn on the
  exact spot they used in the first half.
- **Always a tank / never a surprise map.** Each map rolls a chance (e.g. 80% tank, 60% witch).
  Some maps have no tank or no witch, but the roll is made once per map, so **both teams get the
  same bosses**.

## How it fits with other plugins

| Plugin | Needed? | What it adds |
|---|---|---|
| `witch_and_tankifier` (+ `l4d2lib`) | Recommended | Picks good flows, avoiding bad spots listed for 108 maps, and keeps the witch away from the tank. Without it the game's own random flows are used. |
| `l4d_boss_percent` | Optional | If loaded, it does the announcing and adds `!boss`/`!tank`/`!witch`; we tell it which boss is off ("None"). Without it, this plugin announces by itself. |
| confogl | No | confogl has the same spawn locking (`confogl_lock_boss_spawns`). If it's loaded with that on, this plugin leaves locking to confogl. |

None of them need Ready-Up.

## Commands and settings

`!bosses` shows this map's tank and witch flow.

`cfg/sourcemod/lef_boss_spawns.cfg` (created on first load):

| Cvar | Default | Meaning |
|---|---|---|
| `lef_boss_tank_chance` | `100` | % chance a map has a flow tank. |
| `lef_boss_witch_chance` | `100` | % chance a map has a flow witch. |
| `lef_boss_skip_finales` | `1` | Don't touch finale maps (their tanks are scripted). |
| `lef_boss_lock_spawns` | `1` | Second-half bosses spawn on the first half's spot. |
| `lef_boss_remind_interval` | `120` | While a tank is still to come, remind its spot in chat every this many seconds ("Tank at 63%, you're at 41%"). `0` = off. |
| `lef_boss_warn_distance` | `5` | Warn (chat + hint) when survivors are within this many percent of the tank. Progress is measured like `!current`. `0` = off. |
| `lef_boss_announce` | `1` | Announce flows when survivors leave the saferoom (only when `l4d_boss_percent` isn't loaded). |

Set the vanilla `versus_tank_chance` / `versus_witch_chance` cvars to `1` so this plugin's roll is
the only one; otherwise both chances stack.

## Credits

Spawn locking is a standalone port of confogl's BossSpawning module (Confogl Team), including
its special cases: finale tanks aren't moved, c5m5's tank isn't locked, and second-half witches
that spawn at round start are removed (except c6m1's wedding witches). Not ported: confogl's
`tank_z_fix` for stuck tank spawns, which needs confogl's map data.

## Not tested in-game yet

It compiles; things to check on a server: a map rolling "no tank" shows "None"/"none this map" for
both halves, the second-half tank appears where the first one did, and finales are untouched.
