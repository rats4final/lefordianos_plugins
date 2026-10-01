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
| Restore last round's teams | `sm_restoreteams` |

Flip, shuffle and restore ask "are you sure?" in the menu first. Access can be changed per
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

## Settings (`cfg/sourcemod/lef_teams_panel.cfg`, created on first load)

| Cvar | Default | Meaning |
|---|---|---|
| `lef_teams_panel_join` | `1` | Pressing a team's number in `!teams` joins it. `0` = view only. |
| `lef_teams_panel_swap_requests` | `1` | Allow `!swapwith`. |
| `lef_teams_panel_request_timeout` | `20` | Seconds a swap request stays open. |
| `lef_teams_panel_request_cooldown` | `15` | Seconds between swap requests from the same player. |

## Requirements

SourceMod 1.12+, [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696).
Translations: English and Spanish.

## Not tested in-game yet

It compiles, but it hasn't been run on a server. Things to check on first run:
swapping a survivor with an infected mid-round, flipping teams while a Tank is alive,
`!restoreteams` after a map change, and shuffling with uneven teams.
