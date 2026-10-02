[English](IDEAS.md)

# Ideas

Una lista que va creciendo. Agreguen lo que quieran y pasen las cosas a "Hecho" cuando estén listas.

**La regla general:** mantener la sensación vanilla. Las correcciones de bugs y las mejoras de
comodidad son bienvenidas; cualquier cosa que cambie el balance del juego debe ser opcional y estar
desactivada por defecto.

## En progreso

- **Config lite (sin confogl)**: **paquete armado** (`python3 tools/build_lite.py`, ver
  [configs/lite/INSTALL.es.md](configs/lite/INSTALL.es.md)); falta probarlo en el servidor. Un servidor con SourceMod simple: las correcciones de bugs del repo
  competitivo (`generalfixes.cfg`), el panel de equipos y los plugins de comodidad que nos gustan.
  La configuración por modo de juego viene del `gamemode-based_configs` de Harry Potter
  (`cfg/sourcemod/gamemode_cvars/<modo>.cfg`, se ejecuta al cargar el mapa y al cambiar de modo);
  cada archivo de modo debería configurar los mismos cvars, porque nunca deshace lo que puso el modo
  anterior. Con el `Vote_Mode` de Silvers, los jugadores pueden cambiar de modo y tener la
  configuración correcta.
- **Lefordianos Vanilla+ (modo de partida con confogl)**: un modo `cfgogl/lefordianos/` para
  `!match`: las correcciones más la comodidad, sin ninguno de los cambios de balance competitivo.
  Prioridad más baja.
- Lista de plugins para la config lite: [`configs/lite/PLUGINS.md`](configs/lite/PLUGINS.md).
- **Usar la pantalla de votación del propio juego (builtinvotes) en nuestros plugins.** La extensión
  `builtinvotes` (viene con el repo competitivo) muestra el mismo panel F1/F2 que las votaciones de
  L4D2. Lo que puede y no puede hacer en L4D2:
  - **Solo Sí/No.** Las votaciones de opción múltiple son solo de TF2, así que "elige una de 3"
    sigue necesitando un menú.
  - Se puede mostrar a todos o **a un solo equipo** (`SetBuiltinVoteTeam`), por ejemplo una votación
    solo para infectados.
  - Solo **una votación a la vez** en todo el servidor, con la espera del juego entre votaciones.
  - Ya la usan `match_vote`, `l4d2_setscores`, `slots_vote`, `l4d_boss_vote`, `caster_system`.

  Primeros usos:
  - Panel de equipos: `!voteshuffle`, `!voteflip`, `!voterestore`, para que los jugadores arreglen
    los equipos sin un admin (los admins mantienen los botones instantáneos del menú).
  - Un include compartido pequeño (`lef_votes.inc`) para que cualquiera de nuestros plugins pueda
    iniciar una votación Sí/No con una sola llamada y recibir "aprobada/rechazada", sin repetir la
    preparación cada vez.
  - No para los pedidos de cambio: una votación de 1 persona bloquearía todas las demás votaciones del
    servidor mientras está abierta, así que `!swapwith` mantiene su menú privado.
- **Aviso de "viene el tank"** (complemento de `lef_boss_spawns`): un aviso en el chat/sonido cuando
  los supervivientes están a pocos % del lugar del tank.
- **Puntaje de remontada para versus vanilla**: elegimos las opciones A y C (ver abajo), hechas como
  `lef_score_info` y `lef_comeback_bonus`. Falta probarlas en el servidor.

## Decisiones y planes (2026-10-02)

### Stripper para la config lite
- Usar los archivos de stripper de ZoneMod (`cfg/stripper/zonemod/maps/`) **sin los retrabajos
  especiales** de 13 mapas oficiales: c1m1 aguante del ascensor, c1m3 ruta del evento / ruta del
  refugio, c2m2 y c2m3 y c2m4 refugios rehechos / zona de scavenge / cuarto del carrusel / ruta de los
  autitos chocones, c3m1 bajada de un solo sentido en el pueblo, c4m4 ruta del parque, c5m5 barandas
  del puente, c6m1 departamentos vacíos, c7m2 bajada de un solo sentido en el refugio, c8m1 calle
  bloqueada, c10m1 árboles, c12m4 toldo del galpón. Todo lo demás de esos mapas se queda (arreglos de
  exploits, fuera del mapa, lugares donde uno se traba...).
