[Español](README.es.md)

# lef_campaigns — Lefordianos Campaigns

Campaign rotation. It replaced rikka0w0's Automatic Campaign Switcher (ACS) on 2026-10-04, so the
next campaign can be voted on the game's own vote screen. Left 4 Dead 2.

- When a campaign ends (versus: both teams have played the finale; coop: the survivors escape), the
  server changes to the **next campaign** after `lef_campaigns_delay` seconds (12, while the scoreboard
  is up).
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
| `lef_campaigns_delay` | 12 | Seconds after the finale before changing |
| `lef_campaigns_announce` | 1 | On finale maps, say which campaign comes next |

Needs [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696) and Harry Potter's
`l4d2_mission_manager` (the campaign list).
