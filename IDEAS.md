[Español](IDEAS.es.md)

# Ideas

A running list. Add freely, and move things to "Done" when they ship.

**The rule of thumb:** keep the vanilla feel. Bug fixes and quality-of-life are welcome; anything
that changes game balance should be optional and off by default.

## In progress

- **Lite config (no confogl)**: **package built** (`python3 tools/build_lite.py`, see
  [configs/lite/INSTALL.md](configs/lite/INSTALL.md)); needs testing on the server. A plain-SourceMod server set: the competitive repo's bug fixes
  (`generalfixes.cfg`), the teams panel, and the QoL plugins we like. Per-mode settings come from
  Harry Potter's `gamemode-based_configs` (`cfg/sourcemod/gamemode_cvars/<mode>.cfg`, run on map
  start and on mode change); every mode file should set the same cvars, since it never undoes the
  previous mode's. With Silvers' `Vote_Mode`, players can switch modes and get the right settings.
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

## Decisions and plans (2026-10-02)

### Stripper for the lite config
- Use ZoneMod's stripper files (`cfg/stripper/zonemod/maps/`) **minus the special reworks** on 13
  official maps: c1m1 elevator holdout, c1m3 lower event path / saferoom route, c2m2 & c2m3 & c2m4
  saferoom reworks / scavenge area / carousel room / bumper cars route, c3m1 town one-way drop, c4m4
  playground route, c5m5 bridge railings, c6m1 empty apartment rooms, c7m2 saferoom one-way drop,
  c8m1 block street, c10m1 tree cards, c12m4 warehouse awning. Everything else on those maps stays
  (exploit fixes, out of bounds, stuck spots...).
