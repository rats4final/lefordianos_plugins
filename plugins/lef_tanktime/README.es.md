[English](README.md)

# lef_tanktime — Lefordianos Tank!Time!

La mutación **Taaannnk!!** (`mutation19`) en versus: todos los infectados son tanks. Un port del
[Tank!Time!](https://forums.alliedmods.net/showthread.php?t=248745) 1.2.3 de Merc1less, que hace jugable
esa mutación en versus. Left 4 Dead 2.

**Solo funciona en mutation19.** En cualquier otro modo no hace nada, y sus cambios de mapas quedan
apagados.

## Cómo se juega el modo

- Hasta **4 tanks** en el equipo infectado. Aparecen juntos **15 s** después de que los supervivientes
  salen del refugio; cada tank muerto vuelve **30 s** después. Los bots tank llenan los lugares vacíos;
  un jugador que entra a los infectados toma un bot tank, o la próxima aparición.
- **Las dos mitades usan los mismos lugares de tank.** Los tanks que aparecen en lugares conocidos como
  malos (por mapa) se mueven a lugares buenos. La witch aparece en el mismo lugar en las dos mitades.
- **Finales**: el juego deja un solo bot tank, así que los tanks humanos se reparten la vida de 4 tanks.
- Supervivientes: **`!slayme`** estando caído (ahorra tiempo al equipo); arrastrarse al refugio está
  activado.
- Un **panel** muestra el tank al que apuntas (supervivientes: su nombre; infectados: su vida).
- `!ttcfg` muestra las opciones en uso.

## Ajustes (`cfg/sourcemod/lef_tanktime.cfg`)

| Cvar | Por defecto | Qué |
|---|---|---|
| `lef_tanktime_options` | `55` | Sumar: 1 bots tank, 2 arrastrarse, 4 panel, 8 vida del tank al derribarte, 16 tank y witch en cada mapa, 32 sin tank "normal" del director, 64 modo escopetas, 128 el modo escopetas deja las armas tier 1. Se lee al empezar el modo. |
| `lef_tanktime_spawn_time` | `15` | Segundos después de salir del refugio hasta que aparecen los tanks |
| `lef_tanktime_respawn_time` | `30` | Segundos hasta que un tank muerto vuelve a aparecer |
| `lef_tanktime_tank_health` | `0` | Vida del tank (0 = la del juego) |
| `lef_tanktime_bigguns_limit` | `2` | Modo escopetas: armas grandes por ronda |
| `lef_tanktime_regular_tank_color` | `255 0 0 255` | Color del tank "normal" del director |
| `lef_tanktime_restart_command` | (vacío) | Se ejecuta si una ronda empieza durante la intro (vacío = reiniciar el mapa) |

Datos por mapa (nombres de los bots tank, zonas de aparición malas, límites en finales):
`addons/sourcemod/configs/lef_tanktime.cfg`.

## Qué trae

- **Cambios de mapas** (`stripper/maps/`, 22 mapas): entidades que solo se activan cuando este plugin
  dispara el relay `relay_tt_mutation19`, o sea en mutation19 (puertas y eventos de final más rápidos,
  el ascensor en c1m1/c4m2/c8m4...). `tools/make_stripper.py` los agrega a nuestros archivos de Stripper.
- **VScripts de finales** (`vscripts/`, 6 scripts, se instalan en `scripts/vscripts/`): **los scripts
  actuales de Valve** más los cambios de Tank!Time! dentro de `if mutation19` (6 bidones en c1m4/c6m3,
  sin tank del director en c9m2, jefes permitidos desde el inicio en c7m3). Las copias de Tank!Time!
  estaban hechas sobre scripts viejos de Valve y habrían deshecho arreglos posteriores (ej.
  `GetGameModeBase()`, la música del final de c9m2) en todos los modos; los nuestros son idénticos a
  los del juego fuera de mutation19.
- **lef_mode_plugins** apaga los plugins de versus que pelearían con este (rotación de tank, orden de
  spawns, probabilidad de jefes, avisos de tank); ver su README.

## Qué cambió respecto del original

- **Left4DHooks** (`L4D_ReplaceTank`, `L4D_TakeOverZombieBot`) en vez de sus propias firmas de gamedata,
  que se rompen cuando se actualiza el juego. Sintaxis nueva, colors.inc, traducciones en/es, cvars
  `lef_tanktime_*`, datos de mapas en `configs/lef_tanktime.cfg`.
- **Errores arreglados:** mientras el modo estaba activo se tragaba todo mensaje del chat que empezara
  con `!` (también los comandos de otros plugins), ahora `!slayme`/`!ttcfg` son comandos normales; el
  temporizador del panel se duplicaba cada ronda; "FixedFirstSpawnPos" se leía y se descartaba; el modo
  escopetas no reemplazaba la SG552; daba un error (fuera de rango) si todos los lugares de reaparición estaban ocupados.
- **Arreglos de mapas:** en c11m3 su archivo de Stripper conectaba la barricada de combustible a un
  relay que no existía (`relay_event_default` en vez de `relay_minifinale_default`), así que en **todos**
  los modos el fuego no se habría apagado nunca al romperla. En c5m2 una salida nombraba mal un relay
  (solo importaba en mutation19).
- El relay se dispara al empezar la ronda (la versión del original que compiló el dueño lo hacía así en
  vez de esperar 1 segundo); los ajustes del director se vuelven a aplicar después de las configs de
  cada mapa.

## Necesita

Left4DHooks, colors.inc, Stripper:Source (para los cambios de mapas). Todavía sin probar con jugadores
(2026-11-08).

Plugin original, cambios de mapas y VScripts: **Merc1less** (Tank!Time!, AlliedModders). Frases en
español en parte de la traducción de Torpedo.
