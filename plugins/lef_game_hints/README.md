[Español](README.es.md)

# lef_game_hints — Lefordianos Game Hints

Friendly warnings and tips during the round. **Nothing here punishes anyone**: it only talks.
Left 4 Dead 2.

## Rushing and falling behind (survivors)

A survivor far **ahead** of the team, or far **behind** it, gets a chat and hint-box warning;
the other survivors are told too (`lef_hints_pace_tell_team`). Distances are a share of the map's
length, like Harry Potter's `no-rushing` (which teleports and slays; we only warn).

No warnings:
- for the **last survivor standing** (they do whatever they need to, like running to the saferoom);
- while a **tank** is up (running away is fine);
- during **finales**, and for 90 s after a **panic event** (alarms, gauntlets: running is the point);
- once inside the end saferoom.

## Holding an infected (versus)

- A special infected kept **alive a long time without attacking** (`lef_hints_hold_time`, 60 s) gets a
  reminder. Attacking or using its ability resets the clock.
- A **ghost that could spawn** but doesn't, for `lef_hints_ghost_time` (60 s), gets a reminder. Only
  seconds where spawning is actually possible count.
- `lef_hints_hold_tell_team 1` also tells the infected team (off by default: holding for a team hit
  is fine).

## Tank tips (versus)

Whoever becomes the tank gets a line about their team (still respawning → hold back; up → call the
hit in chat) and 2 random tips: avoid open areas, punch hittables, rocks for far survivors, don't
chase into the saferoom... The infected team is told who the tank is.

## Settings

| Cvar | Default | What it does |
|---|---|---|
| `lef_hints_pace` | 1 | Rushing / behind warnings |
| `lef_hints_rush_distance` | 0.12 | Ahead of the next teammate by this share of the map |
| `lef_hints_behind_distance` | 0.15 | Behind the closest teammate by this share of the map |
| `lef_hints_pace_tell_team` | 1 | Also tell the other survivors |
| `lef_hints_panic_grace` | 90 | Seconds without pace warnings after a panic event |
| `lef_hints_hold` | 1 | Holding-an-infected reminders |
| `lef_hints_hold_time` | 60 | Seconds alive without attacking |
| `lef_hints_ghost_time` | 60 | Seconds as a ghost able to spawn |
| `lef_hints_hold_tell_team` | 0 | Also tell the infected team |
| `lef_hints_tank_tips` | 1 | Tank tips |
| `lef_hints_tank_tip_count` | 2 | Random tips per tank |
| `lef_hints_cooldown` | 30 | Seconds between warnings to the same player |

The tips and warnings are in `translations/lef_game_hints.phrases.txt` (English and Spanish), easy to
reword.

## Needs

[Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696).
