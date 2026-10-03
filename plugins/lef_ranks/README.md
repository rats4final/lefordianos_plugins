[Español](README.es.md)

# lef_ranks — Lefordianos Ranks

A ranking for our versus games, made to build **balanced teams**. Left 4 Dead 2.

## How points work

Everyone starts at **1000 points** (Elo, like in chess, adapted to teams):

- When a **map** ends (both halves played), the team with more points on that map wins. Its players
  gain points and the losers lose them.
- Beating a stronger team gives more points than beating a weaker one; losing to a stronger team costs
  less.
- New players move faster (`lef_ranks_k_new` 40) for their first 20 maps, so they find their level
  quickly; after that, `lef_ranks_k_settled` (20).
- Only **map results** count, not damage or kills: that's what balanced teams are about, and it can't
  be farmed.
- A map only counts with at least **2 humans per side** (so bot games don't), and players who were on
  both sides during a map don't count for it.

## Commands

| Command | What it shows |
|---|---|
| `!rank` / `!rank <player>` | Points, maps played, won, lost, and position on the board |
| `!top` | The top 10 (players with at least `lef_ranks_min_games` maps, 5) |

After each map, every player sees their change in chat ("Map won: +14 points, now 1032").

## Balanced shuffle

`lef_teams_panel`'s balanced shuffle uses these points for anyone with at least 5 ranked maps
(`lef_teams_ranked_games`), and the roster level for everyone else (level 3 = 1000 points, each level
100 points). So it starts with the roster and gets more accurate the more you play.

## Settings

| Cvar | Default | What it does |
|---|---|---|
| `lef_ranks_start` | 1000 | Starting points |
| `lef_ranks_k_new` | 40 | How much one map moves a new player's points |
| `lef_ranks_k_settled` | 20 | How much one map moves an established player's points |
| `lef_ranks_settled_games` | 20 | Maps after which a player is established |
| `lef_ranks_min_players` | 2 | Humans needed per side for a map to count |
| `lef_ranks_min_games` | 5 | Maps needed to appear in `!top` |
| `lef_ranks_announce` | 1 | Tell each player their change after a map |

## Storage and cost

Uses SourceMod's database: the `lef_ranks` entry in `configs/databases.cfg` if you add one (e.g.
MySQL), otherwise `storage-local`, the SQLite file SourceMod already has
(`addons/sourcemod/data/sqlite/sourcemod-local.sq3`). Queries run in the background: one small write per
player per map and one read when a player joins. It costs practically nothing.

Needs [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696).
