[Español](README.es.md)

# Other authors' plugins

Original source of plugins by other AlliedModders authors, kept **unchanged** for reference.
One folder per author, one folder per plugin inside it.

When we rewrite or improve one of these, the new version goes in [`plugins/`](../plugins/) and
the original stays here, so we can always compare against it.

| Author | Plugin | Source | Our version |
|---|---|---|---|
| -=BwA=- Jester | `l4d2_bwa_teamspanel` (Players Panel and Switch Menu 1.2.2) | AlliedModders forums | [`lef_teams_panel`](../plugins/lef_teams_panel/) |
| Mart | Throwable / Explosion announcers, Upgrade pack announce, Scripted HUD | AlliedModders | — |
| NoroHime | `l4d_announce_healer` | AlliedModders | — |
| SilverShot | `l4d_fire_glow`, `l4d_pipebomb_ignore` | AlliedModders | — |
| Buster "Mr. Zero" Nielsen; fork by cravenge and Dragokas | `sceneprocessor` 1.33.3 (needed by Harry's `l4d2_survivor_mourn_fix`; copy from Harry Potter's Rotoblin-AZMod repo) | [AlliedModders t=241585](https://forums.alliedmods.net/showthread.php?t=241585) | — |
| pan0s | `l4d2_menu`, `l4d2_srs` (zip contents, without compiled binaries) | AlliedModders | — |

Versions and forum links for each one are in [CREDITS.md](../CREDITS.md). Compiled files (`.smx`, `.so`, `.dll`) are not kept.

To add one: create `alliedmodders/<Author>/<plugin>/`, drop the `.sp` (plus any gamedata or
translation files) in it, and add a row above with the forum link.
