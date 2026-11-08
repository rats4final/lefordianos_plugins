[Español](README.es.md)

# lef_client_cvars — Lefordianos Client Cvars

Checks each player's own game settings (client cvars) and kicks anyone using a value that gives an
unfair advantage: full brightness (`mat_fullbright`), no fog (`fog_*`), a bigger/brighter
flashlight (`cl_survivor_light_*`), see-through props, and so on. Left 4 Dead 2.

A standalone port of confogl's **ClientSettings** module (Confogl Team), so it works **without
confogl**. It checks the **same 59 cvars** ZoneMod does (the competitive repo's
`cfg/cvar_tracking.cfg`), listed in our `cfg/lefordianos/client_cvars.cfg`.

Third-person peeking is a different check, done by the competitive repo's
`l4d_thirdpersonshoulderblock` (also in the lite config). SMAC and Little Anti-Cheat check other
cvars (wireframe, `r_drawothermodels`...); together they cover each other.

## How it works

Every 5 seconds it asks each player for every listed cvar:

- **Value outside the allowed range:** kicked, with the cvar and the allowed value in the kick
  message, so an honest player can fix it and rejoin. Chat says who and why; the server log too.
- **The game refuses to report the cvar** (protected or missing, usually a cheat): kicked too,
  unless `lef_clientcvars_kick_missing 0`.

## The list

`cfg/lefordianos/client_cvars.cfg`, one line per cvar:

```
lef_trackclientcvar <cvar> <hasMin> <min> <hasMax> <max> [<action: 0 kick, 1 log only>]
```

The file starts with `lef_resetclientcvars`, and `common.cfg` runs it every map. `!clientcvars`
lists what's checked. The command name differs from confogl's (`confogl_trackclientcvar`) on purpose,
so both can be loaded without clashing.

## Settings (`cfg/sourcemod/lef_client_cvars.cfg`)

| Cvar | Default | Meaning |
|---|---|---|
| `lef_clientcvars_enable` | `1` | On/off. |
| `lef_clientcvars_interval` | `5.0` | Seconds between checks. |
| `lef_clientcvars_kick_missing` | `1` | Kick when the game refuses to report a cvar. |

## Own message for one cvar

Add `"Kicked Value <cvar>"` (chat) and/or `"Kick Reason Value <cvar>"` (kick screen) to
`translations/lef_client_cvars.phrases.txt` (and `es/`), with the same arguments as the general
phrases (name/cvar/value, cvar/value/allowed). `mat_fullbright` has one: it says that's cheating and how
to come back.

## In use

On the owner's server since 2026-10-03. Kicks so far (to 2026-11-08): `mat_fullbright` 10,
`cl_survivor_light_enable 0` 5, `r_flashlightmuzzleflash 0` 2, `cl_max_shadow_renderable_dist 0` 2,
`sv_consistency 0` 1. Until 1.1.0 the kick message said "allowed: g" instead of the value (SourceMod has
no `%g`).

Third person (`c_thirdpersonshoulder`) is a different plugin, `l4d_thirdpersonshoulderblock`: it moves
the player to spectators (`l4d_tpsblock_action 1`); our patched copy tells them why and how to come back.
