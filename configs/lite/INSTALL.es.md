[English](INSTALL.md)

# Config lite: armar e instalar

La config lite es nuestra configuración del servidor **sin confogl**: correcciones de bugs, comodidad,
nuestros plugins, antitrampas y los arreglos de mapas de Stripper, manteniendo el versus vanilla. Qué
incluye se elige en [PLUGINS.md](PLUGINS.md); cómo se arma el paquete está en [manifest.txt](manifest.txt).

Funciona en servidores **Windows y Linux**: el paquete trae las dos versiones de cada extensión.

## Qué hace falta

- Un servidor dedicado de L4D2 con **Metamod:Source** y **SourceMod 1.12** instalados.
- En la computadora donde se arma el paquete (puede ser el servidor, tu PC o WSL): **Python 3.8+** y
  **git**. En Windows, instala ambos desde python.org y git-scm.com; después usa `py` en vez de
  `python3` en los comandos de abajo.

## 1. Armar el paquete

Desde la carpeta de este repo:

```bash
python3 tools/fetch_refs.py      # la primera vez: clona los repos de referencia al lado de este
python3 tools/get_sourcemod.py   # la primera vez: descarga nuestro compilador fijo de SourceMod
python3 tools/get_extensions.py  # la primera vez: descarga las extensiones que incluimos (REST in Pawn)
python3 tools/build_lite.py      # arma el paquete
```

El resultado queda en `build/lite/left4dead2/` (unos 22 MB, 179 plugins), más `build/lite/CONTENTS.txt`
con la lista de plugins. Si falta algo, o algo existe solo para una plataforma, el armado termina con
avisos.

## 2. Antes de copiar

1. **Haz una copia de seguridad** de `left4dead2/addons/` y `left4dead2/cfg/` del servidor.
2. **Borra las copias viejas** de los mismos plugins. Los nuestros van todos en
   `addons/sourcemod/plugins/lefordianos/` (salvo `left4dhooks.smx`, que reemplaza al de `plugins/`). Si el
   servidor ya tiene, por ejemplo, `plugins/l4d_afk_commands.smx`, bórralo, o el plugin se carga dos veces.
   Compara con `build/lite/CONTENTS.txt`.
3. Apaga el servidor.

## 3. Copiar

Copia el **contenido** de `build/lite/left4dead2/` sobre la carpeta `left4dead2/` del servidor, juntando
carpetas y reemplazando archivos.

Al **final** del `cfg/server.cfg` del servidor, agrega:

```
exec lefordianos/server_base.cfg
```

¿Todavía no tienes `server.cfg`, o quieres uno limpio? Copia `cfg/server.example.cfg` a `cfg/server.cfg` y
completa las líneas marcadas `CHANGE ME` (nombre, contraseña de RCON, región, grupo de Steam). Explica cada
línea y ya termina con el `exec` de arriba. Está hecho a partir del server.cfg del repo competitivo y del
de Harry Potter; las actualizaciones solo traen el ejemplo, así tu `server.cfg` nunca se sobrescribe.

## Probar solo con bots

En la consola del servidor o por RCON: `exec lefordianos/test_bots.cfg` prende `sv_cheats` y deja correr
una partida de versus con equipos de solo bots, para probar plugins solo (jugar de infectado contra bots,
darte el tank, hacer aparecer cosas). El archivo lista comandos útiles. Se deshace con
`exec lefordianos/test_off.cfg`, y nunca lo dejes prendido con randoms. Necesita
`sv_allow_lobby_connect_only 0` (el valor del server.cfg de ejemplo).

## 4. Arrancar y revisar

Arranca el servidor (las extensiones y Stripper necesitan un arranque completo, no solo un cambio de mapa)
y en la consola del servidor:

- `meta list`: aparece **Stripper**.
- `sm exts list`: aparecen **Actions**, **BuiltinVotes**, **CollisionHook**, **REST in Pawn** y **Source Scramble**, todas
  funcionando.
- `sm plugins list`: busca plugins marcados como fallidos.
  - **En Windows**, `l4d2_chainsaw_fix` falla a propósito: arregla un crasheo que solo pasa en Linux.
- Los errores quedan en `addons/sourcemod/logs/errors_<fecha>.log`.

## 5. Ajustes que quizás quieras cambiar

| Qué | Dónde |
|---|---|
| Probabilidad de tank/witch por mapa, modo T1, tank horde monitor, baneos del antitrampas, cada cuánto salen los mensajes | `cfg/lefordianos/common.cfg` |
| Ajustes para un solo modo de juego | `cfg/sourcemod/gamemode_cvars/<modo>.cfg` (cada uno empieza con `exec lefordianos/common.cfg`) |
| Mensajes del servidor | `addons/sourcemod/translations/smd_advertisements.phrases.txt` |
| Sonidos del karma kill | `addons/sourcemod/configs/lef_karma_sounds.txt` + [docs/FASTDL.es.md](../../docs/FASTDL.es.md) |
| Armas reemplazadas en el modo T1 | `addons/sourcemod/configs/lef_t1_mode.cfg` |
| Qué pueden votar los jugadores (`!votes`) y qué muestra `!menu` | `addons/sourcemod/configs/lef_votes.cfg`, `addons/sourcemod/configs/lef_menu.cfg` |
| Duración del baneo al expulsar por votación, pausa solo por votación, quién puede iniciar votaciones | `cfg/sourcemod/lef_votes.cfg` (se crea al cargar la primera vez) |
| Revisión de baneos de Steam: la clave de la API web de Steam (mantenla privada) | `cfg/sourcemod/lef_steam_bans.cfg`: `lef_bans_apikey "..."` |
| Reducción de daño a bots (15%), avisos de ritmo/infectado guardado, panel de inicio y `!wait` | `cfg/sourcemod/lef_bot_protect.cfg`, `lef_game_hints.cfg`, `lef_round_start.cfg` |
| Nombre del servidor, RCON, región, lobby/matchmaking, addons | `cfg/server.cfg` (empieza desde `cfg/server.example.cfg`) |
| Cambios de Stripper | edita `configs/lite/stripper_rules.txt` acá, corre `python3 tools/make_stripper.py` y vuelve a armar |

Cada plugin además crea su propio `cfg/sourcemod/<plugin>.cfg` la primera vez que carga; los valores de
`lefordianos/common.cfg` ganan sobre esos, porque se aplican después.

## Actualizar

```bash
git pull
python3 tools/fetch_refs.py --update
python3 tools/build_lite.py
```

Después copia de nuevo (paso 3). Los archivos de ajustes que editaste en el servidor se reemplazan, así
que guarda tus cambios en este repo (o vuelve a aplicarlos).

## No incluido (a propósito)

- `lef_comeback_bonus` y `l4d2_penalty_bonus`: desmarcados en la lista.
- l4dtoolz (más de 8 jugadores, tickrate): en espera hasta probar la versión de lakwsh.
- El `plugin_updates_checker` de Silvers (necesita una extensión HTTP que no tenemos) y `l4d_glare`
  (necesita otros dos plugins).
- El tank horde monitor **sí** está incluido, pero apagado (`l4d2_tank_horde_monitor_enable 0`).
- Se agregó el `l4d2_karma_kill` de Harry Potter (no está en la lista) porque `lef_karma_sounds` lo necesita.
