[Español](README.es.md)

# lef_saferoom_doors — Lefordianos Saferoom Doors

Tells everyone who uses the saferoom doors. Left 4 Dead 2.

| Door | What gets announced |
|---|---|
| Start saferoom | "X opened the saferoom door." once per round, or "The saferoom door opened by itself." |
| End saferoom | By default only "X closed the end saferoom door with 2 teammate(s) still outside." With `lef_doors_end 2`, every open and close. |

Start-door opens and "closed with teammates outside" are also written to the server log, so
admins can check afterwards who shut the team out.

## Settings (`cfg/sourcemod/lef_saferoom_doors.cfg`)

| Cvar | Default | Meaning |
|---|---|---|
| `lef_doors_start` | `1` | Announce who opens the start saferoom door. |
| `lef_doors_end` | `1` | End door: 0 = off, 1 = only closing with teammates outside, 2 = every open/close. |
| `lef_doors_cooldown` | `3.0` | Seconds between messages caused by the same player (stops door spam). |

Needs [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696), which tells the start
door from the end door.

Who used the door comes from the game's `door_open`/`door_close` events (the same ones Harry Potter's
`lockdown_system` and the competitive scoremod use). Version 1.0.0 read the door's own OnOpen output,
which always names the door itself, so it said "opened by itself" every time and never reported the
end door.

## Not tested in-game yet

Compiles. Check: the start message shows once per round, the "opened by itself" case, and that a
teammate still outside (alive or down) is counted when the end door closes.
