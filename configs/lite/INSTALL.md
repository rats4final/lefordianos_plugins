[Español](INSTALL.es.md)

# Lite config: build and install

The lite config is our server setup **without confogl**: bug fixes, quality-of-life, our plugins,
anti-cheat, and Stripper map fixes, keeping vanilla versus. What's in it is chosen in
[PLUGINS.md](PLUGINS.md); how it's packaged is in [manifest.txt](manifest.txt).

Works on **Windows and Linux** servers: the package has both builds of every extension.

## What you need

- A L4D2 dedicated server with **Metamod:Source** and **SourceMod 1.12** installed.
- On the computer where you build the package (can be the server, your PC, or WSL):
  **Python 3.8+** and **git**. On Windows, install both from python.org and git-scm.com; then
  use `py` instead of `python3` below.

## 1. Build the package

From this repo's folder:

```bash
python3 tools/fetch_refs.py      # first time: clones the reference repos next to this one
python3 tools/get_sourcemod.py   # first time: downloads our pinned SourceMod compiler
python3 tools/get_extensions.py  # first time: downloads extensions we ship (REST in Pawn, Actions, l4dtoolz)
python3 tools/build_lite.py      # builds the package
```

The result is `build/lite/left4dead2/` (about 22 MB, 179 plugins), plus `build/lite/CONTENTS.txt`
with the plugin list. The build stops with warnings if anything is missing or only exists for one
platform.

## 2. Before copying

1. **Back up** the server's `left4dead2/addons/` and `left4dead2/cfg/`.
2. **Remove old copies** of the same plugins. Ours all go in `addons/sourcemod/plugins/lefordianos/`
   (except `left4dhooks.smx`, which replaces the one in `plugins/`). If the server already has, for
   example, `plugins/l4d_afk_commands.smx`, delete it, or the plugin loads twice. Compare with
   `build/lite/CONTENTS.txt`.
3. Stop the server.

## 3. Copy

Copy the **contents** of `build/lite/left4dead2/` over the server's `left4dead2/` folder, merging
folders and overwriting files.

At the **end** of the server's `cfg/server.cfg`, add:

```
exec lefordianos/server_base.cfg
```

No `server.cfg` yet, or want a clean one? Copy `cfg/server.example.cfg` to `cfg/server.cfg` and fill
in the lines marked `CHANGE ME` (name, RCON password, region, Steam group). It explains every line
and already ends with the `exec` above. It's built from the competitive repo's and Harry Potter's
server.cfg; updates only ship the example, so your `server.cfg` is never overwritten.

## Testing alone with bots

