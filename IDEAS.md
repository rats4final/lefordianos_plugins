# Ideas

A running list. Add freely, and move things to "Done" when they ship.

**The rule of thumb:** keep the vanilla feel. Bug fixes and quality-of-life are welcome; anything
that changes game balance should be optional and off by default.

## In progress

- **Lite config (no confogl)**: a plain-SourceMod server set: the competitive repo's bug fixes
  (`generalfixes.cfg`), the teams panel, and the QoL plugins we like.
- **Lefordianos Vanilla+ (confogl match mode)**: a `cfgogl/lefordianos/` mode for `!match`:
  the fixes plus QoL, with none of the competitive balance changes. Lowest priority.
- Lite config plugin list to choose from: [`configs/lite/PLUGINS.md`](configs/lite/PLUGINS.md).
- **Use the game's own vote screen (builtinvotes) in our plugins.** The `builtinvotes`
  extension (ships with the competitive repo) shows the same F1/F2 vote panel as L4D2's own votes.
  What it can and can't do in L4D2:
  - **Yes/No only.** Multiple-choice votes are TF2-only, so "pick one of 3" still needs a menu.
  - Can be shown to everyone or **one team only** (`SetBuiltinVoteTeam`), e.g. an infected-only vote.
  - Only **one vote at a time** server-wide, with the game's cooldown between votes.
  - Already used by `match_vote`, `l4d2_setscores`, `slots_vote`, `l4d_boss_vote`, `caster_system`.

  First uses:
  - Teams panel: `!voteshuffle`, `!voteflip`, `!voterestore`, so players can fix teams without an
    admin (admins keep the instant menu buttons).
  - A small shared include (`lef_votes.inc`) so any of our plugins can start a Yes/No vote with
    one call and get "passed/failed", instead of repeating the setup each time.
  - Not for swap requests: a 1-person vote would block every other vote on the server while it's
    open, so `!swapwith` keeps its private menu.
- **"Tank incoming" warning** (add-on to `lef_boss_spawns`): a chat/sound heads-up when survivors
  get within a few % of the tank's flow.
- **Comeback scoring for vanilla versus**: chose options A and C (see below), built as
  `lef_score_info` and `lef_comeback_bonus`. Needs testing on the server.

## Undo griefing: admin restore (proposed 2026-10-01)

Improves Harry Potter's `admin_hp` (`!hp` heals *every* survivor to full, root only, no menu).
Working name `lef_admin_restore`.

- **Heal**: `!heal <player|@survivors>`, with an admin menu entry. Replaces `!hp`.
- **Team-damage ledger**: for each survivor, the plugin quietly keeps track of what *teammates*
  did to them: HP lost, incaps caused (which push toward black-and-white), a team kill, and a
  snapshot of their items taken right before the first teammate hit.
- **Undo**: `!restore <player>` (or the menu, which lists who has something to undo, e.g.
  "Nick: 45 HP, 1 incap, lost pills + molotov, by Troll") gives back exactly that:
  the HP teammates took, the incap count, a revive if downed by a teammate, a respawn next to the
  team if team-killed, and the items they had before.
- **Admins get a heads-up** when someone takes heavy team damage: "Troll did 60 team damage to
  Nick. !restore Nick to undo."
- **Possible later**: a Yes/No vote (builtinvotes) so players can restore a victim when no admin
  is online.

**Already in the list**: ZoneMod's `despawn_health` gives SI back part of their missing health
when they turn back into a ghost (`si_restore_ratio`, default 0.5 = half, 1.0 = full). It's in
section 7 of the plugin list. Nothing to build; just tick it.

## Comeback scoring (discussion, 2026-10-01)

**The problem:** vanilla versus scores mostly by distance (plus a 25-point tiebreak for the team
that did more damage). A team wiped early on a map gets almost nothing, so one bad map can mean a
400+ point gap. That demoralises the losing team and anyone who joins it.

**How it could work technically:** the competitive scoring plugins don't replace the scoreboard;
they adjust the game's own scoring settings right before the round's score is counted
(`L4D2_OnEndVersusModeRound`). `l4d2_penalty_bonus` uses a neat trick: it sets a *negative* defib
penalty, which turns it into a bonus that shows on the normal scoreboard and **still counts when a
team is wiped**. ZoneMod's `holdout_bonus` is built on it. Our plugin would use it too.

