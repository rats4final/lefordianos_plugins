[Español](README.es.md)

# lef_teams_panel — Lefordianos Teams Panel

A rewrite of **"Jesters Players Panel and Switch Menu"** by -=BwA=- Jester (original in
[`alliedmodders/BwA-Jester/`](../../alliedmodders/BwA-Jester/)). Left 4 Dead 2 only.

## What it does

**For everyone**

| Command | What happens |
|---|---|
| `!teams` | Panel listing spectators, survivors and infected. Press **1/2/3** to join that team. |
| `!lastteams` | Shows the teams as they were at the end of the last round (marks who isn't here). |
| `!swapwith [player]` | Asks a player on another team to trade places with you. They get a Yes/No menu. |

The panel shows survivors as dead/down/away, and bots as open spots. Infected classes are
**only shown to infected and spectators**, so survivors don't learn the lineup.

**For admins** (kick flag, `c`) — a **"Team Management"** category in `!admin`:

| Menu item | Command |
|---|---|
| Show teams | `sm_teams` |
| Move a player to a team | `sm_moveplayer <player> <spec\|surv\|inf>` |
| Swap two players | `sm_swapplayers <player1> <player2>` |
| Flip teams (survivors ↔ infected) | `sm_flipteams` |
| Shuffle teams randomly | `sm_shuffleteams` |
| Balanced shuffle (roster levels) | `sm_balanceteams` |
| Restore last round's teams | `sm_restoreteams` |

Flip, shuffle, balance and restore ask "are you sure?" in the menu first. Access can be changed per
command in `admin_overrides.cfg`.

## What it leaves to other plugins (on purpose)

The old panel tried to do everything itself. Other plugins do these jobs better, so this one
works alongside them instead:

| Job | Use this plugin | Why |
|---|---|---|
| `!spec` / `!survivors` / `!infected` commands | `l4d_afk_commands` (Harry Potter), or `playermanagement` | Anti-abuse rules: no switching while pinned, reloading, covered in bile, right after spawning, etc. |
| Pausing | `pause.smx` (competitive repo) | Both teams ready up to unpause, and SI don't spawn because of the pause. |
| Spectators staying spectators on map change | `l4d2_spec_stays_spec` | Dedicated, maintained. |
| Fixing teams that got scrambled on map change | `l4d2_fix_team_shuffle` | Runs automatically; `!restoreteams` here is the manual button. |

Joining from the panel uses whichever join plugin is loaded, so its rules still apply. With no
join plugin installed, the panel falls back to a basic built-in join that respects team limits
and won't let a pinned or downed survivor leave.

## Fixes over the original

- **Restore teams never worked**: the original never saved anyone's Steam ID, so it could
  never match players. It also assumed teams always swap sides between maps. This version saves
  "campaign team A/B" and works out which side each team plays now.
- **Hijacked the game's `jointeam` command**, which the M-key team menu uses.
- **"Spectators stay spectators" could move the wrong person**: timers stored player slots, not
  user IDs. (This feature is now left to `l4d2_spec_stays_spec`.)
- **Crash-prone bot search**: it skipped slot 1 and could read past the last slot when no
  survivor bot existed.
- **Panel titles were swapped** ("Current" vs "Last Map").
- **Flip teams lost track of counts** halfway through.
- **Swap requests could be answered late**: accepting an old menu after teams had changed still
  swapped. Requests now expire and are checked again before anything moves.
- **Admin menus shared global state**: two admins using the menu at once overwrote each other.
- **Its own gamedata/signatures**: these break on game updates. It now uses Left4DHooks' functions
  (`L4D_SetHumanSpec`, `L4D_TakeOverBot`), which are kept up to date.

## Dropped from the original

Pause/unpause (use `pause.smx`), the join command aliases (use `l4d_afk_commands`), automatic
spectator restore (use `l4d2_spec_stays_spec`), and the debug-logging menu.

## Balanced shuffle and the roster

Random shuffles often put all the regulars on one team. The balanced shuffle gives each player a
level and splits the players so both teams' levels add up as close as possible.

- Our regulars go in `addons/sourcemod/configs/lef_roster.cfg` (copy it from `lef_roster.example.cfg`
  the first time; updates only ship the example, so your list is never overwritten): SteamID (any format: `STEAM_1:…`,
  `[U:1:…]` or `7656…`), a name, and an optional level from 1 (new) to 5 (best). The file explains
  how to find a SteamID.
- Anyone not in the roster counts as `lef_teams_random_level` (2); a regular without a level counts
  as `lef_teams_roster_level` (3). So with no levels at all, the regulars are simply spread evenly.
- It tries every split (8 players = 70 even splits). Between equally even splits it spreads the
  regulars evenly, then picks one at random, so the same group doesn't get the same teams every time.
- `sm_roster` lists each player's level and whether they're in the roster; `sm_roster_reload`
  re-reads the file. Also votable from `!votes` (lef_votes).

## Settings (`cfg/sourcemod/lef_teams_panel.cfg`, created on first load)

| Cvar | Default | Meaning |
|---|---|---|
| `lef_teams_panel_join` | `1` | Pressing a team's number in `!teams` joins it. `0` = view only. |
| `lef_teams_panel_swap_requests` | `1` | Allow `!swapwith`. |
| `lef_teams_panel_request_timeout` | `20` | Seconds a swap request stays open. |
| `lef_teams_panel_request_cooldown` | `15` | Seconds between swap requests from the same player. |
| `lef_teams_roster_level` | `3` | Balanced shuffle: level of a roster player with no `"level"`. |
| `lef_teams_random_level` | `2` | Balanced shuffle: level of a player who isn't in the roster. |

## Requirements

SourceMod 1.12+, [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696).
Translations: English and Spanish.

## Not tested in-game yet

It compiles, but it hasn't been run on a server. Things to check on first run:
swapping a survivor with an infected mid-round, flipping teams while a Tank is alive,
`!restoreteams` after a map change, and shuffling with uneven teams.
