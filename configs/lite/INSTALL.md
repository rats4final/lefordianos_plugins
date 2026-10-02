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
python3 tools/get_extensions.py  # first time: downloads extensions we ship (REST in Pawn)
python3 tools/build_lite.py      # builds the package
```

The result is `build/lite/left4dead2/` (about 22 MB, 178 plugins), plus `build/lite/CONTENTS.txt`
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
- `sm exts list`: shows **Actions**, **BuiltinVotes**, **CollisionHook**, **REST in Pawn**, **Source Scramble**, all running.
- `sm plugins list`: look for plugins marked as failed.
  - **On Windows**, `l4d2_chainsaw_fix` fails on purpose: it fixes a Linux-only crash.
- Errors are logged in `addons/sourcemod/logs/errors_<date>.log`.

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
| Bot damage reduction (15%), pace/holding warnings, start panel and `!wait` | `cfg/sourcemod/lef_bot_protect.cfg`, `lef_game_hints.cfg`, `lef_round_start.cfg` |
| Server name, RCON, region, lobby/matchmaking, addons | `cfg/server.cfg` (start from `cfg/server.example.cfg`) |
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

## Not included (on purpose)

- `lef_comeback_bonus` and `l4d2_penalty_bonus`: unticked in the picker.
- l4dtoolz (more than 8 players, tickrate): on hold until we test lakwsh's version.
- Silvers' `plugin_updates_checker` (needs an HTTP extension we don't have) and `l4d_glare`
  (needs two more plugins).
- The tank horde monitor **is** included, but switched off (`l4d2_tank_horde_monitor_enable 0`).
- Harry Potter's `l4d2_karma_kill` is added (not in the picker) because `lef_karma_sounds` needs it.
