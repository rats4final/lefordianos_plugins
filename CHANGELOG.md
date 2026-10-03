[Español](CHANGELOG.es.md)

# Changelog

What was built, by date. Nothing here has been tested on a real server yet. Details and reasons are
in [IDEAS.md](IDEAS.md); what each part gives players is in [docs/BENEFITS.md](docs/BENEFITS.md).

## 2026-10-04

- **Mute vote:** pick voice, chat or both; it lasts until the round ends, as a warning (was voice and chat
  for the rest of the map).
- **Choose the tank** in `!votes` (infected team only): the picked teammate gets the next tank, or the
  current one if a tank is in play. Admins already had `sm_forcepass`, `sm_taketank`, `sm_givetank`.
- **Tank tip fixed:** with our tank control, one player gets 2 control bars, then the tank goes to a bot.
- **`lef_campaigns` replaces ACS:** the next campaign is voted in `!votes` on the game's vote screen
  (any time), `!next` shows it; without a vote, the next one in the list.
- **Game mode votes** on the game's vote screen (`!votes` > Change game mode), using Vote_Mode's list;
  its old chat vote is admin-only.
- **Quad caps** possible (`l4d2_dominators 0`, like ZoneMod), at the owner's request.
- **M key** (team menu) works again (`l4d_afk_commands_pressM_block 0`); it follows the same balance
  rules as `!survivors`/`!infected`.
- **Tank tips:** rock controls (right click / E / R), the control meter and `!pass`.
- **Server messages** rewritten: `!menu`, `!votes`, `!wait`, `!rank`, stats, the start panel, tank tips.
- **`lef_ranks`:** a ranking from map wins (Elo for teams), `!rank` and `!top`; the balanced shuffle
  uses its points once a player has 5 ranked maps (roster levels before that).
- **c5m5 (The Parish bridge):** no more 4 medkits in the truck by the tank (ZoneMod meant them as pills,
  via confogl); the map's normal random items are back.
- **`!wait`:** 3-2-1 countdown with Ready-Up's beeps when the wait ends; on a campaign's first map
  (no saferoom box) survivors who wander off while waiting are teleported back to where they stood
  (freezing is an option), which is why the hold didn't work there.
- **Tank reminders** (`lef_boss_spawns`): every 2 minutes while a tank is still to come, and a warning
  when survivors get within 5% of it.
- **Witch spawn sound** changed to the witch's own tune: it used the same sound as the tank notice.
- **Every skill report** (skeets, crowns, deadstops, pops...) is shown in chat.

## 2026-10-03

- **Fix (first night with players):**
  - Harry's witch notifier had no translation file in the package: the packager didn't understand file
    names joined with SourcePawn's `...` operator. Now it does (no other plugin was affected).
  - The tank horde monitor's rule hint used two team colors (`{red}` and `{blue}`), which the color
    library refuses; now `{red}` and `{olive}`.
  - `l4d2_playstats` overflowed its console buffer after a long session with many players coming and
    going. Patched copy with room for 32 blocks instead of 10.
