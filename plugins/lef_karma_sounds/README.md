[Español](README.es.md)

# lef_karma_sounds — Lefordianos Karma Sounds

Plays one of **our own sounds**, picked at random, when a karma kill is announced (a survivor
charged, punched or pulled to their death). Left 4 Dead 2.

Works with either karma kill plugin: eyal282's `l4d2-karma-kill-system` or Harry Potter's
`l4d2_karma_kill`. They keep playing their own sound too (it's hard-coded in them).

## Adding sounds

1. Put the files on the **game server** under `left4dead2/sound/`, e.g.
   `left4dead2/sound/lefordianos/karma/fall1.wav` (`.wav` or `.mp3`).
2. List them in `addons/sourcemod/configs/lef_karma_sounds.txt`, one per line, relative to `sound/`:
   `lefordianos/karma/fall1.wav`
3. Put the `.bz2` copies on FastDL so players download them quickly ([docs/FASTDL.md](../../docs/FASTDL.md)).
4. Change map. `sm_karmasounds_test` plays one to check.

Files listed but missing on the server are skipped (and logged). With an empty list the plugin
does nothing, so it's safe to install before the sounds exist.

## Settings (`cfg/sourcemod/lef_karma_sounds.cfg`)

| Cvar | Default | Meaning |
|---|---|---|
| `lef_karma_sounds_enable` | `1` | On/off. |
| `lef_karma_sounds_volume` | `1.0` | Volume (0–1). |
| `lef_karma_sounds_cooldown` | `5.0` | Minimum seconds between two sounds. |

Admin commands: `sm_karmasounds_reload` (re-read the list), `sm_karmasounds_test`.

## Not tested in-game yet

Compiles. Check with real sounds: one sound per karma kill (not two), and players without the file
download it.