From the server console or RCON: `exec lefordianos/test_bots.cfg` turns on `sv_cheats` and lets a
versus game run with bot-only teams, so you can try plugins alone (play infected against bot
survivors, give yourself the tank, spawn things). The file lists handy commands. Undo it with
`exec lefordianos/test_off.cfg`, and never leave it on with randoms. It needs
`sv_allow_lobby_connect_only 0` (the example server.cfg's value).

## 4. Start and check

Start the server (extensions and Stripper need a full start, not just a map change), then in the
server console:

- `meta list`: shows **Stripper**.
- `plugin_print`: shows **L4DToolZ** (needed for `sv_steam_bypass`).
- `sm exts list`: shows **Actions**, **BuiltinVotes**, **CollisionHook**, **REST in Pawn**, **Source Scramble**, all running.
- `sm plugins list`: look for plugins marked as failed.
  - **On Windows**, `l4d2_chainsaw_fix` fails on purpose: it fixes a Linux-only crash.
- Errors are logged in `addons/sourcemod/logs/errors_<date>.log`.
- Players can't join ("No Steam logon", "bogus payload data", "session no longer available"):
  see [docs/CONNECTION.md](../../docs/CONNECTION.md).

## 5. Settings you may want to change

| What | Where |
|---|---|
| Tank/witch chance per map, T1 mode, tank horde monitor, anti-cheat bans, message interval | `cfg/lefordianos/common.cfg` |
| Settings for one game mode only | `cfg/sourcemod/gamemode_cvars/<mode>.cfg` (each starts with `exec lefordianos/common.cfg`) |
| Server messages | `addons/sourcemod/translations/smd_advertisements.phrases.txt` |
| Karma kill sounds | `addons/sourcemod/configs/lef_karma_sounds.txt` + [docs/FASTDL.md](../../docs/FASTDL.md) |
| Weapons replaced in T1 mode | `addons/sourcemod/configs/lef_t1_mode.cfg` |
| What players can vote on (`!votes`), and what `!menu` lists | `addons/sourcemod/configs/lef_votes.cfg`, `addons/sourcemod/configs/lef_menu.cfg` |
| Vote kick ban length, pause only by vote, who can start votes | `cfg/sourcemod/lef_votes.cfg` (created on first load) |
| Steam ban checks: the Steam Web API key (keep it private) | `cfg/sourcemod/lef_steam_bans.cfg`: `lef_bans_apikey "..."` |
| Keep scores when an admin changes the map inside the campaign (`lef_match_keep_scores`), warning seconds | `cfg/sourcemod/lef_match.cfg` |
| Order of the `!admin` menu | `addons/sourcemod/configs/adminmenu_sorting.txt` |
| Bot damage reduction (15%), pace/holding warnings, start panel and `!wait` | `cfg/sourcemod/lef_bot_protect.cfg`, `lef_game_hints.cfg`, `lef_round_start.cfg` |
| Server name, RCON, region, lobby/matchmaking, addons | `cfg/server.cfg` (start from `cfg/server.example.cfg`) |
| Steam check off (`sv_steam_bypass 1`, against "No Steam logon"; read the trade-off in `server.example.cfg`). A `server.cfg` copied before 2026-10-04 lacks it: add the line there or in `custom.cfg` | `cfg/server.cfg` |
| Language of the vote screen (one text for everyone) and of server messages | `addons/sourcemod/configs/core.cfg`: `"ServerLang" "es"` (default `"en"`). Menus and chat already follow each player's language |
| **Your own settings** (any cvar, map transitions...), never overwritten by updates | `cfg/lefordianos/custom.cfg` (copy it from `custom.example.cfg` once; runs last, so it wins) |
| Stripper changes | edit `configs/lite/stripper_rules.txt` here, run `python3 tools/make_stripper.py`, rebuild |

Each plugin also writes its own `cfg/sourcemod/<plugin>.cfg` the first time it loads; values in
`lefordianos/common.cfg` win over those, because they're applied afterwards.

## Updating

```bash
git pull
python3 tools/fetch_refs.py --update
python3 tools/build_lite.py
```

Then copy again (step 3). Settings files you edited on the server get overwritten, so keep your
changes in this repo (or re-apply them).

## Our server: the l4d2-server repo

The owner's server lives in its own private repo, [l4d2-server](https://github.com/rats4final/l4d2-server):
MetaMod, SourceMod and this package already installed for Windows, plus the server's own files
(`server.cfg`, `custom.cfg`, admins, roster). Its README explains how to run it on a new machine.
To update it, with that repo cloned next to this one:

```bash
python3 tools/build_lite.py
python3 tools/sync_server.py      # or: python3 tools/sync_server.py <path to l4d2-server>
```

`sync_server.py` copies the package in and removes files that left the package since the last sync
(it keeps the list in `lefordianos-package.txt` there). It never touches files the package doesn't
ship, and skips plugins the owner moved to `addons/sourcemod/plugins/disabled/`. Then commit and push
in l4d2-server, and on the server machine: stop the server, `git pull`, start it.

## Not included (on purpose)

- `lef_comeback_bonus` and `l4d2_penalty_bonus`: unticked in the picker.
- l4dtoolz's more than 8 players and tickrate: on hold. l4dtoolz itself ships, only for `sv_steam_bypass`.
- Silvers' `plugin_updates_checker` (needs an HTTP extension we don't have) and `l4d_glare`
  (needs two more plugins).
- The tank horde monitor **is** included, but switched off (`l4d2_tank_horde_monitor_enable 0`).
- Harry Potter's `l4d2_karma_kill` is added (not in the picker) because `lef_karma_sounds` needs it.
