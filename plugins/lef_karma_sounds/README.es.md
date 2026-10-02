[English](README.md)

# lef_karma_sounds — Lefordianos Karma Sounds (sonidos del karma kill)

Toca uno de **nuestros propios sonidos**, elegido al azar, cuando se anuncia un karma kill (un
superviviente que muere por un charger, un golpe de tank o un jalón al vacío). Left 4 Dead 2.

Funciona con cualquiera de los dos plugins de karma kill: el `l4d2-karma-kill-system` de eyal282 o el
`l4d2_karma_kill` de Harry Potter. Ellos siguen tocando su propio sonido también (lo tienen fijo en el código).

## Agregar sonidos

1. Pon los archivos en el **servidor del juego** dentro de `left4dead2/sound/`, por ejemplo
   `left4dead2/sound/lefordianos/karma/fall1.wav` (`.wav` o `.mp3`).
2. Lístalos en `addons/sourcemod/configs/lef_karma_sounds.txt`, uno por línea, relativos a `sound/`:
   `lefordianos/karma/fall1.wav`
3. Pon las copias `.bz2` en FastDL para que los jugadores las descarguen rápido ([docs/FASTDL.es.md](../../docs/FASTDL.es.md)).
4. Cambia de mapa. `sm_karmasounds_test` toca uno para probar.

Los archivos listados que no estén en el servidor se saltean (y quedan en el log). Con la lista vacía el
plugin no hace nada, así que se puede instalar antes de tener los sonidos.

## Configuración (`cfg/sourcemod/lef_karma_sounds.cfg`)

| Cvar | Por defecto | Significado |
|---|---|---|
| `lef_karma_sounds_enable` | `1` | Activado/desactivado. |
| `lef_karma_sounds_volume` | `1.0` | Volumen (0–1). |
| `lef_karma_sounds_cooldown` | `5.0` | Segundos mínimos entre dos sonidos. |

Comandos de admin: `sm_karmasounds_reload` (vuelve a leer la lista), `sm_karmasounds_test`.

## Todavía no probado en el juego

Compila. Revisar con sonidos reales: un solo sonido por karma kill (no dos), y que los jugadores que no
tienen el archivo lo descarguen.
