[English](README.md)

# Lefordianos Plugins

Plugins de SourceMod y configuraciones para nuestro servidor de versus de Left 4 Dead 2. El objetivo
es **versus vanilla con las mejoras de comodidad y correcciones de bugs** de ZoneMod y compañía, sin
los cambios de balance competitivo.

Qué les da a jugadores y admins: [docs/BENEFITS.es.md](docs/BENEFITS.es.md). Qué se hizo y cuándo:
[CHANGELOG.es.md](CHANGELOG.es.md). Contexto para asistentes de IA: [AGENTS.md](AGENTS.md) (en inglés).

## Estructura

| Carpeta | Qué contiene |
|---|---|
| [`plugins/`](plugins/) | Nuestros plugins: nuevos, y reescrituras/mejoras de otros más viejos. Una carpeta por plugin con `scripting/`, `translations/` y un README. |
| [`alliedmodders/`](alliedmodders/) | Código original de otros autores, sin cambios, como referencia. Una carpeta por autor. |
| [`configs/`](configs/) | Configuraciones del servidor: una lite sin confogl (lista de plugins para elegir en [`configs/lite/PLUGINS.md`](configs/lite/PLUGINS.md)), y más adelante un modo de partida con confogl. |
| [`IDEAS.es.md`](IDEAS.es.md) | Ideas y lo que está en progreso. |

Cada documento tiene su versión en español al lado (`*.es.md`); el selector de plugins es un solo archivo en ambos idiomas.

## Plugins

| Plugin | Qué hace |
|---|---|
| [`lef_teams_panel`](plugins/lef_teams_panel/README.es.md) | Panel `!teams`, pedidos de cambio `!swapwith` y un menú de admin "Gestión de equipos". |
| [`lef_boss_spawns`](plugins/lef_boss_spawns/README.es.md) | Probabilidad de tank/witch por mapa, mismo lugar de aparición para ambos equipos, % anunciado. |
| [`lef_score_info`](plugins/lef_score_info/README.es.md) | Explica los puntajes de versus: cuánto vale el mapa, la diferencia, qué hace falta para remontar, mapas ganados. No cambia puntos. |
| [`lef_comeback_bonus`](plugins/lef_comeback_bonus/README.es.md) | El equipo que va perdiendo gana un bono limitado sobre la distancia que recorre. |
| [`lef_admin_restore`](plugins/lef_admin_restore/README.es.md) | `!heal`, y `!restore` para deshacer lo que los compañeros le hicieron a un superviviente (vida, derribos, muertes, objetos). |
| [`lef_saferoom_doors`](plugins/lef_saferoom_doors/README.es.md) | Anuncia quién abrió la puerta del refugio inicial y quién cerró la final con compañeros afuera. |
| [`lef_t1_mode`](plugins/lef_t1_mode/README.es.md) | Modo solo armas T1 que se prende y apaga (cvar, admin o votación `!t1`), configurable. |
| [`lef_client_cvars`](plugins/lef_client_cvars/README.es.md) | Expulsa a quien tenga cvars de cliente que dan ventaja (brillo total, sin niebla...); la lista de ZoneMod, sin confogl. |
| [`lef_votes`](plugins/lef_votes/README.es.md) | `!votes` en la pantalla de votación del juego, desde un archivo de config: mapas, equipos, expulsar (con un baneo corto, como en vanilla), AFK, silenciar, reglas, pausa solo por votación. Más una categoría *Lefordianos* en `!admin`. |
| [`lef_menu`](plugins/lef_menu/README.es.md) | `!menu`: todos los comandos para jugadores del servidor en un menú; oculta lo que no está instalado. |
| [`lef_round_start`](plugins/lef_round_start/README.es.md) | Panel de inicio (dónde sale tank/witch, equipos) y `!wait`: una votación mantiene cerrado el refugio hasta que entre un amigo. Sin Ready-Up. |
| [`lef_game_hints`](plugins/lef_game_hints/README.es.md) | Solo avisos: rushear, quedarse atrás, guardar un infectado mucho tiempo; consejos para el tank. |
| [`lef_bot_protect`](plugins/lef_bot_protect/README.es.md) | Los bots sobrevivientes reciben 15% menos daño de los jugadores infectados, para que no sean muertes gratis. |
| [`lef_steam_bans`](plugins/lef_steam_bans/README.es.md) | Avisa a los admins cuando alguien que entra tiene baneos VAC, de juego o de la comunidad (solo baneos, nada más). Necesita REST in Pawn y una clave de la API de Steam. |
| [`lef_karma_sounds`](plugins/lef_karma_sounds/README.es.md) | Nuestro propio sonido al azar en los karma kills (necesita FastDL, ver [docs/FASTDL.es.md](docs/FASTDL.es.md)). |
| [`l4d2_tank_horde_monitor`](plugins/l4d2_tank_horde_monitor/README.es.md) | Copia parchada del tank horde monitor del repo competitivo, con interruptor y recordatorio de la regla. |
| [`l4d_tank_control_eq`](plugins/l4d_tank_control_eq/README.es.md) | Copia parchada de la rotación de tank del repo competitivo que ya no necesita Ready-Up. |

## Compilar

Todas las herramientas son de Python 3 y funcionan en Windows y Linux (en Windows usa `py` en vez de `python3`).

```bash
python3 tools/fetch_refs.py       # una vez: clona los repos de referencia al lado de este (commits fijados)
python3 tools/get_sourcemod.py    # una vez: descarga nuestro compilador fijo de SourceMod 1.12 en tools/sourcemod/
python3 tools/get_extensions.py   # una vez: descarga las extensiones que incluimos (REST in Pawn) en tools/extensions/
python3 tools/build.py            # compila nuestros plugins en build/   (./build.sh es un atajo)
python3 tools/build.py lef_t1_mode
python3 tools/build_lite.py       # arma el paquete completo de la config lite en build/lite/
python3 tools/make_stripper.py    # regenera los archivos de Stripper lite desde los de ZoneMod
```

La versión del compilador está fijada en `tools/SOURCEMOD_VERSION` (`python3 tools/get_sourcemod.py latest`
la actualiza). Los archivos include de terceros (Left4DHooks, colors, builtinvotes, multicolors...) vienen de
los repos de referencia que están al lado de este. Usa `REFS=/alguna/ruta` si están en otro lugar.

**Config lite:** ver [configs/lite/INSTALL.es.md](configs/lite/INSTALL.es.md) para armarla e instalarla en un servidor.

## Repos de referencia y créditos

Ver [CREDITS.es.md](CREDITS.es.md) para cada fuente, sus autores y enlaces.

Están al lado de este repo, solo para leer: L4D2-Competitive-Rework (SirPlease), L4D1_2-Plugins
(Harry Potter), MoYu_Server_Stupid_Plugins (Forgetest), Left4DHooks (Silvers),
Practiceogl-Rework, l4d2_mission_manager, sourcetvsupport (shqke).
