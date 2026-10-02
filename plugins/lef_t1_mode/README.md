[Español](README.es.md)

# lef_t1_mode — Lefordianos T1 Mode

A switchable "only T1 weapons" mode. Works with or without confogl. Left 4 Dead 2.

## What gets replaced

Set in `addons/sourcemod/configs/lef_t1_mode.cfg` (a `"banned" "replacement"` list; `"none"` removes
the weapon). Defaults:

| Banned | Becomes |
|---|---|
| M16, Desert rifle | SMG |
| AK-47, SG552 | Silenced SMG |
| Auto shotgun / SPAS | Pump / Chrome shotgun |
| Hunting rifle (15 rounds), Military sniper (30 rounds) | Scout |

Allowed: T1 weapons, pistols, melee, **Scout, AWP, grenade launcher, M60**. The config has
commented lines to ban the AWP, grenade launcher or M60 too. After editing, `sm_t1_reload`.

When the mode is on it converts weapon spawns at round start, weapons that appear later, and any
banned weapon a survivor picks up or carries over from the previous map.

## Turning it on and off

| How | Command |
|---|---|
| Cvar | `lef_t1_enable 1` / `0` |
| Admin | `sm_forcet1 on` / `off` (generic admin flag, `b`) |
| Players | `!t1` starts a Yes/No vote on the game's vote screen (needs the builtinvotes extension) |

If the survivors are still in the starting saferoom it applies right away; otherwise from the next
round. When survivors leave the saferoom with the mode on, chat says "Only T1 weapons this round".

A choice made by vote (`!t1`) or by an admin (`sm_forcet1`) lasts for the whole session: map changes
re-run the configs, which would switch it back, so it's applied again after them. Once the server is
empty, it goes back to `lef_t1_enable` from the configs.

## Settings (`cfg/sourcemod/lef_t1_mode.cfg`)

| Cvar | Default | Meaning |
|---|---|---|
| `lef_t1_enable` | `0` | The mode itself. |
| `lef_t1_convert_held` | `1` | Also replace banned weapons survivors pick up or carry over. |
| `lef_t1_vote_time` | `20` | Seconds the `!t1` vote stays open. |

## How it works

It uses the same weapon stocks as the competitive repo's `l4d2_weaponrules` (from l4d2util), but
keeps its own list, so it never clears another mode's weapon rules. The Scout and AWP are CS:S
weapons; like `l4d2_sniper_precache`, it precaches them every map so converting to them can't crash.

## Not tested in-game yet

Compiles. Check: spawns convert at round start, a weapon carried over from the previous map is
swapped, the `!t1` vote passes/fails correctly, and the Scout appears on maps without CS weapons.
