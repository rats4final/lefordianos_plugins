# AGENTS.md — read this first

Context for AI assistants (Claude Code, Codex, etc.) working on this repo. It is the short version of
everything decided so far; the long versions are in [IDEAS.md](IDEAS.md) (decisions, plans, research),
[CHANGELOG.md](CHANGELOG.md) (what was built when) and [docs/BENEFITS.md](docs/BENEFITS.md) (what each
part gives players and admins). This file is in English only on purpose: it's for tools, not players.

## What this is

L4D2 SourceMod plugins and server configs for a **friends' vanilla versus server** ("Lefordianos").
They play normal versus with bug fixes and quality-of-life from ZoneMod and others, and want to **keep
the vanilla feel**: no competitive balance changes unless chosen on purpose (the few chosen ones are
marked in [configs/lite/PLUGINS.md](configs/lite/PLUGINS.md)).

- Owner: rats4final (GitHub `rats4final/lefordianos_plugins`, branch `main`, public repo).
- Two configs: the **lite config** (no confogl; assembled, ready to test) and a confogl
  "Lefordianos Vanilla+" match mode (lowest priority, not started).
- Must work on **Windows and Linux** servers (both extension builds, gamedata for both, Python tools).

## Layout

| Path | What |
|---|---|
| `plugins/<name>/` | Our plugins: `scripting/`, `translations/` (+ `es/`), `configs/`, `README.md` + `README.es.md` |
| `alliedmodders/` | Plugins imported from AlliedModders authors (credited) |
| `configs/lite/` | The lite config (`left4dead2/cfg/server.example.cfg`, `lefordianos/test_bots.cfg` for solo testing): `PLUGINS.md` (bilingual picker), `manifest.txt` (what goes in the package), `stripper_rules.txt`, `left4dead2/` (our cfg files), `INSTALL.md` |
| `tools/` | Python build tools (see below); `refs.txt` pins the reference repos |
| `docs/` | FastDL guide, benefits overview |
| `IDEAS.md`, `CHANGELOG.md`, `CREDITS.md`, `README.md` | Each with a Spanish twin `*.es.md` |

Reference repos live **next to** this one (`../`, pinned in `tools/refs.txt`, fetched with
`tools/fetch_refs.py`). They are read-only references: never edit them.

## Build

```bash
python3 tools/fetch_refs.py       # reference repos (once)
python3 tools/get_sourcemod.py    # pinned SourceMod 1.12 compiler -> tools/sourcemod/
python3 tools/get_extensions.py   # pinned extensions (REST in Pawn) -> tools/extensions/
python3 tools/build.py [plugin]   # compile ours -> build/ (prints compiler output only if any)
python3 tools/build_lite.py       # the full lite package -> build/lite/ (+ CONTENTS.txt); warns on missing files or one-platform files
python3 tools/make_stripper.py    # regenerate lite Stripper files from ZoneMod's, minus stripper_rules.txt
```

## Conventions

- **Reuse first.** Before writing a plugin, check whether a proven one in the reference repos does
  the job; build only the gaps, and say in the README which jobs are delegated to what.
- **Docs are bilingual**: every doc has a `*.es.md` twin; `PLUGINS.md` is one bilingual file;
  translations ship `en` and `es`. Write plain language and say *why*.
- **Credit everyone**: original authors in `CREDITS.md`/`.es.md` and in the plugin's README/myinfo.
- Our plugins: `lef_` prefix, cvars `lef_<area>_*`, `AutoExecConfig`, new syntax, Left4DHooks instead
  of private gamedata, colors.inc `CPrintToChat`.
