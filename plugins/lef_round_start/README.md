[Español](README.es.md)

# lef_round_start — Lefordianos Round Start

The moments before survivors leave the saferoom, **without Ready-Up**: nobody has to press F1 or
type `!ready`. Left 4 Dead 2.

## Start panel

A small panel with this map's **tank and witch spots**, the **infected team's starting classes**,
which half of the round it is, how many humans each team has, and the commands to know. It disappears
`lef_start_panel_after_leave` seconds (15) after survivors leave the saferoom, at the first infected
hit on a survivor, after `lef_start_panel_time` seconds (60), or when the player presses **0**. It
steps aside when another menu opens.

## Waiting for a friend (`!wait`)

In versus, one survivor leaving the saferoom starts the round for everyone. When a friend is still
connecting:

1. Someone types `!wait` (also in `!menu`) and picks how many players to wait for (1–4).
2. A Yes/No vote asks "Wait for 1 more player before leaving the saferoom?".
3. If it passes, **nobody can leave the saferoom**: anyone who tries is sent back. A countdown shows
   in the hint box.
4. The wait ends (after a 3-2-1 countdown) when that many more humans are on the teams, when time runs out
   (`lef_start_wait_time`, 90 s), or when `!go` passes a vote (admins: instantly).
   `!extend` votes for more time (`lef_start_extend_time`, up to `lef_start_max_extends` times).

Typing `+1`, `+2`... in chat (our usual habit) does **not** start a vote on its own, so nobody gets a
surprise vote screen: that player just gets a private tip about `!wait`. Set
`lef_start_chat_trigger 2` to make `+N` start the vote directly, or `0` for no tip.

The newcomer is then told by `lef_teams_panel` which team to join to even things out.

## Settings

| Cvar | Default | What it does |
|---|---|---|
| `lef_start_panel` | 1 | Show the start panel |
| `lef_start_panel_time` | 60 | Hide it after this many seconds at most |
| `lef_start_panel_after_leave` | 15 | Seconds it stays after survivors leave the saferoom |
| `lef_start_wait_time` | 90 | Seconds to wait after a `!wait` vote passes |
| `lef_start_extend_time` | 60 | Seconds an `!extend` vote adds |
| `lef_start_max_extends` | 2 | Extensions per round |
| `lef_start_chat_trigger` | 1 | `+1` in chat: 0 = nothing, 1 = private tip, 2 = start the vote |
| `lef_start_countdown` | 3 | Seconds of 3-2-1 countdown (Ready-Up's beeps) before the wait ends. 0 = none |
| `lef_start_freeze` | 1 | Freeze survivors while waiting: 0 = never, 1 = only on a campaign's first map (no saferoom box to keep them in), 2 = always |

## Ready-Up

If Ready-Up is loaded, this plugin steps aside: Ready-Up already holds the start and has its own
panel. The saferoom hold uses the same method as Ready-Up (`warp_to_start_area`).

## Needs

[Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696) and the BuiltinVotes extension.
