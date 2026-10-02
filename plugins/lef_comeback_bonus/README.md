# lef_comeback_bonus — Lefordianos Comeback Bonus

Gives the team that's behind a fair chance to come back in vanilla versus. Left 4 Dead 2, versus only.

## How it works

1. **At the start of each map** it looks at the total scores. If a team is behind by at least
   **100** points (`lef_comeback_min_gap`), the bonus is on for that team on this map.
2. **During the half that team plays survivors**, it earns an extra **15%** (`lef_comeback_percent`)
   of the distance points it covers.
3. **Capped at the gap** (`lef_comeback_cap_to_gap`): the bonus can help them catch up, but the
   bonus alone never puts them ahead.

Because it's a percentage of the distance they *actually* cover, the trailing team still has to
play well. Wiped at 10% means 15% of very little.

**Example.** After map 1 the score is 400–40 (gap 360). Map 2 is worth 500. The trailing team
reaches the saferoom: 500 distance + 75 bonus = 575. The leading team also reaches it: 500. The
gap drops from 360 to 285.

## What players see

> [Comeback] The other team is behind by **360**: as survivors on this map they earn **+15%** of their distance.

(when survivors leave the saferoom, if the bonus is on) and after their half:

> [Comeback] **+75** comeback bonus for the other team.

`!comeback` shows whether it's on for this map.

## Requirements

- [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696)
- **`l4d2_penalty_bonus`** from the competitive repo (`addons/sourcemod/plugins/optional/`). It adds
  the points by turning the game's defib penalty into a bonus, so they show on the normal
  scoreboard and count even when the team is wiped. Our plugin won't load without it.

## Settings (`cfg/sourcemod/lef_comeback_bonus.cfg`)

| Cvar | Default | Meaning |
|---|---|---|
| `lef_comeback_enable` | `1` | On/off. |
| `lef_comeback_percent` | `15` | Bonus as a % of the distance points the trailing team covers. |
| `lef_comeback_min_gap` | `100` | Only kick in when a team is at least this far behind at the start of the map. |
| `lef_comeback_cap_to_gap` | `1` | Never give more than the gap. |

## How the distance is measured

The bonus is calculated just before the game counts the half, from the game's own per-survivor
progress (the value it scores with): map value × the team's average progress. It's an
**estimate** of the distance points: the bonus may be off by a point or two from exactly 15%, but
the announced number is always the number added.

## Not tested in-game yet

Compiles. Things to check: the bonus appears on the round-end scoreboard, it goes to the right
team in both halves, and it's never more than the gap.
