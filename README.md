[Español](README.es.md)

# Lefordianos Plugins

SourceMod plugins and server configs for our Left 4 Dead 2 versus server. The goal is
**vanilla versus with the quality-of-life and bug fixes** from ZoneMod and friends, without the
competitive balance changes.

What it gives players and admins: [docs/BENEFITS.md](docs/BENEFITS.md). What was built when:
[CHANGELOG.md](CHANGELOG.md). Context for AI assistants: [AGENTS.md](AGENTS.md).

## Layout

| Folder | What's in it |
|---|---|
| [`plugins/`](plugins/) | Our plugins: new ones, and rewrites/improvements of older ones. One folder per plugin with `scripting/`, `translations/` and a README. |
| [`alliedmodders/`](alliedmodders/) | Other authors' original sources, kept unchanged for reference. One folder per author. |
| [`configs/`](configs/) | Server setups: a lite one without confogl (plugin list to pick from in [`configs/lite/PLUGINS.md`](configs/lite/PLUGINS.md)), and a confogl match mode later. |
| [`IDEAS.md`](IDEAS.md) | Ideas and what's in progress. |

Every doc has a Spanish version next to it (`*.es.md`); the plugin picker is a single file in both languages.

## Plugins

| Plugin | What it does |
|---|---|
| [`lef_teams_panel`](plugins/lef_teams_panel/) | `!teams` panel, `!swapwith` swap requests, and a Team Management admin menu. |
| [`lef_boss_spawns`](plugins/lef_boss_spawns/) | Per-map tank/witch chance, same spawn spot for both teams, flows announced. |
| [`lef_score_info`](plugins/lef_score_info/) | Explains versus scores: map value, gap, what's needed to come back, map wins. No point changes. |
| [`lef_comeback_bonus`](plugins/lef_comeback_bonus/) | The trailing team earns a capped bonus on the distance it covers. |
| [`lef_admin_restore`](plugins/lef_admin_restore/) | `!heal`, and `!restore` to undo what teammates did to a survivor (HP, incaps, team kills, items). |
| [`lef_saferoom_doors`](plugins/lef_saferoom_doors/) | Announces who opened the start saferoom door and who closed the end one with teammates outside. |
| [`lef_t1_mode`](plugins/lef_t1_mode/) | Switchable T1-only weapons mode (cvar, admin or `!t1` vote), configurable. |
| [`lef_client_cvars`](plugins/lef_client_cvars/) | Kicks players whose client cvars give an advantage (fullbright, no fog...); ZoneMod's list, without confogl. |
| [`lef_votes`](plugins/lef_votes/) | `!votes` on the game's vote screen, from a config file: maps, teams, kick (with a short ban, like vanilla), AFK, mute, rules, pause only by vote. Plus a *Lefordianos* category in `!admin`. |
| [`lef_menu`](plugins/lef_menu/) | `!menu`: every player command on the server in one menu; hides what isn't installed. |
| [`lef_round_start`](plugins/lef_round_start/) | Start panel (tank/witch spots, teams) and `!wait`: a vote keeps the saferoom closed until a friend joins. No Ready-Up needed. |
| [`lef_game_hints`](plugins/lef_game_hints/) | Warnings only: rushing, falling behind, holding an infected too long; tips for the tank. |
| [`lef_bot_protect`](plugins/lef_bot_protect/) | Survivor bots take 15% less damage from infected players, so they aren't free kills. |
| [`lef_ranks`](plugins/lef_ranks/) | Ranking from map wins (Elo, adapted to teams): `!rank`, `!top`; feeds the balanced shuffle. |
| [`lef_steam_bans`](plugins/lef_steam_bans/) | Tells admins when a joining player has VAC, game or community bans (bans only, nothing else). Needs REST in Pawn and a Steam API key. |
| [`lef_karma_sounds`](plugins/lef_karma_sounds/) | Our own random sound on karma kills (needs FastDL, see [docs/FASTDL.md](docs/FASTDL.md)). |
| [`l4d2_tank_horde_monitor`](plugins/l4d2_tank_horde_monitor/) | Patched copy of the competitive repo's tank horde monitor with an on/off switch and a rule reminder. |
| [`l4d_tank_control_eq`](plugins/l4d_tank_control_eq/) | Patched copy of the competitive repo's tank rotation that no longer requires Ready-Up. |

## Building

All tools are Python 3 and work on Windows and Linux (on Windows use `py` instead of `python3`).

```bash
python3 tools/fetch_refs.py       # once: clone the reference repos next to this one (pinned commits)
python3 tools/get_sourcemod.py    # once: download our pinned SourceMod 1.12 compiler into tools/sourcemod/
python3 tools/get_extensions.py   # once: download extensions we ship (REST in Pawn) into tools/extensions/
python3 tools/build.py            # build our plugins into build/   (./build.sh is a shortcut)
python3 tools/build.py lef_t1_mode
python3 tools/build_lite.py       # build the full lite config package into build/lite/
python3 tools/make_stripper.py    # regenerate the lite Stripper files from ZoneMod's
```

The compiler version is pinned in `tools/SOURCEMOD_VERSION` (`python3 tools/get_sourcemod.py latest`
updates it). Third-party include files (Left4DHooks, colors, builtinvotes, multicolors...) come from the
reference repos next to this one. Set `REFS=/some/path` if they live elsewhere.

**Lite config:** see [configs/lite/INSTALL.md](configs/lite/INSTALL.md) to build and install it on a server.

## Reference repos and credits

See [CREDITS.md](CREDITS.md) for every source, its authors and links.

Kept next to this repo, read-only: L4D2-Competitive-Rework (SirPlease), L4D1_2-Plugins
(Harry Potter), MoYu_Server_Stupid_Plugins (Forgetest), Left4DHooks (Silvers),
Practiceogl-Rework, l4d2_mission_manager, sourcetvsupport (shqke).
