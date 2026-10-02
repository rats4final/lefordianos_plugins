# lef_score_info — Lefordianos Score Info

Explains vanilla versus scores so a bad map doesn't feel hopeless. **It changes no points.**
Left 4 Dead 2, versus only.

## What players see

**When survivors leave the saferoom**
> [Score] This map is worth **500** points. Gap: **300** (60% of this map).

**After the first half** (from the point of view of each player)
> [Score] Your team scored **420** of 500 on this map.
> [Score] The other team need **421** (85% of the map) to win this map.
> [Score] The other team need **121** (25% of the map) to take the overall lead.

**After the map**
> [Score] Your team won this map, **420** to **380**.
> [Score] Your team: **1200** pts, **2** maps won | The other team: **900** pts, **1** maps won

`!score` shows the standings and this map's value at any time.

Messages say "your team" / "the other team" to players and "the survivors" / "the infected" to
spectators, because the game's internal "Team A / Team B" means nothing to anyone.

## Map wins

Counted per map by comparing both teams' scores on that map, kept for the whole campaign and
reset when a new campaign starts. It's for bragging rights and morale: a blowout counts as **one**
lost map. The game still decides the winner by total points.

## Settings (`cfg/sourcemod/lef_score_info.cfg`)

| Cvar | Default | Meaning |
|---|---|---|
| `lef_score_info_delay` | `5.0` | Seconds after a half ends before printing (lets the scoreboard settle). |

## Credits and differences

Idea from MoYu's `l4d2_score_difference` (Forgetest, vikingo12). That plugin predicts the *next*
map's value, which needs Silvers' Info Editor; this one announces each map's value when the map
starts instead, so it needs only Left4DHooks. Don't run both: they print similar lines.

## Not tested in-game yet

Compiles. Things to check: the "your team / other team" labels are right in both halves (the
game swaps sides between halves), and the map wins count resets on a new campaign.
