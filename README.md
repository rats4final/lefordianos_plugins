[Español](README.es.md)

# Lefordianos Plugins

SourceMod plugins and server configs for our Left 4 Dead 2 versus server. The goal is
**vanilla versus with the quality-of-life and bug fixes** from ZoneMod and friends, without the
competitive balance changes.

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
| [`lef_karma_sounds`](plugins/lef_karma_sounds/) | Our own random sound on karma kills (needs FastDL, see [docs/FASTDL.md](docs/FASTDL.md)). |
| [`l4d2_tank_horde_monitor`](plugins/l4d2_tank_horde_monitor/) | Patched copy of the competitive repo's tank horde monitor with an on/off switch and a rule reminder. |
| [`l4d_tank_control_eq`](plugins/l4d_tank_control_eq/) | Patched copy of the competitive repo's tank rotation that no longer requires Ready-Up. |

## Building

```bash
tools/get-sourcemod.sh      # once: download our pinned SourceMod 1.12 compiler into tools/sourcemod/
tools/fetch-refs.sh         # once: clone the reference repos next to this one (pinned commits)
./build.sh                  # build everything
./build.sh lef_teams_panel  # build one plugin
```

Output goes to `build/`, laid out like a server's `left4dead2/` folder, so deploying is a copy:
`build/addons/sourcemod/plugins/*.smx` and `build/addons/sourcemod/translations/`.

The compiler is our own pinned SourceMod (version in `tools/SOURCEMOD_VERSION`; `tools/get-sourcemod.sh latest`
updates it). Third-party include files (Left4DHooks, colors, builtinvotes...) still come from the
reference repos next to this one. Set `REFS=/some/path` if they live elsewhere.

## Reference repos and credits

See [CREDITS.md](CREDITS.md) for every source, its authors and links.

Kept next to this repo, read-only: L4D2-Competitive-Rework (SirPlease), L4D1_2-Plugins
(Harry Potter), MoYu_Server_Stupid_Plugins (Forgetest), Left4DHooks (Silvers),
Practiceogl-Rework, l4d2_mission_manager, sourcetvsupport (shqke).
