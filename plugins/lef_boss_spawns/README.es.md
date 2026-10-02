[English](README.md)

# lef_boss_spawns — Lefordianos Boss Spawns (aparición de jefes)

Hace que los tanks y witches del versus sean **justos y conocidos para ambos equipos**. Left 4 Dead 2,
solo versus.

## Los problemas que arregla

- **Tanks sorpresa.** El primer equipo de supervivientes se encuentra con un tank que nadie anunció;
  el segundo equipo sabe que viene y juega con cuidado. Ahora el % se anuncia a todos cuando los
  supervivientes salen del cuarto seguro.
- **Lugares distintos para cada equipo.** El vanilla puede hacer aparecer al tank *antes* de una
  bajada (como una alcantarilla) para un equipo y *después* para el otro. Ahora el tank y la witch de
  la segunda mitad aparecen exactamente en el mismo lugar que en la primera.
- **Siempre un tank / nunca un mapa sorpresa.** Cada mapa sortea una probabilidad (por ejemplo 80% de
  tank, 60% de witch). Algunos mapas no tienen tank o witch, pero el sorteo se hace una vez por mapa,
  así que **ambos equipos tienen los mismos jefes**.

## Cómo encaja con otros plugins

| Plugin | ¿Necesario? | Qué agrega |
|---|---|---|
| `witch_and_tankifier` (+ `l4d2lib`) | Recomendado | Elige buenos %, evitando lugares malos listados para 108 mapas, y mantiene a la witch lejos del tank. Sin él se usan los % al azar del propio juego. |
| `l4d_boss_percent` | Opcional | Si está cargado, él hace los anuncios y agrega `!boss`/`!tank`/`!witch`; nosotros le avisamos qué jefe no hay ("None"). Sin él, este plugin anuncia por su cuenta. |
| confogl | No | confogl tiene el mismo bloqueo de lugar (`confogl_lock_boss_spawns`). Si está cargado con eso activado, este plugin le deja el bloqueo a confogl. |

Ninguno necesita Ready-Up.

## Comandos y configuración

`!bosses` muestra el % del tank y la witch de este mapa.

`cfg/sourcemod/lef_boss_spawns.cfg` (se crea al cargarlo por primera vez):

| Cvar | Por defecto | Significado |
|---|---|---|
| `lef_boss_tank_chance` | `100` | % de probabilidad de que un mapa tenga tank. |
| `lef_boss_witch_chance` | `100` | % de probabilidad de que un mapa tenga witch. |
| `lef_boss_skip_finales` | `1` | No tocar los mapas finales (sus tanks los maneja el final). |
| `lef_boss_lock_spawns` | `1` | Los jefes de la segunda mitad aparecen en el lugar de la primera. |
| `lef_boss_announce` | `1` | Anunciar los % cuando los supervivientes salen del cuarto seguro (solo si `l4d_boss_percent` no está cargado). |

Pongan los cvars vanilla `versus_tank_chance` / `versus_witch_chance` en `1` para que el sorteo de
este plugin sea el único; si no, las dos probabilidades se suman.

## Créditos

El bloqueo de lugar es una versión independiente del módulo BossSpawning de confogl (Confogl Team),
incluyendo sus casos especiales: los tanks del final no se mueven, el tank de c5m5 no se bloquea, y
las witches de la segunda mitad que aparecen al empezar la ronda se quitan (salvo las de la boda de
c6m1). No se incluyó: el `tank_z_fix` de confogl para tanks trabados al aparecer, que necesita los
datos de mapas de confogl.

## Todavía no probado en el juego

Compila; cosas para revisar en un servidor: que un mapa que sortea "sin tank" muestre "None"/"no hay en
este mapa" en ambas mitades, que el tank de la segunda mitad aparezca donde apareció el primero, y que
los finales no se toquen.