**Options**, from "keeps vanilla scoring" to "changes it most":

| | Idea | Changes points? | Helps the losing team specifically? |
|---|---|---|---|
| A | **Show it better**: after each map, the score difference and "you need X% of the next map to come back" (MoYu's `l4d2_score_difference` already does this), plus a **map wins** count ("Maps: 3–2"), so one blowout is one lost map, not the whole game. | No | Morale only |
| B | **Effort points**: a wiped team still earns points for what it did: SI killed, tank damage/kill, witch killed/crowned. Same rules for both teams. | Yes, a little | Shrinks blowouts for whoever gets wiped |
| C | **Catch-up bonus**: the team that's behind gets a small bonus on the next maps (e.g. a % of the gap, capped). Tunable, could be off by default. | Yes | Yes, directly |
| D | **Cap per-map swing**: one map can't widen the gap by more than N points. | Yes | Yes, limits blowouts |
| E | **ZoneMod's health-bonus scoring** (`l4d2_hybrid_scoremod_zone`): points for staying healthy. | A lot | No; it's a different game |

## Later

- **Demo recording** for both configs (parked 2026-10-01, we'll come back to it):
  - the [sourcetvsupport](https://github.com/shqke/sourcetvsupport) extension (fixes SourceTV
    in L4D2; the binary has to be downloaded from its GitHub releases or built from source);
  - a small `lef_demo_recorder` plugin that starts recording when a round goes live and names
    the files `date_map_round.dem`. No auto-record plugin exists in the reference repos;
    shqke's `autorecorder` (sp_public repo) is the one to look at.

## Brainstorm (from the first read-through, 2026-10-01)

1. **Vanilla+ match mode**: see above.
2. **Teams panel rewrite**: done, see `plugins/lef_teams_panel`.
3. **Balanced teams from history**: save each player's stats over time (damage dealt to
   survivors/SI, skeets, deaths, tank damage) in SQLite, and have `!balance` propose fair teams.
   Harry Potter's `l4d_mix` does captain picks; this would be the stats-based version for a group
   that plays together often. Could feed straight into the panel's shuffle (a "balanced shuffle"
   admin menu item).
4. **Match recap**: after each map, post scores, MVPs, tank damage and funny moments ("Ellis
   killed 3 teammates"). Pieces exist already: `l4d2_playstats`, `survivor_mvp`,
   `l4d_tank_damage_announce`, `l4d_pig_infected_notify`, `l4dffannounce`. Posting to Discord
   would need an HTTP extension (SteamWorks or REST in Pawn), which isn't in the reference repos.
5. **A lighter mode system than confogl**: switch config "profiles" (cvars + plugin list)
   without confogl's competitive extras. Only worth building if the confogl-based mode turns
   out to get in the way.

## More ideas

- **Admin menu additions**: the SourceMod `!admin` menu could get more L4D2 categories:
  - map/campaign switching: `l4d2_mm_adminmenu` (mission manager) already does this;
  - respawn a dead survivor at the crosshair: `l4d_sm_respawn` (Harry Potter);
  - spawn items/SI and control the director: `all4dead2` has a menu;
  - restart the round / swap the scores (`l4d2_setscores`) for when something goes wrong.
  A "Lefordianos" admin category could collect the ones we use.
- **Modernise more old-syntax plugins** we find on AlliedModders: the same treatment as the
  teams panel (new syntax, Left4DHooks instead of private gamedata, translations).

## Done

- **lef_score_info** (option A) and **lef_comeback_bonus** (option C): built, not yet tested in game.
- **lef_boss_spawns**: per-map tank/witch chance (same for both teams), second-half bosses spawn on
  the first half's spot (port of confogl's BossSpawning), flows announced. Works with
  `witch_and_tankifier` / `l4d_boss_percent`, without Ready-Up or confogl.
- **l4d_tank_control_eq (patched)**: tank rotation without the Ready-Up requirement.
- **lef_teams_panel**: rewrite of BwA Jester's players panel. `!teams`, `!lastteams`,
  `!swapwith`, and a Team Management admin menu (move, swap, flip, shuffle, restore).
