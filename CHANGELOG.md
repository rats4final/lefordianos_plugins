[Español](CHANGELOG.es.md)

# Changelog

What was built, by date. Nothing here has been tested on a real server yet. Details and reasons are
in [IDEAS.md](IDEAS.md); what each part gives players is in [docs/BENEFITS.md](docs/BENEFITS.md).

## 2026-10-03

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