- **Boomer vomit:** `vomit_collide_strict 0`. `l4d_vomit_trace_patch` made the vomit need a survivor's exact
  hitbox (ZoneMod's choice); players felt the range was shorter. Its teammate-blocking fix stays.
- **Turned off** `boomer_horde_equalizer_refactored` for now: the owner suspects it misbehaves.
- **Removed** Silvers' `Dynamic_Light` (the extra light where survivors point their flashlights), at the
  owner's request.
- **Your own settings:** `cfg/lefordianos/custom.cfg` runs at the end of `common.cfg` every map, so its
  values win over server.cfg and plugin configs; updates only ship `custom.example.cfg`.
- **Map transitions** (Harry Potter's `l4d2_map_transitions` + `l4d2_transition_info_fix`) to join
  campaigns in versus.
- **Fix (first server test):** 20 fix plugins failed to load on the server because their gamedata files
  weren't in the package: the packager only found gamedata loaded the old way (`LoadGameConfigFile`),
  not the newer `new GameData(...)`. Now it finds both.
- **Fix:** `l4d_afk_commands` needs a newer Actions extension than the competitive repo ships; the
  package now has Actions 3.9.2 (keeps every older function).
- **Fix:** `l4d2_survivor_mourn_fix` needs `sceneprocessor`; now included.
- **Fix (second server test):**
  - `pause` threw errors every second while paused: it needs `sv_maxplayers`, which only exists with
    l4dtoolz. Patched copy in `plugins/pause`.
  - `si_class_announce` called Ready-Up without checking it was loaded. Patched copy in
    `plugins/si_class_announce`.
  - `lerpmonitor` allowed at most 67 ms (a 100-tick value), so players with the game's default lerp
    (100 ms) were moved to spectators. Now up to 100 ms.
  - Players with Steam in "Spanish - Latin America" saw English: SourceMod treats it as a separate
    language (`las`). Every Spanish translation in the package now also covers it.
- **Start panel:** shows the infected team's starting classes; stays 15 s after survivors leave the
  saferoom and hides at the first infected hit (up to 60 s).
- **Witch spawns are announced** (Harry Potter's `tank_witch_spawn_notify`).
- **Next campaign** entry in `!votes` and `!menu` only shows on finale maps: ACS only allows that vote
  there and answered "only on a finale map" elsewhere (`"finale_only"` key). Changing campaign
  mid-campaign is still `!votes` > Change map.
- **ACS in Spanish:** it only shipped English, Chinese, French and Russian; we add Spanish (and Latin
  American Spanish).
- **Fix:** settings changed by vote or admin (T1 mode, tank/witch chance, horde monitor, all talk) were
  undone on the next map, because every map change re-runs the configs. They now last until the server
  is empty (`lef_votes` `"persist"` key, and `lef_t1_mode` itself).
- **Lite config:** players' workshop addons off for everyone (`l4d2_addons_eclipse 0` in `common.cfg`).
- **Lite config:** an example `server.cfg` (from the competitive repo's and Harry Potter's, checked
  against the Valve wiki) and `test_bots.cfg` / `test_off.cfg` for testing alone with bots.

## 2026-10-02

### New plugins
- **`lef_round_start`**: start-of-round panel (tank/witch spots, teams, commands) and `!wait`, a vote
  that keeps the saferoom closed until a friend joins. `+1` in chat only gives a private tip. No
  Ready-Up needed.
- **`lef_game_hints`**: warnings only, for rushing, falling behind and holding an infected too long.
  Tips for whoever becomes (or is passed) the tank.
- **`lef_bot_protect`**: survivor bots take 15% less damage from infected players, so they aren't
  free kills.
- **`lef_steam_bans`**: tells admins about joining players' VAC, game and community bans (bans only,
  no hours). Uses REST in Pawn and a Steam Web API key.
- **`lef_votes`**:
  - `!votes` from a config file: maps, teams, kick with a 5-minute ban (like vanilla), AFK, mute,
    rules, pause only by vote;
  - a *Lefordianos* category in `!admin`;
  - after every vote, the list of who voted Yes and No;
  - ACS's next-campaign vote opens on finale maps.
- **`lef_menu`**: `!menu` with every player command on the server.
- **`lef_client_cvars`**: kicks players with advantage client cvars (fullbright, no fog...),
  ZoneMod's 59-cvar list, without confogl.
- **`lef_saferoom_doors`**: who opened the start saferoom door, who closed the end one on teammates.
- **`lef_t1_mode`**: switchable T1-only weapons mode (vote, admin or cvar).
- **`lef_karma_sounds`**: our own sounds on karma kills (waiting for the sound files).

### Changed
- **`lef_teams_panel`**:
  - balanced shuffle, using a roster of SteamIDs and levels;
  - tells newcomers and spectators how to even out the teams.
- **`l4d2_tank_horde_monitor`** (patched): on/off switch and a rule reminder; installed off.

### Lite config
- Assembled: 177 plugins for Windows and Linux.
- **Settings:**
  - ZoneMod values for the chosen gameplay plugins;
  - 50% tank and 50% witch chance per map;
  - nobody can join the team that already has more humans;
  - ACS announces its vote in chat.
- **Map files:**
  - Stripper configs generated from ZoneMod's, minus the special reworks and a few global changes;
  - per-game-mode configs through Harry Potter's `gamemode-based_configs`.
- **Plugins from other sources:**
  - anti-cheat: SMAC and Little Anti-Cheat (srcdslab), LAC logging only;
  - REST in Pawn extension.

### Tools and docs
- **Tools:** Python build tools for Windows and Linux: pinned SourceMod 1.12 compiler, pinned
  reference repos, pinned extensions, lite package builder, Stripper generator.
- **Docs:** credits for every source; English/Spanish docs; FastDL guide; AGENTS.md for AI sessions.
- **References:** AlliedModders plugins imported (Mart, NoroHime, Silvers, pan0s). AoC-Gamers repos
  reviewed.

## 2026-10-01

- **Repo started.** Reference repos read; ideas list; bilingual plugin picker for the lite config.
- **`lef_teams_panel`**: rewrite of -=BwA=- Jester's Players Panel (`!teams`, `!swapwith`, Team
  Management admin menu).
- **`lef_boss_spawns`**:
  - per-map tank/witch chance, the same for both teams;
  - same spawn spots in both halves;
  - flows announced.
- **`lef_score_info`**: `!score` explains versus scoring (map value, gap, what's left).
- **`lef_comeback_bonus`**: a bonus for the trailing team (built, not in the lite package).
- **`lef_admin_restore`**: `!heal` and `!restore` to undo griefing (team damage, incaps, lost items).
- **`l4d_tank_control_eq`**: patched to run without Ready-Up.
