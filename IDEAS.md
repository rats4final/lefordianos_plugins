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
- **Tank and witch every map, with announcements.** The answer is to use existing plugins
  rather than build one: `l4d2lib` + `witch_and_tankifier` + `l4d_boss_percent` already do it
  without Ready-Up or confogl (see section 5b of the plugin list). Possible add-ons of our own:
  - **Chance per map**: e.g. 80% tank / 60% witch, rolled once per map so both teams get the same.
    `witch_and_tankifier` exposes `SetTankPercent` / `SetWitchPercent`, so a small add-on can turn
    a boss off for that map, and `l4d_boss_percent` then announces "Tank: none".
  - **"Tank incoming" warning**: a chat/sound heads-up when survivors get within a few % of
    the tank's flow.

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

- **lef_teams_panel**: rewrite of BwA Jester's players panel. `!teams`, `!lastteams`,
  `!swapwith`, and a Team Management admin menu (move, swap, flip, shuffle, restore).
