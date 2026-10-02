[English](CREDITS.md)

# Créditos y fuentes

Este repo se apoya en el trabajo de otras personas. Esta página lista de dónde viene todo.

## Repos de referencia

Están al lado de este repo (no adentro). `tools/fetch-refs.sh` los clona todos en los commits fijados
en [`tools/refs.txt`](tools/refs.txt), así todo se puede rearmar con un solo comando.

| Repo | Autor(es) principal(es) | Para qué lo usamos |
|---|---|---|
| [L4D2-Competitive-Rework](https://github.com/SirPlease/L4D2-Competitive-Rework) | Sir (SirPlease), con el Confogl Team, A1m`, Forgetest, Visor, Jahze, ProdigySim y los muchos colaboradores de su README | La mayoría de las correcciones y plugins de comodidad, configs de stripper de ZoneMod, extensiones (sourcescramble, collisionhook, actions, builtinvotes) |
| [L4D1_2-Plugins](https://github.com/fbef0102/L4D1_2-Plugins) | Harry Potter (fbef0102) | `l4d_afk_commands`, `gamemode-based_configs`, mission manager/ACS, muchas correcciones |
| [Game-Private_Plugin](https://github.com/fbef0102/Game-Private_Plugin) | Harry Potter (fbef0102) | Tutoriales de servidor (Stripper, l4dtoolz, tickrate) |
| [MoYu_Server_Stupid_Plugins](https://github.com/Target5150/MoYu_Server_Stupid_Plugins) | Forgetest (Target5150) y colaboradores | Correcciones; ideas para `lef_score_info` |
| [Left4DHooks](https://github.com/SilvDev/Left4DHooks) | Silvers (SilverShot) | La librería que usa casi todo plugin |
| [Various_Scripts_Collection](https://github.com/SilvDev/Various_Scripts_Collection) | Silvers | Correcciones de exploits, `l4d_heartbeat`, verificador de actualizaciones, extras visuales |
| [Vote_Mode](https://github.com/SilvDev/Vote_Mode), [Console_Spam_Patches](https://github.com/SilvDev/Console_Spam_Patches), [Dissolve_Infected](https://github.com/SilvDev/Dissolve_Infected), [Dynamic_Light](https://github.com/SilvDev/Dynamic_Light) | Silvers | Votación de modo de juego, consola, visuales |
| [Left-4-fix](https://github.com/LuxLuma/Left-4-fix), [Enhanced Throwables](https://github.com/LuxLuma/-L4D-L4D2-Enhanced-Throwables) | Lux (LuxLuma) | Correcciones del desfibrilador y la witch, exploits |
| [l4d2_mission_manager](https://github.com/rikka0w0/l4d2_mission_manager) | rikka0w0 | API de la lista de mapas y cambio automático de campaña |
| [l4d2-karma-kill-system](https://github.com/eyal282/l4d2-karma-kill-system) | eyal282 (myGaming) | Anuncios de karma kill |
| [l4dtoolz](https://github.com/lakwsh/l4dtoolz) | lakwsh (basado en el L4DToolZ original) | Más de 8 jugadores, desbloqueo de tickrate, arreglo del error de logon de Steam |
| [sm-plugin-SMAC](https://github.com/srcdslab/sm-plugin-SMAC) | srcdslab, fork de SMAC de GoD-Tony, Silenci0 y colaboradores | Antitrampas |
| [sourcetvsupport](https://github.com/shqke/sourcetvsupport) | shqke | Arreglos de SourceTV / grabación de demos (planeado) |
| [Practiceogl-Rework](https://github.com/AoC-Gamers/Practiceogl-Rework) | AoC-Gamers | Ejemplo de un modo de partida hecho sobre ZoneMod |

## Plugins de AlliedModders

Guardados sin cambios en [`alliedmodders/`](alliedmodders/), una carpeta por autor.

| Autor | Plugin | Versión | Hilo del foro |
|---|---|---|---|
| -=BwA=- Jester | Players Panel and Switch Menu (`l4d2_bwa_teamspanel`) | 1.2.2 | Foros de AlliedModders |
| Mart | Throwable Announcer (`l4d_throwable_announcer`) | 1.0.8 | [t=327613](https://forums.alliedmods.net/showthread.php?t=327613) |
| Mart | Explosion Announcer (`l4d_explosion_announcer`) | 1.0.8 | [t=328006](https://forums.alliedmods.net/showthread.php?t=328006) |
| Mart | Upgrade Ammo Pack Deploy Announce (`l4d2_pack_deploy_announce`) | 1.0.0 | [t=341472](https://forums.alliedmods.net/showthread.php?t=341472) |
| Mart | Scripted HUD (`l4d2_scripted_hud`) | 1.0.2 | [t=331212](https://forums.alliedmods.net/showthread.php?t=331212) |
| NoroHime | Announce Health (`l4d_announce_healer`) | 1.2.1 | [Perfil de Steam](https://steamcommunity.com/id/NoroHime/) |
| SilverShot (Silvers) | Fire Glow (`l4d_fire_glow`) | 1.8 | [t=186617](https://forums.alliedmods.net/showthread.php?t=186617) |
| SilverShot (Silvers) | Bots Ignore PipeBombs and Shoot (`l4d_pipebomb_ignore`) | 2.0 | [t=333464](https://forums.alliedmods.net/showthread.php?t=333464) |
| pan0s | L4D2 Menu (`l4d2_menu`) | 1.2 | [t=332614](https://forums.alliedmods.net/showthread.php?t=332614) |
| pan0s | Statistic And Ranking System (`l4d2_srs`) | 2.5 | Foros de AlliedModders; incluye HexTags (Hexah), Chat-Processor (Drixevel) y GeoResolver (Hattrick HKS) |

## Código que adaptamos

| Nuestro plugin | Basado en |
|---|---|
| `lef_teams_panel` | Players Panel and Switch Menu de -=BwA=- Jester, que a su vez se basó en TeamSWITCH (SkyDavid), l4d_teamspanel (OtterNas3) y SpecStaysSpec (DieTeetasse) |
| `lef_boss_spawns` | Bloqueo de lugar de aparición adaptado del módulo BossSpawning de confogl (Confogl Team) |
| `lef_score_info` | Idea de `l4d2_score_difference` de Forgetest y vikingo12 |
| `lef_comeback_bonus` | Usa `l4d2_penalty_bonus` (Tabun, A1m`; repo competitivo) |
| `lef_admin_restore` | Mejora el `admin_hp` de Harry Potter |
| `l4d_tank_control_eq` | L4D2 Tank Control de arti, con Sheo, Sir y Altair-Sossai (una línea cambiada) |

Si falta algo o un crédito está mal, avísennos y lo corregimos.
