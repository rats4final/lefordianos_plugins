[Español](README.es.md)

# lef_steam_bans — Lefordianos Steam Bans

When a player joins, asks Steam whether their account has **VAC bans**, **game bans** (from a game's
own anti-cheat) or a **Steam Community ban**, and tells the admins. It only looks at bans: **no hours,
no profile, no friends**, nothing else about the player. Left 4 Dead 2 (works in any Source game).

- Admins (generic flag, override `lef_bans_notify`) see it in chat; `lef_bans_announce 1` tells everyone.
- Every finding goes to `logs/lef_steam_bans.log`.
- Each account is asked about once per server start; map changes don't ask again.
- `sm_checkbans <player>` asks again and also tells you when there's nothing.
- It never kicks unless you set `lef_bans_kick_vac_days` (e.g. 365 = kick VAC bans from the last year).

## Setup

1. Get a Steam Web API key at <https://steamcommunity.com/dev/apikey> (any domain name works).
2. On the server, put it in `cfg/sourcemod/lef_steam_bans.cfg` (created on first load):
   `lef_bans_apikey "YOURKEY"`. **Keep it private**: never put it in this repo or a shared config.
3. Change map or restart.

Without a key the plugin does nothing (one line in the error log says why).

## Settings

| Cvar | Default | What it does |
|---|---|---|
| `lef_bans_apikey` | (empty) | Steam Web API key |
| `lef_bans_announce` | 0 | 0 = admins only, 1 = everyone |
| `lef_bans_game_bans` | 1 | Also report game bans |
| `lef_bans_community` | 0 | Also report Steam Community bans |
| `lef_bans_kick_vac_days` | 0 | Kick if the last VAC ban is newer than this many days. 0 = never kick |

## Needs

The **REST in Pawn** extension ([sm-ripext](https://github.com/ErikMinekus/sm-ripext)); the lite
package includes it for Windows and Linux (`tools/get_extensions.py`).

## Credits

Idea from StevoTVR's VAC Status Checker (forked by Harry Potter as `vacbans`), which uses the Socket
extension instead.