- **Mantener las witches y los tanks programados** como en vanilla:
  - no usar la parte de `global_filters.cfg` de ZoneMod que quita witches (sí su parte que quita
    ragdolls y la que corrige tipos de entidad);
  - también quitar estos bloques de eventos: c1m4 "tank a los 29 segundos" (ZoneMod agrega un tank
    cuando el ascensor llega abajo en el centro comercial; vanilla no tiene tank antes del final) y
    c4m2 / c4m3 "arreglar varias witches no deseadas". Los arreglos como el del generador de c9m2 y el
    filtro del tank de c10m3 se quedan.
  - **c7m1 se queda** (decidido el 2026-10-02): la puerta del vagón se abre sola 20 s después de que
    aparece el tank, y se quitan los sonidos falsos de tank. Buena comodidad; si no, los supervivientes
    queman al tank dentro del vagón.
  - Los tanks programados de los mapas (por ejemplo el del vagón de c7m1, o los finales) nunca los
    quitan nuestros plugins; la lista `static_tank_map` solo evita que `witch_and_tankifier` agregue un
    *segundo* tank por % ahí.
- **Hecho:** `tools/make_stripper.py` + `configs/lite/stripper_rules.txt` generan
  `configs/lite/left4dead2/cfg/stripper/lefordianos/`. Volver a correrlo cuando ZoneMod actualice.
- **Filtros globales** (`global_filters.cfg`, se aplica a todos los mapas) tiene 17 secciones. Quitadas:
  WITCH REMOVAL, T2 WEAPON SPAWN FIX (convierte todas las T2 en T1 en todos lados), COMPETITIVE ITEM
  SPAWNS (quita ametralladoras fijas, bidones, propano, oxígeno). Se quedan: quitar ragdolls, arreglos de
  entidades/densidad de objetos/objetos golpeables/puertas/colisiones, limpieza de basura física, mesas
  fijas, limpieza de sonidos y efectos visuales. **Falta decidir:** PILL CABINET MAX (los botiquines de
  pared dan como mucho 2 pastillas), ITEM PICKUP FIX (los puntos de cuerpo a cuerpo/objetos dan una sola
  recogida), INFECTED CLIP / TRIGGER FIX (quita las paredes invisibles que impiden a los infectados
  llegar a algunos lugares).

### Tickrate (en pausa, no por ahora)
Todo lo que averiguamos, para no tener que investigarlo de nuevo:
- **Es de todo el servidor.** Se pone con la opción de arranque `-tickrate 60` / `100` (con el l4dtoolz
  de lakwsh; con el de Accelerator74 hace falta además `tickrate_enabler`). La versión de lakwsh también
  tiene `sv_tickrate N`, que se aplica después del próximo cambio de mapa. No puede ser distinto entre la
  config lite y un modo de confogl sin cambiar de mapa.
- **Rates a configurar** (`server.cfg`, varios necesitan `sm_cvar`): `sv_minrate`/`sv_maxrate`/`net_splitpacket_maxrate`
  = tickrate × 1000; `sv_minupdaterate`/`sv_maxupdaterate`/`sv_mincmdrate`/`sv_maxcmdrate` = tickrate;
  `sv_client_min_interp_ratio 0`/`sv_client_max_interp_ratio 0`; `fps_max 0`; `nb_update_frequency`
  (cada cuánto "piensan" los comunes y las witches: más bajo = más suave pero más CPU). El `server.cfg`
  del repo competitivo trae un bloque listo para 100 tick. El l4dtoolz de lakwsh sube `sv_minrate` y
  `sv_minupdaterate` solo cuando cambia el tickrate.