- **Keep scripted witches and tanks** like vanilla:
  - don't use the witch-removal part of ZoneMod's `global_filters.cfg` (keep its ragdoll removal and
    entity-type fix);
  - also drop these event blocks: c1m4 "spawn tank at 29 seconds" (ZoneMod adds a tank when the
    elevator reaches the bottom of the mall; vanilla has no tank before the finale) and c4m2 / c4m3
    "fix multiple unwanted witches". Fixes like c9m2's generator freeze and c10m3's tank filter stay.
  - **c7m1 is kept** (decided 2026-10-02): the train-car door opens by itself 20 s after the tank
    spawns, and the fake tank sounds are removed. Good QoL; otherwise survivors burn the tank inside
    the car.
  - Scripted map tanks (e.g. c7m1's train car, finales) are never removed by our plugins; the
    `static_tank_map` list only stops `witch_and_tankifier` adding a *second* flow tank there.
- **Done:** `tools/make_stripper.py` + `configs/lite/stripper_rules.txt` generate
  `configs/lite/left4dead2/cfg/stripper/lefordianos/`. Re-run it after ZoneMod updates.
- **Global filters** (`global_filters.cfg`, applies to every map) has 17 sections. Removed: WITCH
  REMOVAL, T2 WEAPON SPAWN FIX (turns every T2 into T1 everywhere), COMPETITIVE ITEM SPAWNS (removes
  miniguns, gas cans, propane, oxygen). Kept: ragdoll removal, entity/item density/hittable/door/prop
  collision fixes, junk prop cleanup, immovable tables, sound and visual cleanups. **Still to decide:**
  PILL CABINET MAX (cabinets give at most 2 pills), ITEM PICKUP FIX (melee/item spawns give one
  pickup), INFECTED CLIP / TRIGGER FIX (removes clips that keep infected out of some spots).

### Tickrate (parked, not for now)
Everything we learned, so we don't have to research it again:
- **It's server-wide.** Set with the launch option `-tickrate 60` / `100` (lakwsh's l4dtoolz; with
  Accelerator74's l4dtoolz you also need `tickrate_enabler`). lakwsh's version also has
  `sv_tickrate N`, which applies after the next map change. It can't differ between the lite config
  and a confogl mode without a map change.
- **Rates to set** (`server.cfg`, many need `sm_cvar`): `sv_minrate`/`sv_maxrate`/`net_splitpacket_maxrate`
  = tickrate × 1000; `sv_minupdaterate`/`sv_maxupdaterate`/`sv_mincmdrate`/`sv_maxcmdrate` = tickrate;
  `sv_client_min_interp_ratio 0`/`sv_client_max_interp_ratio 0`; `fps_max 0`; `nb_update_frequency`
  (how often commons/witches think: lower = smoother but more CPU). The competitive repo's
  `server.cfg` has a ready 100-tick block. lakwsh's l4dtoolz raises `sv_minrate`/`sv_minupdaterate`
  by itself when the tickrate changes.
- **Things that break above 30 tick, and their fixes:**
  - the boomer's vomit range gets shorter in versus → [`lakwsh/l4d2_vomit_fix`](https://github.com/lakwsh/l4d2_vomit_fix)
    (not in our folder yet);
  - dual pistols fire much faster → `l4d2_pistol_delay`;
  - door speed, fall damage and other tick-based timings → `TickrateFixes` (plus `tick_door_speed 1.3`).
- **Quirks:** the client's `net_graph` shows at most 100 even at 128 tick (display only); a client's
  real cmdrate can't exceed their FPS; if the server's FPS (`sv` in net_graph) drops below the
  tickrate during tank + horde, everyone gets fewer updates. The competitive guide suggests a ~3 GHz
  CPU for 100 tick. CPU and upload bandwidth grow roughly with the tickrate (100 tick ≈ 3× 30 tick).

### l4dtoolz: Accelerator74 vs lakwsh
Both are forks of the original by ivailosp. The competitive repo ships Accelerator74's.

| | Accelerator74 (competitive repo) | lakwsh (recommended by Harry for L4D2) |
|---|---|---|
| Max clients (players + bots) | Launch option `-maxplayers N`, else **31**. Fixed for the whole run. | `sv_setmax N` (18–32, default 18). Use `+sv_setmax 31` at launch; can change at runtime (when the server is empty). |
| Human player limit | `sv_maxplayers` (-1 = game default, 0–32) | `sv_maxplayers` (-1 = game default, up to 31) |
| Lobby reservation | `sv_force_unreserved` | `sv_force_unreserved`, plus `sv_cookie` to read/set the lobby cookie (0 removes the lobby) |
| Tickrate | No (needs `tickrate_enabler`) | Yes: `-tickrate N` / `sv_tickrate N` |
| "No Steam logon" workaround | No | `sv_steam_bypass 1` — but SteamIDs are then **not verified**: admins by SteamID and our roster can't be trusted, Family Sharing bans stop working, SteamWorks breaks, and server-browser info needs `l4d2_a2s_fix`. Only switch on while the error is happening. |
| Block Family Sharing accounts | No | `sv_anti_sharing 1` |
| How it finds game code | Symbols/signatures | Offsets with pointer checks: less likely to break on updates |
| Games | L4D1 and L4D2 | L4D2 (Harry points L4D1 users to Accelerator74's) |
| Windows / Linux | Both | Both |

Gotchas: `sv_setmax` ≠ `sv_maxplayers` (all clients incl. bots vs. real players); above 31 crashes
since The Last Stand. The competitive configs set the human limit through `mv_maxplayers` (from
`match_vote`) because `sv_maxplayers` gets reset on map change; with lakwsh we'd set
`sv_maxplayers` + `sv_visiblemaxplayers` in `server.cfg`. For `sv_allow_lobby_connect_only` the
two sources differ: the competitive `server.cfg` uses `0`; Harry's tutorial suggests `1` plus his
`l4d_unreservelobby` for servers with 5+ slots. To test on our server.
**Decision (2026-10-02):** no l4dtoolz for now. lakwsh's is the likely choice once we've tested it
on our server and it causes no problems.

### Karma kill sounds
Only for karma kills. eyal282's karma kill system fires `KarmaKillSystem_OnKarmaEventPost`, so a
small plugin of ours can play a random sound from our own list. Players must download custom sounds:
- **FastDL** is the good way (full guide: [docs/FASTDL.md](docs/FASTDL.md)): a web server with the files, and `sv_downloadurl "http://.../"` on the
  game server. A public IP at home works: run a small web server (nginx, Caddy, or even
  `python3 -m http.server`), forward its port, use `http://` (the game's downloader isn't reliable
  with `https://`), and compress files as `.bz2` so they download faster. If the home IP changes,
  use a dynamic DNS name. Upload speed at home limits how fast players download.
- Without FastDL, players download from the game server itself (slow). Harry's
  `l4d_fastdl_delay_downloader` makes them download only at map change, not on join.

### Anti-cheat
Use **srcdslab's SMAC and srcdslab's Little Anti-Cheat**. Start LAC with `lilac_ban 0` (log only)
for a couple of weeks.

### One front door: `!menu` for players, `!admin` for admins (proposed 2026-10-02)

**Teams panel vs. votes, the difference:** the teams panel's admin menu is **instant, admin-only**
(an admin decides and it happens). `!votes` is for **players deciding together** on the game's vote
screen, no admin needed, for things that affect everyone. Some actions exist in both (shuffle,
flip, restore teams): admins do them instantly, players vote for them.

To keep it simple for everyone:
- **Players:** one `!menu` (alias `!lef`) with: *Teams* (the `!teams` panel, `!swapwith`), *Vote*
  (the `!votes` list), *Info* (`!bosses`, `!score`), *Help* (all our commands, one line each).
- **Admins:** everything in SourceMod's `!admin` menu (the one admins already use): the existing
  *Team Management* category, plus a new *Lefordianos* category to run any vote item instantly,
  and to force-pass / cancel the current vote. Heal/restore stay in *Player Commands*.

**`lef_votes` design** (inspired by Harry Potter's archived `l4d_votes_5` and his private
`l4d2_vote_change`, whose README/screenshots show a menu → Yes/No on the game's vote screen, and
custom votes defined in a config file): every vote item is defined in a config file with a title
(EN/ES), the server command to run if it passes, who can call it, and its pass message. Adding a
vote = adding an entry, no code. Built-in items need code only where a menu is required first
(pick a map, pick a player).

**Suggested votes:**

| Group | Vote | How |
|---|---|---|
| Maps | Change campaign / map (official + custom, names from the mission manager) | menu, then Yes/No |
| Maps | Next campaign at the finale (replaces ACS's vote) | automatic at the finale |
| Maps | Restart the current map | Yes/No |
| Maps | Change game mode (versus, coop, realism...) | menu, then Yes/No (Vote_Mode does this today) |
| Teams | Shuffle / balanced shuffle (with the roster) / flip / restore last round's teams | Yes/No |
| Players | Move a player to spectator (AFK) | pick player, then Yes/No |
| Players | Kick a player, or **troll kick** (kick + can't rejoin for 5 minutes, no real ban) | pick player, then Yes/No |
| Rules | T1-only mode on/off | Yes/No (`sm_forcet1`) |
| Rules | Tank horde monitor on/off | Yes/No |
| Rules | Tank / witch chance per map: 0%, 50%, 100% | menu, then Yes/No (applies next map) |
| Rules | Alltalk on/off | Yes/No |
| Admin only | Force-pass / cancel the current vote | `!admin` |

Not suggested: "give HP" (changes versus balance; `!heal` covers griefing) and ban votes (troll
kick covers it without permanent bans).


**Decided 2026-10-02:** the list above is approved, `!menu` is the name. Additions:
- **Kick vote works like vanilla's:** kick plus a short temporary ban (default 5 minutes,
  configurable; 0 = kick only), so a kicked troll can't rejoin right away. SourceMod's own kick only
  kicks.
- **Pause only by vote:** players can't `!pause` directly any more; they call a Yes/No pause vote
  (randoms can't abuse it). Unpausing still works as in `pause.smx` (both teams ready up). Admins keep
  instant **force pause / force unpause** in the `!admin` *Lefordianos* category.
- **Mute/gag vote** (suggested): silence a player's voice and chat for the rest of the map.
- Client cvar checks are covered by the new `lef_client_cvars` (ZoneMod's list, without confogl).

**Later:** show who voted Yes/No on each vote (user will look for existing plugins), vote cooldowns,
minimum players, whether spectators can call/join votes (Harry's plugin has these as cvars).

### Votes, and replacing Automatic Campaign Switcher
Harry's archived `l4d_votes_5` (L4D1_2-Plugins) is a good base to learn from: a `!votes` menu
(change official/custom map, restart, kick, give HP, alltalk) on the game's vote screen. Its
successor `l4d2_vote_change` is private (paid, no source). Harry's `match_vote` in Sourcemod-Plugins
is another example. Idea: our own `!votes` menu that also replaces ACS: at the finale, pick the next
campaign from a menu (list from the mission manager), then a Yes/No vote on the game's screen
(multiple-choice votes don't exist in L4D2). Other items: T1 mode, tank horde monitor on/off,
balanced shuffle.

### Tank horde monitor (undecided)
Made switchable: our patched copy in `plugins/l4d2_tank_horde_monitor` adds
`l4d2_tank_horde_monitor_enable` (0 = vanilla) and a once-per-round rule reminder. Still undecided
whether to turn it on; a vote for it will go in the `!votes` menu.

### Balanced teams
Roster file with our SteamIDs, a name and a manual level 1–5 (randoms get a default level).
`!balance` / admin menu "Balanced shuffle" tries every split of the players present (8 players = 70
splits) and picks the most even one. Part of `lef_teams_panel`.

### Balanced teams (built 2026-10-02)
Built into `lef_teams_panel` as `sm_balanceteams` (admin menu and `!votes`). The roster lives in
`configs/lef_roster.cfg` on the server (the package ships only `lef_roster.example.cfg`, so updates
never overwrite it). Waiting for the SteamIDs and, optionally, levels.

### New ideas (2026-10-02), proposed, not decided yet
1. **Finale campaign vote**: ACS (already in the package) has its own plurality vote, `!mapvote`
   (each player picks a campaign, `!mapvotes` shows the count, the winner plays next). The Yes/No vote
   screen can't do "pick one of many", so keep ACS's vote, open its menu automatically when the finale
   starts, and add it to `!menu`.
2. **Show who voted**: no extra plugin needed. Clients send `Vote Yes` / `Vote No` for every vote on
   screen (the game's own and BuiltinVotes'), and the `VotePass` / `VoteFail` messages mark the end, so
   a listener can print "Yes: A, B — No: C" after each vote.
3. **Bots on survivors get focused**: avoid uneven games first: a team size vote (2v2 / 3v3 / 4v4,
   `survivor_limit` + `z_max_player_zombies`, from the next map); stricter balance on join
   (`l4d_afk_commands_versus_teams_unbalance_limit 1`); tell spectators they can take the bot. A
   damage reduction for bots would be a balance change, so only as an option, off by default.
4. **Better survivor bots**: user is looking for plugins.
5. **Holding an infected too long**: warning to the player (and optionally the team) after N seconds
   alive or in ghost mode without attacking. Warnings only.
6. **Rushers and players left behind**: warnings by flow distance from the team, with exceptions (last
   one alive, teammates incapped or pinned, crescendo/gauntlet events, finales). Harry's `no-rushing`
   teleports and slays, which is too harsh for us; borrow its distance logic only.
7. **Dead Center mall route**: ZoneMod's `c1m3_mall.cfg` doesn't force a route (it only speeds up the
   lower route's doors). Check in game with `stripper_dump` which route logic the map has, then decide
   whether to add a random pick like The Parish.
8. **Round start panel and waiting for players ("+1")**: Ready-Up (competitive) has an auto-start mode
   (`l4d_ready_enabled 2`, nobody presses F1) and a panel footer other plugins can write to, but its
   auto-start only waits for players still loading. Options: our own light "start hold" (survivors
   can't leave the saferoom while a "+1 wait" vote is active, countdown, vote to extend, newcomer goes
   to the smaller team) plus a start panel (tank/witch %, info) shown until someone leaves the saferoom,
   SI attack or N seconds; or Ready-Up auto-start with our lines in its footer.
9. **Tank tips**: when a player becomes the tank, a short hint with a few tips (wait for your team to
   respawn and call the hit, avoid open areas, use hittables and rocks, don't chase into the saferoom).
10. **Hours and VAC bans on join**: Harry's `vacbans` (Sourcemod-Plugins; needs the Socket extension
   and a Steam Web API key) and Forgetest's `l4d2_playtime_interface` (MoYu; needs REST in Pawn and a
   key). Private profiles hide hours.
11. **REST in Pawn (ripext)**: an HTTP + JSON extension (Windows and Linux). With one API key it would
   cover hours, bans, Discord messages (match recap, admin calls) and update checks. Cost: one more
   extension to keep up to date.

### Windows and Linux
Everything must run on both:
- Our plugins: the same `.smx` runs on both. Fine.
- Plugins with gamedata (signatures/offsets): check each file has Windows **and** Linux entries.
- Extensions and Metamod plugins need both `.so` and `.dll`: the competitive repo ships both for its
  extensions; lakwsh's l4dtoolz and Stripper:Source have both builds.
- Our tools (`build.sh`, `tools/*.sh`) are bash: on Windows use Git Bash or WSL; a PowerShell
  version can come later if needed.

## Undo griefing: admin restore (built as `lef_admin_restore`, 2026-10-01)

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

## From the new sources (2026-10-01)

- **On-screen info (`lef_hud`)**: Mart's `l4d2_scripted_hud` shows that L4D2's built-in HUD text
  slots (the ones mutations use) can be written directly from SourceMod, with no VScript. We could
  keep a small line on screen, e.g. "Tank 63% · Witch none · Gap 300", fed by `lef_boss_spawns` and
  `lef_score_info`, instead of only announcing in chat. Only 4 slots exist and mutations use them,
  so it should step aside in those modes.
- **Vote_Mode on the game's vote screen**: Silvers' `Vote_Mode` switches game mode by vote but uses
  a menu vote. A version (or wrapper) using builtinvotes would fit the vote-screen idea above. The
  vote screen is Yes/No only, so it would be "Switch to Realism?" after picking from a menu.
- **`!lef` help menu**: one menu listing our commands (`!teams`, `!swapwith`, `!bosses`, `!score`,
  `!comeback`...) instead of pan0s' generic `!menu`.
- **Stats for balanced teams**: pan0s' SRS shows which stats are worth recording; our version
  would use non-blocking database queries and no extra extensions.

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

- **lef_votes** and **lef_menu**: `!votes` from a config file (the list above, kick with a 5-minute ban, pause only by vote, admin *Lefordianos* category with force pause/unpause and pass/cancel) and `!menu` for players. Not yet tested in game. Still to do: the ACS-style finale vote, the balanced shuffle (waits for the roster) and showing who voted.
- **lef_client_cvars**: client cvar checks (fullbright, fog, flashlight...) without confogl, ZoneMod's list. Not yet tested in game.

- **Lite config package**: `configs/lite/manifest.txt` + `tools/build_lite.py` (170 plugins, Windows and Linux), our configs in `configs/lite/left4dead2/` (ZoneMod values, per-mode files, server messages). All tools moved to Python so they also run on Windows.

- **lef_karma_sounds**: our own random sound on karma kills, waiting for the sound files.
- **l4d2_tank_horde_monitor (patched)**: on/off switch and rule reminder.
- **Lite stripper**: generated from ZoneMod's with `tools/make_stripper.py`.

- **lef_saferoom_doors**: who opened the start saferoom door, who closed the end one with teammates outside. Not yet tested in game.
- **lef_t1_mode**: switchable T1-only weapons mode (cvar, admin, `!t1` vote), configurable list. Not yet tested in game.

- **lef_admin_restore**: `!heal`, `!restore`, `!teamdamage`, admin heads-ups. Not yet tested in game.
- **lef_score_info** (option A) and **lef_comeback_bonus** (option C): built, not yet tested in game.
- **lef_boss_spawns**: per-map tank/witch chance (same for both teams), second-half bosses spawn on
  the first half's spot (port of confogl's BossSpawning), flows announced. Works with
  `witch_and_tankifier` / `l4d_boss_percent`, without Ready-Up or confogl.
- **l4d_tank_control_eq (patched)**: tank rotation without the Ready-Up requirement.
- **lef_teams_panel**: rewrite of BwA Jester's players panel. `!teams`, `!lastteams`,
  `!swapwith`, and a Team Management admin menu (move, swap, flip, shuffle, restore).
