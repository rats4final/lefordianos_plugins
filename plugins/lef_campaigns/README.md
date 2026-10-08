[Español](README.es.md)

# lef_campaigns — Lefordianos Campaigns

Campaign rotation. It replaced rikka0w0's Automatic Campaign Switcher (ACS) on 2026-10-04, so the
next campaign can be voted on the game's own vote screen. Left 4 Dead 2.

- **Versus**, when both teams have played the finale: the game's end screen lets players vote **play
  again** (rematch) or the **lobby** for 30 seconds (`sv_pz_endgame_vote_period`, set in
  `lefordianos/common.cfg`; the game's default 12 left no time), plus 5. A rematch is left to the game.
  Otherwise the game would send everyone to the lobby: this plugin changes to the **next campaign**
  instead, unless more players voted for the lobby than for playing again, a "Return to lobby" vote
  passed, or an admin used `!lobby` (`lef_match`). How the end screen works was read from
  `server.dll` (2026-10-08); not yet tested with players.
- **Coop**: the server changes to the next campaign `lef_campaigns_delay` seconds (12) after the
  survivors escape.
- The next campaign is the one voted with **`!votes` > Maps > Next campaign** (pick a campaign, then a
  Yes/No vote on F1/F2), any time during the campaign. Without a vote, it's the next one in the list
  of Harry Potter's mission manager: official campaigns first, then custom ones (Big Wat Night...).
- On a finale map, 20 seconds after leaving the saferoom, chat says which campaign comes next and how
  to vote another.
- If another plugin changes the map first (e.g. `l4d2_map_transitions` on `c9m2_lots`), that wins: our
  change is cancelled by any map change.

| Command | What it does |
|---|---|
| `!next` | Which campaign comes next |
| `sm_setnextcampaign <first map>` / `clear` | Set or forget the next campaign (admins, change-map flag; what the vote runs) |

| Cvar | Default | What it does |
|---|---|---|
| `lef_campaigns_delay` | 12 | Coop: seconds after the escape before changing (versus follows the end screen) |
| `lef_campaigns_announce` | 1 | On finale maps, say which campaign comes next |

Needs [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696) and Harry Potter's
`l4d2_mission_manager` (the campaign list).
