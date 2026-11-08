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

## Attack together (versus)

- Once per map, when the survivors leave the saferoom (first half), the infected team gets the tip:
  attack together, one alone rarely gets anything.
- A **smoker, hunter, jockey or charger** that went in alone and died fast gets a private reminder,
  at most once per round. "Alone and fast" means all of: killed by a survivor within
  `lef_hints_solo_time` (15 s) of spawning, less than `lef_hints_solo_damage` (10) damage done, nobody
  pinned, no infected teammate alive within `lef_hints_solo_range` (1200 units) or hitting a survivor
  in the last 5 s, no survivor down or pinned, and no tank up.
- **Boomers and spitters never count**, nor deaths not caused by a survivor (falls, suicides):
  sacrificing one to rotate the spawn order ("kill boom") is a real tactic.

## Tank tips (versus)

Whoever becomes the tank gets a line about their team (still respawning → hold back; up → call the
hit in chat) and random tips: avoid open areas, punch hittables, rocks for far survivors, don't
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
| `lef_hints_solo` | 1 | Attack-together tip and reminder |
| `lef_hints_solo_time` | 15 | Alone: died within this many seconds of spawning |
| `lef_hints_solo_damage` | 10 | Alone: did less damage than this |
| `lef_hints_solo_range` | 1200 | Alone: no infected teammate this close |
| `lef_hints_tank_tips` | 1 | Tank tips |
| `lef_hints_tank_tip_count` | 1 | Random tips per tank |
| `lef_hints_cooldown` | 30 | Seconds between warnings to the same player |

The tips and warnings are in `translations/lef_game_hints.phrases.txt` (English and Spanish), easy to
reword.

## Needs

[Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696).
