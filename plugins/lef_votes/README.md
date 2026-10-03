[Español](README.es.md)

# lef_votes — Lefordianos Votes

`!votes`: players decide things together on the game's own vote screen (F1 = Yes, F2 = No).
Admins get the same options in `!admin`, where they run at once with no vote. Left 4 Dead 2.

## What can be voted

Everything is listed in `addons/sourcemod/configs/lef_votes.cfg`, in groups. Adding a vote usually
means adding an entry with a server command, no code. Reload with `sm_votes_reload`.

| Group | Votes |
|---|---|
| Maps | Change map (campaign → map list from the mission manager), restart this map, next campaign (played after this one, via `lef_campaigns`), change game mode (Vote_Mode's list) |
| Teams | Shuffle, balanced shuffle (roster levels), swap survivors and infected, restore last round's teams (`lef_teams_panel`) |
| Players | Kick, move to spectators (AFK), mute voice, chat or both until the round ends (a warning), **choose the tank** (infected team only: the picked teammate gets the next tank, or the current one if a tank is already in play) |
| Rules | Tank and witch chance 0 / 50 / 100 %, T1 weapons only on/off, tank horde monitor on/off |
| Game | Pause, all talk on/off |

Entry types: `command` (runs a server command when the vote passes), `client` (opens another
plugin's menu, no vote here; hidden when that plugin isn't loaded), `map`, `restart`, `kick`,
`spec`, `mute`, `pause`. The config file explains each.

## Kick works like vanilla's

The game's own vote kick also stops the player from rejoining for a while. SourceMod's kick doesn't,
so a kicked troll could come straight back. Here a vote kick is a kick plus a short ban:
`lef_votes_kick_ban_minutes` (default 5; 0 = kick only). Admins with a flag in
`lef_votes_immune_flags` (default `b`) can't be kicked, moved or muted by vote.

## Pause only by vote

So randoms can't pause whenever they like, players can't use `!pause` directly: typing it starts a
pause vote instead. If it passes, the game pauses as usual (`pause.smx`), and unpausing works as
before (both teams `!ready`). Admins can still `!pause` directly, and have **force pause** and
**force unpause** in the admin menu. Turn this off with `lef_votes_pause_by_vote 0`.

## Votes last the whole session

Every map change re-runs the server configs, which would quietly undo a voted setting (tank/witch
chance, horde monitor, all talk). So those votes are remembered and applied again after each map's
configs, until the server is empty; then everything goes back to the configs. In the config file
this is the `"persist"` key.

## Who voted

After every vote on the vote screen (the game's own votes from the Esc menu, ours, and other
plugins'), chat lists who voted Yes and who voted No. `lef_votes_show_voters 2` also shows each vote
as it comes in; `0` turns it off. No extra plugin needed: players send "Vote Yes" / "Vote No" for every
vote, and we listen to that.

## Next campaign and game mode

- **Next campaign:** pick a campaign, then Yes/No on F1/F2. If it passes, [`lef_campaigns`](../lef_campaigns/)
  plays it when the current campaign ends. Works any time, not only on the finale.
- **Change game mode:** pick a category and a mode from Vote_Mode's own list
  (`data/l4d_votemode.cfg`), then Yes/No on F1/F2; if it passes, Vote_Mode applies it (`sm_forcemode`)
  and restarts the map. Vote_Mode's old chat vote (`!votemode`) is admin-only in the lite config.

## Admin menu

`!admin` → **Lefordianos**:

- **Run a vote option now**: every entry above, with no vote.
- **Force pause / Force unpause** (`pause.smx`'s `sm_forcepause` / `sm_forceunpause`).
- **Pass / cancel the current vote** (also `sm_vp` and `sm_vc`).

## Settings

| Cvar | Default | What it does |
|---|---|---|
| `lef_votes_pass_percent` | 50 | A vote passes when more than this percent of the votes cast are Yes |
| `lef_votes_min_players` | 1 | Players needed on the server to start a vote |
| `lef_votes_time` | 20 | Seconds a vote stays on screen |
| `lef_votes_spectators_call` | 0 | Spectators can start votes |
| `lef_votes_spectators_vote` | 1 | Spectators can vote |
| `lef_votes_kick_ban_minutes` | 5 | Minutes a vote-kicked player can't rejoin (0 = kick only) |
| `lef_votes_immune_flags` | b | Admin flags that can't be vote-kicked, moved or muted |
| `lef_votes_pause_by_vote` | 1 | Players can only pause through a vote |
| `lef_votes_show_voters` | 1 | List who voted: 0 = off, 1 = at the end, 2 = also each vote |

The vote screen shows one text for everyone, in the server's language; the menus follow each
player's language (English or Spanish).

## Needs

- [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696) and the **BuiltinVotes**
  extension.
- Optional: Harry Potter's `l4d2_mission_manager` (map vote), `pause.smx` (pause), `basecomm`
  (mute; part of SourceMod), `lef_teams_panel`, `lef_t1_mode`, `lef_boss_spawns`,
  `l4d2_tank_horde_monitor`, Vote_Mode. A vote for a missing plugin does nothing.

## Credits

Ideas from Harry Potter's archived `l4d_votes_5` and his `l4d2_vote_change` (votes defined in a
config file). The mission manager include is Harry Potter's (based on rikka0w0's).