- **Cosas que se rompen arriba de 30 tick, y sus arreglos:**
  - el alcance del vómito del boomer se acorta en versus → [`lakwsh/l4d2_vomit_fix`](https://github.com/lakwsh/l4d2_vomit_fix)
    (todavía no está en nuestra carpeta);
  - las pistolas dobles disparan mucho más rápido → `l4d2_pistol_delay`;
  - velocidad de las puertas, daño por caída y otros tiempos que dependen del tick → `TickrateFixes`
    (más `tick_door_speed 1.3`).
- **Rarezas:** el `net_graph` del jugador muestra como mucho 100 aunque el servidor vaya a 128 (es solo
  visual); el cmdrate real de un jugador no puede pasar sus FPS; si los FPS del servidor (`sv` en el
  net_graph) caen por debajo del tickrate durante tank + horda, todos reciben menos actualizaciones. La
  guía del repo competitivo sugiere una CPU de ~3 GHz para 100 tick. La CPU y la subida de internet
  crecen más o menos con el tickrate (100 tick ≈ 3× 30 tick).

### l4dtoolz: Accelerator74 vs lakwsh
Los dos son forks del original de ivailosp. El repo competitivo trae el de Accelerator74.

| | Accelerator74 (repo competitivo) | lakwsh (el que recomienda Harry para L4D2) |
|---|---|---|
| Máximo de clientes (jugadores + bots) | Opción de arranque `-maxplayers N`, si no **31**. Fijo mientras corre el servidor. | `sv_setmax N` (18–32, por defecto 18). Usar `+sv_setmax 31` al arrancar; se puede cambiar en marcha (con el servidor vacío). |
| Límite de jugadores humanos | `sv_maxplayers` (-1 = lo del juego, 0–32) | `sv_maxplayers` (-1 = lo del juego, hasta 31) |
| Reserva de lobby | `sv_force_unreserved` | `sv_force_unreserved`, más `sv_cookie` para ver/poner la cookie del lobby (0 quita el lobby) |
| Tickrate | No (necesita `tickrate_enabler`) | Sí: `-tickrate N` / `sv_tickrate N` |
| Arreglo de "No Steam logon" | No | `sv_steam_bypass 1`, pero entonces los SteamID **no se verifican**: los admins por SteamID y nuestro roster no son confiables, los baneos de cuentas familiares dejan de funcionar, SteamWorks se rompe, y la info del buscador de servidores necesita `l4d2_a2s_fix`. Prenderlo solo mientras dure el error. |
| Bloquear cuentas de Family Sharing | No | `sv_anti_sharing 1` |
| Cómo encuentra el código del juego | Símbolos/firmas | Offsets con verificación de punteros: es menos probable que se rompa con las actualizaciones |
| Juegos | L4D1 y L4D2 | L4D2 (Harry manda a los de L4D1 al de Accelerator74) |
| Windows / Linux | Ambos | Ambos |

Ojo: `sv_setmax` ≠ `sv_maxplayers` (todos los clientes con bots vs. solo jugadores reales); más de 31
crashea desde The Last Stand. Las configs competitivas ponen el límite de humanos con `mv_maxplayers`
(de `match_vote`) porque `sv_maxplayers` se reinicia al cambiar de mapa; con lakwsh pondríamos
`sv_maxplayers` + `sv_visiblemaxplayers` en `server.cfg`. Para `sv_allow_lobby_connect_only` las dos
fuentes difieren: el `server.cfg` competitivo usa `0`; el tutorial de Harry sugiere `1` junto con su
`l4d_unreservelobby` para servidores de 5+ lugares. A probar en nuestro servidor.
**Decisión (2026-10-02):** por ahora ningún l4dtoolz. El de lakwsh es el probable, una vez que lo
probemos en nuestro servidor y no cause problemas.

### Sonidos del karma kill
Solo para karma kills. El karma kill de eyal282 dispara `KarmaKillSystem_OnKarmaEventPost`, así que un
plugin chico nuestro puede tocar un sonido al azar de nuestra propia lista. Los jugadores tienen que
descargar los sonidos propios:
- **FastDL** es la buena forma (guía completa: [docs/FASTDL.es.md](docs/FASTDL.es.md)): un servidor web con los archivos, y `sv_downloadurl "http://.../"` en el
  servidor del juego. Una IP pública en casa sirve: correr un servidor web chico (nginx, Caddy, o hasta
  `python3 -m http.server`), abrir su puerto en el router, usar `http://` (la descarga del juego no es
  confiable con `https://`), y comprimir los archivos como `.bz2` para que bajen más rápido. Si la IP de
  casa cambia, usar un nombre de DNS dinámico. La velocidad de subida de casa limita qué tan rápido
  descargan los jugadores.
- Sin FastDL, los jugadores descargan del servidor del juego (lento). El `l4d_fastdl_delay_downloader`
  de Harry hace que descarguen solo al cambiar de mapa, no al entrar.

### Antitrampas
Usar **el SMAC de srcdslab y el Little Anti-Cheat de srcdslab**. Empezar LAC con `lilac_ban 0` (solo
registra) un par de semanas.

### Una sola puerta de entrada: `!menu` para jugadores, `!admin` para admins (propuesto 2026-10-02)

**Panel de equipos vs. votaciones, la diferencia:** el menú de admin del panel de equipos es
**instantáneo y solo para admins** (un admin decide y pasa). `!votes` es para que **los jugadores
decidan juntos** en la pantalla de votación del juego, sin admin, para cosas que afectan a todos.
Algunas acciones están en los dos (mezclar, invertir, restaurar equipos): los admins las hacen al
instante, los jugadores las votan.

Para que sea simple para todos:
- **Jugadores:** un solo `!menu` (alias `!lef`) con: *Equipos* (el panel `!teams`, `!swapwith`),
  *Votar* (la lista de `!votes`), *Info* (`!bosses`, `!score`), *Ayuda* (todos nuestros comandos,
  una línea cada uno).
- **Admins:** todo en el menú `!admin` de SourceMod (el que ya usan los admins): la categoría
  *Gestión de equipos* que ya existe, más una categoría nueva *Lefordianos* para ejecutar al
  instante cualquier ítem de votación, y forzar/cancelar la votación en curso. Curar/restaurar
  siguen en *Comandos de jugador*.

**Diseño de `lef_votes`** (inspirado en el `l4d_votes_5` archivado de Harry Potter y en su
`l4d2_vote_change` privado, cuyo README/capturas muestran un menú → Sí/No en la pantalla de
votación del juego, y votaciones personalizadas definidas en un archivo de config): cada ítem de
votación se define en un archivo de config con un título (EN/ES), el comando del servidor que se
ejecuta si pasa, quién puede iniciarla y su mensaje. Agregar una votación = agregar una entrada, sin
programar. Solo hace falta código para los ítems que necesitan un menú antes (elegir mapa, elegir
jugador).

**Votaciones sugeridas:**

| Grupo | Votación | Cómo |
|---|---|---|
| Mapas | Cambiar campaña / mapa (oficiales + custom, nombres del mission manager) | menú, después Sí/No |
| Mapas | Próxima campaña en el final (reemplaza la votación de ACS) | automática en el final |
| Mapas | Reiniciar el mapa actual | Sí/No |
| Mapas | Cambiar el modo de juego (versus, coop, realismo...) | menú, después Sí/No (hoy lo hace Vote_Mode) |
| Equipos | Mezclar / mezcla balanceada (con el roster) / invertir / restaurar los equipos de la última ronda | Sí/No |
| Jugadores | Mover un jugador a espectador (AFK) | elegir jugador, después Sí/No |
| Jugadores | Expulsar a un jugador, o **expulsión troll** (kick + no puede volver por 5 minutos, sin ban real) | elegir jugador, después Sí/No |
| Reglas | Modo solo T1 prendido/apagado | Sí/No (`sm_forcet1`) |
| Reglas | Tank horde monitor prendido/apagado | Sí/No |
| Reglas | Probabilidad de tank / witch por mapa: 0%, 50%, 100% | menú, después Sí/No (desde el próximo mapa) |
| Reglas | Alltalk prendido/apagado | Sí/No |
| Solo admins | Forzar / cancelar la votación en curso | `!admin` |

No sugeridas: "dar vida" (cambia el balance del versus; `!heal` cubre el griefing) y votar baneos (la
expulsión troll lo cubre sin baneos permanentes).


**Decidido el 2026-10-02:** la lista de arriba está aprobada, `!menu` es el nombre. Agregados:
- **La votación de expulsión funciona como la del vanilla:** expulsa y además banea un rato (por defecto
  5 minutos, configurable; 0 = solo expulsar), así un troll expulsado no vuelve enseguida. La expulsión
  propia de SourceMod solo expulsa.
- **Pausa solo por votación:** los jugadores ya no pueden usar `!pause` directo; inician una votación
  Sí/No de pausa (los randoms no pueden abusar). Reanudar sigue igual que en `pause.smx` (ambos equipos se
  ponen listos). Los admins mantienen **forzar pausa / forzar reanudar** al instante en la categoría
  *Lefordianos* de `!admin`.
- **Votación para silenciar** (sugerida): callar la voz y el chat de un jugador por el resto del mapa.
- La revisión de cvars de cliente la cubre el nuevo `lef_client_cvars` (la lista de ZoneMod, sin confogl).

**Más adelante:** mostrar quién votó Sí/No en cada votación (el usuario va a buscar plugins que ya
existan), tiempo de espera entre votaciones, mínimo de jugadores, si los espectadores pueden iniciar o
participar en votaciones (el plugin de Harry tiene esto como cvars).

### Votaciones, y reemplazar Automatic Campaign Switcher
El `l4d_votes_5` archivado de Harry (L4D1_2-Plugins) sirve para aprender: un menú `!votes` (cambiar mapa
oficial/custom, reiniciar, expulsar, dar vida, alltalk) en la pantalla de votación del juego. Su sucesor
`l4d2_vote_change` es privado (de pago, sin código). El `match_vote` de Harry en Sourcemod-Plugins es otro
ejemplo. Idea: nuestro propio menú `!votes` que además reemplace a ACS: en el final, elegir la próxima
campaña en un menú (lista del mission manager) y después una votación Sí/No en la pantalla del juego (en
L4D2 no existen las votaciones de opción múltiple). Otras opciones: modo T1, tank horde monitor
prendido/apagado, mezcla balanceada.

### Tank horde monitor (sin decidir)
Ya se puede prender y apagar: nuestra copia parchada en `plugins/l4d2_tank_horde_monitor` agrega
`l4d2_tank_horde_monitor_enable` (0 = vanilla) y un recordatorio de la regla una vez por ronda. Falta
decidir si se activa; su votación va a ir en el menú `!votes`.

### Equipos balanceados
Archivo de roster con nuestros SteamID, un nombre y un nivel manual del 1 al 5 (los randoms reciben un
nivel por defecto). `!balance` / menú de admin "Mezcla balanceada" prueba todas las formas de repartir a
los jugadores conectados (8 jugadores = 70 formas) y elige la más pareja. Parte de `lef_teams_panel`.
Esperando los SteamID.

### Windows y Linux
Todo tiene que funcionar en los dos:
- Nuestros plugins: el mismo `.smx` corre en ambos. Bien.
- Plugins con gamedata (firmas/offsets): revisar que cada archivo tenga entradas de Windows **y** Linux.
- Las extensiones y plugins de Metamod necesitan `.so` y `.dll`: el repo competitivo trae ambos para sus
  extensiones; el l4dtoolz de lakwsh y Stripper:Source tienen las dos versiones.
- Nuestras herramientas (`build.sh`, `tools/*.sh`) son bash: en Windows usar Git Bash o WSL; si hace
  falta, más adelante se puede hacer una versión en PowerShell.

## Deshacer el griefing: restaurar por admin (hecho como `lef_admin_restore`, 2026-10-01)

Mejora el `admin_hp` de Harry Potter (`!hp` cura a *todos* los supervivientes al máximo, solo root,
sin menú).

- **Curar**: `!heal <jugador|@survivors>`, con una opción en el menú de admin. Reemplaza `!hp`.
- **Registro de daño de equipo**: para cada superviviente, el plugin anota en silencio lo que le
  hicieron sus *compañeros*: vida perdida, derribos causados (que lo acercan al blanco y negro), una
  muerte por un compañero, y una foto de sus objetos tomada justo antes del primer golpe de un compañero.
- **Deshacer**: `!restore <jugador>` (o el menú, que lista quién tiene algo para deshacer, por ejemplo
  "Nick: 45 de vida, 1 derribo, perdió pastillas + molotov, por Troll") devuelve exactamente eso: la
  vida que le quitaron los compañeros, el conteo de derribos, levantarlo si lo derribó un compañero,
  revivirlo junto al equipo si lo mató un compañero, y los objetos que tenía antes.
- **Los admins reciben un aviso** cuando alguien recibe mucho daño de equipo: "Troll le hizo 60 de
  daño de equipo a Nick. !restore Nick para deshacer."
- **Quizás más adelante**: una votación Sí/No (builtinvotes) para que los jugadores puedan restaurar a
  una víctima cuando no hay admins conectados.

**Ya está en la lista**: el `despawn_health` de ZoneMod les devuelve a los SI parte de la vida que les
falta cuando vuelven a ser fantasmas (`si_restore_ratio`, por defecto 0.5 = la mitad, 1.0 = toda).
Está en la sección 7 de la lista de plugins. No hay nada que hacer; solo marcarlo.

## Puntaje de remontada (discusión, 2026-10-01)

**El problema:** el versus vanilla puntúa casi todo por distancia (más 25 puntos de desempate para el
equipo que hizo más daño). Un equipo que muere temprano en un mapa no gana casi nada, así que un mal
mapa puede significar una diferencia de 400+ puntos. Eso desanima al equipo que pierde y a quien se
une a él.

**Cómo podría funcionar técnicamente:** los plugins de puntaje competitivos no reemplazan el marcador;
ajustan la configuración de puntaje del propio juego justo antes de que se cuenten los puntos de la
ronda (`L4D2_OnEndVersusModeRound`). `l4d2_penalty_bonus` usa un truco ingenioso: pone una penalidad
*negativa* por usar el desfibrilador, que se convierte en un bono que aparece en el marcador normal y
**cuenta aunque el equipo muera**. El `holdout_bonus` de ZoneMod está hecho sobre él. Nuestro plugin
también lo usaría.

**Opciones**, de "mantiene el puntaje vanilla" a "lo cambia más":

| | Idea | ¿Cambia los puntos? | ¿Ayuda específicamente al que pierde? |
|---|---|---|---|
| A | **Mostrarlo mejor**: después de cada mapa, la diferencia de puntaje y "necesitas X% del próximo mapa para remontar" (el `l4d2_score_difference` de MoYu ya lo hace), más un conteo de **mapas ganados** ("Mapas: 3–2"), así una paliza es un mapa perdido, no el juego entero. | No | Solo el ánimo |
| B | **Puntos por esfuerzo**: un equipo que muere igual gana puntos por lo que hizo: SI matados, daño/muerte del tank, witch matada/crown. Mismas reglas para ambos equipos. | Sí, un poco | Achica las palizas de quien muera |
| C | **Bono de remontada**: el equipo que va perdiendo recibe un bono pequeño en los mapas siguientes (por ejemplo un % de la diferencia, con límite). Ajustable, podría venir desactivado. | Sí | Sí, directamente |
| D | **Limitar cuánto cambia un mapa**: un mapa no puede agrandar la diferencia en más de N puntos. | Sí | Sí, limita las palizas |
| E | **Puntaje por vida de ZoneMod** (`l4d2_hybrid_scoremod_zone`): puntos por mantenerse sanos. | Mucho | No; es otro juego |

## De las fuentes nuevas (2026-10-01)

- **Información en pantalla (`lef_hud`)**: el `l4d2_scripted_hud` de Mart muestra que los espacios de
  texto del HUD propio de L4D2 (los que usan las mutaciones) se pueden escribir directamente desde
  SourceMod, sin VScript. Podríamos dejar una línea pequeña en pantalla, por ejemplo "Tank 63% · Witch
  no hay · Diferencia 300", alimentada por `lef_boss_spawns` y `lef_score_info`, en vez de solo
  anunciarlo en el chat. Solo hay 4 espacios y las mutaciones los usan, así que debería apartarse en
  esos modos.
- **Vote_Mode en la pantalla de votación del juego**: el `Vote_Mode` de Silvers cambia el modo de
  juego por votación pero usa una votación por menú. Una versión (o envoltorio) con builtinvotes
  encajaría con la idea de la pantalla de votación de arriba. La pantalla de votación es solo Sí/No,
  así que sería "¿Cambiar a Realismo?" después de elegir en un menú.
- **Menú de ayuda `!lef`**: un menú que liste nuestros comandos (`!teams`, `!swapwith`, `!bosses`,
  `!score`, `!comeback`...) en vez del `!menu` genérico de pan0s.
- **Estadísticas para equipos balanceados**: el SRS de pan0s muestra qué estadísticas vale la pena
  guardar; nuestra versión usaría consultas a la base de datos que no traban el servidor y ninguna
  extensión extra.

## Más adelante

- **Grabación de demos** para ambas configs (en pausa desde el 2026-10-01, volveremos a esto):
  - la extensión [sourcetvsupport](https://github.com/shqke/sourcetvsupport) (arregla SourceTV en
    L4D2; hay que descargar el binario de sus releases de GitHub o compilarlo desde el código);
  - un plugin pequeño `lef_demo_recorder` que empiece a grabar cuando arranca la ronda y nombre los
    archivos `fecha_mapa_ronda.dem`. No hay ningún plugin de grabación automática en los repos de
    referencia; el `autorecorder` de shqke (repo sp_public) es el que hay que mirar.

## Lluvia de ideas (de la primera revisión, 2026-10-01)

1. **Modo de partida Vanilla+**: ver arriba.
2. **Reescritura del panel de equipos**: hecho, ver `plugins/lef_teams_panel`.
3. **Equipos balanceados según el historial**: guardar las estadísticas de cada jugador en el tiempo
   (daño a supervivientes/SI, skeets, muertes, daño al tank) en SQLite, y que `!balance` proponga
   equipos parejos. El `l4d_mix` de Harry Potter hace elección por capitanes; esta sería la versión
   por estadísticas para un grupo que juega junto seguido. Podría alimentar directamente la mezcla
   del panel (una opción "mezcla balanceada" en el menú de admin).
4. **Resumen de la partida**: después de cada mapa, publicar puntajes, MVPs, daño al tank y momentos
   graciosos ("Ellis mató a 3 compañeros"). Ya existen partes: `l4d2_playstats`, `survivor_mvp`,
   `l4d_tank_damage_announce`, `l4d_pig_infected_notify`, `l4dffannounce`. Publicar en Discord
   necesitaría una extensión HTTP (SteamWorks o REST in Pawn), que no está en los repos de referencia.
5. **Un sistema de modos más liviano que confogl**: cambiar "perfiles" de configuración (cvars +
   lista de plugins) sin los extras competitivos de confogl. Solo vale la pena si el modo con
   confogl termina estorbando.

## Más ideas

- **Más cosas en el menú de admin**: el menú `!admin` de SourceMod podría tener más categorías de L4D2:
  - cambiar de mapa/campaña: `l4d2_mm_adminmenu` (mission manager) ya lo hace;
  - revivir a un superviviente muerto donde apuntas: `l4d_sm_respawn` (Harry Potter);
  - hacer aparecer objetos/SI y controlar al director: `all4dead2` tiene un menú;
  - reiniciar la ronda / intercambiar los puntajes (`l4d2_setscores`) para cuando algo sale mal.
  Una categoría de admin "Lefordianos" podría juntar las que usemos.
- **Modernizar más plugins con sintaxis vieja** que encontremos en AlliedModders: el mismo trato que
  el panel de equipos (sintaxis nueva, Left4DHooks en vez de gamedata propia, traducciones).

## Hecho

- **lef_votes** y **lef_menu**: `!votes` desde un archivo de config (la lista de arriba, expulsar con baneo de 5 minutos, pausa solo por votación, categoría *Lefordianos* de admin con forzar pausa/quitar pausa y aprobar/cancelar) y `!menu` para jugadores. Falta probarlos en el juego. Pendiente: la votación de final estilo ACS, la mezcla balanceada (espera el roster) y mostrar quién votó.
- **lef_client_cvars**: revisión de cvars de cliente (brillo, niebla, linterna...) sin confogl, con la lista de ZoneMod. Falta probarlo en el juego.

- **Paquete de la config lite**: `configs/lite/manifest.txt` + `tools/build_lite.py` (170 plugins, Windows y Linux), nuestras configs en `configs/lite/left4dead2/` (valores de ZoneMod, archivos por modo, mensajes del servidor). Todas las herramientas pasaron a Python para que también corran en Windows.

- **lef_karma_sounds**: nuestro propio sonido al azar en los karma kills, esperando los archivos de sonido.
- **l4d2_tank_horde_monitor (parchado)**: interruptor y recordatorio de la regla.
- **Stripper lite**: generado desde el de ZoneMod con `tools/make_stripper.py`.

- **lef_saferoom_doors**: quién abrió la puerta del refugio inicial, quién cerró la final con compañeros afuera. Falta probarlo en el juego.
- **lef_t1_mode**: modo solo armas T1 que se prende y apaga (cvar, admin, votación `!t1`), lista configurable. Falta probarlo en el juego.

- **lef_admin_restore**: `!heal`, `!restore`, `!teamdamage`, avisos a los admins. Falta probarlo en el juego.
- **lef_score_info** (opción A) y **lef_comeback_bonus** (opción C): hechos, falta probarlos en el juego.
- **lef_boss_spawns**: probabilidad de tank/witch por mapa (igual para ambos equipos), los jefes de la
  segunda mitad aparecen en el lugar de la primera (port del BossSpawning de confogl), % anunciado.
  Funciona con `witch_and_tankifier` / `l4d_boss_percent`, sin Ready-Up ni confogl.
- **l4d_tank_control_eq (parchado)**: rotación de tank sin el requisito de Ready-Up.
- **lef_teams_panel**: reescritura del panel de jugadores de BwA Jester. `!teams`, `!lastteams`,
  `!swapwith` y un menú de admin "Gestión de equipos" (mover, intercambiar, invertir, mezclar, restaurar).
