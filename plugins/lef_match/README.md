[Español](README.es.md)

# lef_match — Lefordianos Match

Admin tools for a versus match. Left 4 Dead 2.

## What it does

- **Keeps the scores when an admin changes the map inside the same campaign.** The game treats any
  forced map change as a new match and puts both teams at 0: restarting the chapter, or picking a
  map with SourceMod's *Change map* (`sm_map`), the mission manager, `!votes`, `changelevel`... With
  this plugin, if the new map is in the same campaign (and isn't its first map), each team gets back
  the points it had **when the chapter being played started** (the unfinished chapter doesn't
  count), and the teams are put back on the sides they started that chapter on.
- **Restart chapter** (`!restartchapter`): restarts the chapter being played, scores kept.
- **Return to lobby** (`!returntolobby` / `!lobby`): sends everyone back to the lobby, like the game's
  own "Return to lobby" vote when it passes.
- Both are in **`!admin` → Server Commands** (first two items), with an "are you sure?".

A new campaign, going back to a campaign's first map (the game's "Restart campaign" too) or an empty
server (everyone went back to the lobby, end of the night) start from 0, as usual.

## Commands (admins with the change-map flag, `g`)

| Command | What it does |
|---|---|
| `!restartchapter` | Restart this chapter in 3 seconds; scores kept. |
| `!returntolobby`, `!lobby` | Everyone back to the lobby in 3 seconds. |

## Settings (`cfg/sourcemod/lef_match.cfg`)

| Cvar | Default | What |
|---|---|---|
| `lef_match_keep_scores` | `1` | Keep the scores on forced map changes inside the campaign. `0` = the game's behaviour. |
| `lef_match_delay` | `3` | Seconds of warning before restarting or returning to the lobby. |

## How it works

- At the start of every chapter (first half) it notes both campaign teams' scores and which one
  starts as survivors. Every 10 seconds it notes which players are on which campaign team.
- When a map starts with both scores at 0 although the chapter before had points, in the same
  campaign, the map was changed by force. It waits until everyone finished loading (at most 30 s,
  or until survivors leave the saferoom), puts the teams back in the chapter's order with
  `lef_teams_panel`'s `sm_flipteams` if they came back swapped, and sets the scores where the
  competitive repo's `l4d2_setscores` sets them (plus the Versus Director's copy, via Left4DHooks).
- "Same campaign" comes from Harry's `l4d2_mission_manager`. Without it, only restarting the same
  map keeps the scores.
- Return to lobby: when the game's vote passes, the server (`Director::FinishScenarioExit` in
  `server.dll`) sends every player a `DisconnectToLobby` message. This plugin sends the same message.

## Needs

Left4DHooks, colors.inc. Optional: `l4d2_mission_manager` (same campaign), `lef_teams_panel`
(putting the teams back), the admin menu.

**Not tested with players yet** (2026-10-08): check the chat message "scores kept" and the scoreboard
after the first restart.
