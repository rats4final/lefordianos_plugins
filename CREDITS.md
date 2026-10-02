[Español](CREDITS.es.md)

# Credits and sources

This repo stands on other people's work. This page lists where everything comes from.

## Reference repos

These live next to this repo (not inside it). `tools/fetch_refs.py` clones them all at the commits
pinned in [`tools/refs.txt`](tools/refs.txt), so the setup can be rebuilt with one command.

| Repo | Main author(s) | What we use it for |
|---|---|---|
| [L4D2-Competitive-Rework](https://github.com/SirPlease/L4D2-Competitive-Rework) | Sir (SirPlease), with the Confogl Team, A1m`, Forgetest, Visor, Jahze, ProdigySim and the many contributors in its README | Most of the bug fixes and QoL plugins, ZoneMod stripper configs, extensions (sourcescramble, collisionhook, actions, builtinvotes) |
| [L4D1_2-Plugins](https://github.com/fbef0102/L4D1_2-Plugins) | Harry Potter (fbef0102) | `l4d_afk_commands`, `gamemode-based_configs`, mission manager/ACS, many fixes |
| [Game-Private_Plugin](https://github.com/fbef0102/Game-Private_Plugin) | Harry Potter (fbef0102) | Server tutorials (Stripper, l4dtoolz, tickrate) |
| [MoYu_Server_Stupid_Plugins](https://github.com/Target5150/MoYu_Server_Stupid_Plugins) | Forgetest (Target5150) and contributors | Fixes; ideas for `lef_score_info` |
| [Left4DHooks](https://github.com/SilvDev/Left4DHooks) | Silvers (SilverShot) | The library almost every plugin uses |
| [Various_Scripts_Collection](https://github.com/SilvDev/Various_Scripts_Collection) | Silvers | Exploit fixes, `l4d_heartbeat`, plugin updates checker, visual extras |
| [Vote_Mode](https://github.com/SilvDev/Vote_Mode), [Console_Spam_Patches](https://github.com/SilvDev/Console_Spam_Patches), [Dissolve_Infected](https://github.com/SilvDev/Dissolve_Infected), [Dynamic_Light](https://github.com/SilvDev/Dynamic_Light) | Silvers | Game mode votes, console fixes, visuals |
| [Left-4-fix](https://github.com/LuxLuma/Left-4-fix), [Enhanced Throwables](https://github.com/LuxLuma/-L4D-L4D2-Enhanced-Throwables) | Lux (LuxLuma) | Defib and witch fixes, exploit fixes |
| [l4d2_mission_manager](https://github.com/rikka0w0/l4d2_mission_manager) | rikka0w0 | Map list API and automatic campaign switcher |
| [l4d2-karma-kill-system](https://github.com/eyal282/l4d2-karma-kill-system) | eyal282 (myGaming) | Karma kill announcements |
| [l4dtoolz](https://github.com/lakwsh/l4dtoolz) | lakwsh (based on the original L4DToolZ) | More than 8 players, tickrate unlock, Steam logon workaround |
| [sm-plugin-SMAC](https://github.com/srcdslab/sm-plugin-SMAC) | srcdslab, fork of SMAC by GoD-Tony, Silenci0 and contributors | Anti-cheat |
| [sm-plugin-lilac](https://github.com/srcdslab/sm-plugin-lilac) | srcdslab, fork of Little Anti-Cheat by J-Tanzanite | Anti-cheat |
| [Sourcemod-Plugins](https://github.com/fbef0102/Sourcemod-Plugins) | Harry Potter (fbef0102) | `cannounce` (connect messages), `smd_advertisements` (server messages) |
| [Multi-Colors](https://github.com/Bara/Multi-Colors) | Bara | `multicolors` include, needed to compile SMAC |
| [sourcetvsupport](https://github.com/shqke/sourcetvsupport) | shqke | SourceTV / demo recording fixes (planned) |
| [Practiceogl-Rework](https://github.com/AoC-Gamers/Practiceogl-Rework) | AoC-Gamers | Example of a match mode built on ZoneMod |
| [AoC-Gamers](https://github.com/orgs/AoC-Gamers/repositories): CallVote-Manager, L4D2-Family-Share, L4D2-Player-Skills, L4D2-Player-Stats, L4D2-CommSuite, T1-ZM, SuperVanilla, L4D2-Competitive-Rework-Fix and others | AoC-Gamers | Reference for vote tracking, stats, Family Sharing and casual ZoneMod variants (see IDEAS) |
| [sm-ripext](https://github.com/ErikMinekus/sm-ripext) | Erik Minekus | REST in Pawn extension (HTTP + JSON), used by `lef_steam_bans` |

## AlliedModders plugins

Kept unchanged in [`alliedmodders/`](alliedmodders/), one folder per author.

| Author | Plugin | Version | Forum thread |
|---|---|---|---|
| -=BwA=- Jester | Players Panel and Switch Menu (`l4d2_bwa_teamspanel`) | 1.2.2 | AlliedModders forums |
| Mart | Throwable Announcer (`l4d_throwable_announcer`) | 1.0.8 | [t=327613](https://forums.alliedmods.net/showthread.php?t=327613) |
| Mart | Explosion Announcer (`l4d_explosion_announcer`) | 1.0.8 | [t=328006](https://forums.alliedmods.net/showthread.php?t=328006) |
| Mart | Upgrade Ammo Pack Deploy Announce (`l4d2_pack_deploy_announce`) | 1.0.0 | [t=341472](https://forums.alliedmods.net/showthread.php?t=341472) |
| Mart | Scripted HUD (`l4d2_scripted_hud`) | 1.0.2 | [t=331212](https://forums.alliedmods.net/showthread.php?t=331212) |
| NoroHime | Announce Health (`l4d_announce_healer`) | 1.2.1 | [Steam profile](https://steamcommunity.com/id/NoroHime/) |
| SilverShot (Silvers) | Fire Glow (`l4d_fire_glow`) | 1.8 | [t=186617](https://forums.alliedmods.net/showthread.php?t=186617) |
| SilverShot (Silvers) | Bots Ignore PipeBombs and Shoot (`l4d_pipebomb_ignore`) | 2.0 | [t=333464](https://forums.alliedmods.net/showthread.php?t=333464) |
| pan0s | L4D2 Menu (`l4d2_menu`) | 1.2 | [t=332614](https://forums.alliedmods.net/showthread.php?t=332614) |
| pan0s | Statistic And Ranking System (`l4d2_srs`) | 2.5 | AlliedModders forums; bundles HexTags (Hexah), Chat-Processor (Drixevel) and GeoResolver (Hattrick HKS) |

## Code we adapted

| Our plugin | Based on |
|---|---|
| `lef_teams_panel` | Players Panel and Switch Menu by -=BwA=- Jester, which built on TeamSWITCH (SkyDavid), l4d_teamspanel (OtterNas3) and SpecStaysSpec (DieTeetasse) |
| `lef_boss_spawns` | Spawn locking ported from confogl's BossSpawning module (Confogl Team) |
| `lef_score_info` | Idea from `l4d2_score_difference` by Forgetest and vikingo12 |
| `lef_comeback_bonus` | Uses `l4d2_penalty_bonus` (Tabun, A1m`; competitive repo) |
| `lef_admin_restore` | Improves `admin_hp` by Harry Potter |
| `lef_client_cvars` | Port of confogl's ClientSettings module (Confogl Team); cvar list from the competitive repo's `cvar_tracking.cfg` |
| `lef_votes` | Ideas from Harry Potter's `l4d_votes_5` (archived) and `l4d2_vote_change`; mission manager include by Harry Potter, based on rikka0w0's |
| `lef_round_start` | Saferoom hold method (`warp_to_start_area`) from Ready-Up (competitive repo) |
| `lef_game_hints` | Distance-as-share-of-the-map idea from Harry Potter's `no-rushing` |
| `lef_steam_bans` | Idea from StevoTVR's VAC Status Checker ([t=80942](https://forums.alliedmods.net/showthread.php?t=80942)), forked by Harry Potter as `vacbans` |
| `lef_t1_mode` | Weapon conversion stocks from l4d2util, as used by `l4d2_weaponrules` (ProdigySim); CS weapon precache idea from `l4d2_sniper_precache` (Visor, A1m`) |
| `l4d_tank_control_eq` | L4D2 Tank Control by arti, with Sheo, Sir and Altair-Sossai (one line changed) |

If something is missing or a credit is wrong, please tell us and we'll fix it.