- Adding a plugin means also updating: `configs/lite/manifest.txt`, `PLUGINS.md`, the plugin tables
  in `README.md`/`.es.md`, `CREDITS` (if based on someone's work), `IDEAS` "Done", `CHANGELOG`,
  `docs/BENEFITS`, and the settings table in `configs/lite/INSTALL*.md` if it has things to configure.
- Config files the admin fills in (roster, keys) ship as `*.example.cfg` or in `cfg/sourcemod/`
  so an update never overwrites them. **Never commit secrets** (Steam API key) or real SteamIDs.

### Gotchas learned the hard way

- colors.inc already defines `CReplyToCommandEx` and `CheckAccess`: don't reuse those names.
- In translation phrases a literal percent sign must be `%%`.
- l4d2util defines `TEAM_SPECTATOR`/`TEAM_SURVIVOR`; don't redefine them when including it.
- Folders starting with `-` or containing spaces (`-L4D-L4D2-Enhanced-Throwables`, `left 4 fix`,
  `The Last Stand`) need `./` or quotes in shell commands and the manifest.
- Stripper entries without a mode line inherit the previous `filter:`/`add:`/`modify:`;
  `make_stripper.py` re-inserts modes when it removes sections.
- Harry's `gamemode-based_configs` runs `cfg/sourcemod/gamemode_cvars/<mode>.cfg` *after* plugin
  autoexec configs, so values there (and in `lefordianos/common.cfg`, which each mode file execs) win.
- `chainsaw_fix` is Linux-only by design and fails to load on Windows; harmless.
- You can't print to chat from inside a usermessage hook: defer with `RequestFrame`.
- **Every map change re-runs the configs** (server.cfg, each plugin's `cfg/sourcemod/*.cfg`, and the
  game-mode cfg that execs `common.cfg`), so a setting changed at runtime (vote, admin) silently reverts.
  Re-apply it in `OnConfigsExecuted` and forget it once the server is empty (wait ~60 s: map changes
  also disconnect everyone briefly). See `lef_votes` (`"persist"`) and `lef_t1_mode`.
- Plugins load gamedata as `LoadGameConfigFile("x")` **or** `new GameData("x")` / `new GameDataWrapper("x")`;
  `build_lite.py` must catch both (it once missed 20 files). Prebuilt `.smx` from other repos may need
  newer extensions than the competitive repo ships (Actions: we ship 3.9.2 via `get_extensions.py`).
- SourceMod gives Steam's "Spanish - Latin America" the code **`las`**, separate from `es`, with no
  fallback. `build_lite.py` copies every `es` translation to `las`; language checks in our plugins
  must accept both.
- Some competitive plugins assume l4dtoolz (`sv_maxplayers`) or Ready-Up natives; we don't run either,
  so check for them (`FindConVar` null, `GetFeatureStatus`). Patched copies live in `plugins/pause` and
  `plugins/si_class_announce`.
- The Valve wiki and AlliedModders block scripted fetches (bot checks); the Internet Archive copy of
  the wiki's L4D2 cvar list works (`web.archive.org/web/2025/<url>`).

## Working with the owner

- Speaks Spanish and English; recent conversations are in Spanish. Explain simply, with the why.
- On real trade-offs (balance changes, privacy, scope), ask with a recommendation; routine choices
  don't need a question.
- **Ask before spawning subagents** (they cost a lot of tokens).
- Commit only when asked (they have approved "commit and push" for this repo's normal flow). Split
  commits by layer (tools / plugin / config / docs), stage explicit paths (never `git add -A`), no AI
  co-author trailers or "generated with" footers. Work happens on `main`.
- WSL machine with a 10 GB cap shared with other work: check `free -g` before heavy runs.
  Builds here are light.

## Status (2026-10-03)

**Built, compiled, in the lite package (179 plugins), not yet tested in game:**
`lef_teams_panel` (teams panel, balanced shuffle with roster, balance hints), `lef_boss_spawns`,
`lef_score_info`, `lef_admin_restore`, `lef_saferoom_doors`, `lef_t1_mode`, `lef_karma_sounds`,
`lef_client_cvars`, `lef_votes` (config-driven votes, vanilla-like kick, pause by vote, who voted,
ACS finale vote, admin category), `lef_menu`, `lef_round_start` (start panel, `!wait`),
`lef_game_hints`, `lef_bot_protect` (15%), `lef_steam_bans` (bans only, via REST in Pawn), patched
`l4d_tank_control_eq` and `l4d2_tank_horde_monitor` (installed off). `lef_comeback_bonus` exists but is
not in the lite package.

**Waiting on the owner:** Steam Web API key (goes in the server's `cfg/sourcemod/lef_steam_bans.cfg`),
SteamIDs for `lef_roster.cfg`, a `stripper_dump` of c1m3 (mall route), survivor bot AI plugins, the
name of the AlliedModders VAC plugin at `showthread.php?p=1335581` (the forum blocks automated reads),
karma sound files, FastDL host.

**Parked:** tickrate, l4dtoolz (lakwsh's likely, plus Harry's `l4d_unreservelobby` for 9+ players),
demo recording (the owner's server already has shqke's sourcetvsupport + disable_cameras installed by hand, not from our package; still missing: an auto-recorder, e.g. shqke's autorecorder or AoC's Lilac-SourceTV), Vanilla+ confogl mode,
stats-based balance levels (AoC Player-Stats/Skills), Family Sharing detection (AoC Family-Share).

**Testing (2026-10-03):** first runs on the owner's Windows server, alone with bots. Fixed so far:
missing gamedata (packager), Actions too old, missing sceneprocessor, pause/si_class_announce errors,
lerp limit, Latin American Spanish, panel timing, witch notice, finale-only campaign vote. To verify
with more players: the jockey "longer stagger" report (probably vanilla: jockey/hunter landings stagger
nearby survivors; suspects if not: l4d2_getup_slide_fix, l4d2_godframes_control_merge), votes and
`!wait` with real people, session persistence across map changes.

**Owner's server:** Windows, `F:\L4D2SERVER2026\l4d2-server` (WSL: `/mnt/f/...`), game folder
`l4d2/left4dead2`, started by `start-server.bat` (versus, c2m1_highway, `+tv_enable 1 -hltv`). The lite
package was copied there on 2026-10-03 with rsync (backup in `F:\L4D2SERVER2026\backups\`), leaving out
`l4d2_chainsaw_fix` (Linux-only). Its `cfg/server.cfg` is our example, not yet customised. The owner's own
settings are in its `cfg/lefordianos/custom.cfg` (tv_autorecord, map transitions, z_ghost_delay 16,
bot cvars); two lines are commented out pending a decision: `sm_onlyforce 1` (would break the pause
vote) and `auto_all_bot_game_enable` (no plugin we know creates it).

**Next step:** the owner tests with more players and reports the error log and what felt wrong.
