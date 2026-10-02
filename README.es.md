[English](README.md)

# Lefordianos Plugins

Plugins de SourceMod y configuraciones para nuestro servidor de versus de Left 4 Dead 2. El objetivo
es **versus vanilla con las mejoras de comodidad y correcciones de bugs** de ZoneMod y compañía, sin
los cambios de balance competitivo.

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
| [`l4d_tank_control_eq`](plugins/l4d_tank_control_eq/README.es.md) | Copia parchada de la rotación de tank del repo competitivo que ya no necesita Ready-Up. |

## Compilar

```bash
./build.sh                  # compila todo
./build.sh lef_teams_panel  # compila un solo plugin
```

El resultado queda en `build/`, ordenado como la carpeta `left4dead2/` de un servidor, así que
instalar es copiar: `build/addons/sourcemod/plugins/*.smx` y `build/addons/sourcemod/translations/`.

El script usa el compilador y los archivos include de los repos de referencia que están al lado de
este (`../L4D2-Competitive-Rework`, `../Left4DHooks`). Usa `REFS=/alguna/ruta` si están en otro lugar.

## Repos de referencia

Están al lado de este repo, solo para leer: L4D2-Competitive-Rework (SirPlease), L4D1_2-Plugins
(Harry Potter), MoYu_Server_Stupid_Plugins (Forgetest), Left4DHooks (Silvers),
Practiceogl-Rework, l4d2_mission_manager, sourcetvsupport (shqke).
