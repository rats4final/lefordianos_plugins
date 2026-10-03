[English](CHANGELOG.md)

# Registro de cambios

Lo que se hizo, por fecha. Nada de esto se probó todavía en un servidor real. Los detalles y razones
están en [IDEAS.es.md](IDEAS.es.md); lo que cada parte le da a los jugadores está en
[docs/BENEFITS.es.md](docs/BENEFITS.es.md).

## 2026-10-04

- **Archivos cfg sin tildes:** el juego cortaba las líneas de los cfg en las tildes, así que los
  comentarios en español se ejecutaban como comandos (montones de "Unknown command" en la consola). Todos
  los cfg del juego quedan en ASCII y `build_lite.py` avisa si vuelve una tilde. `sv_allowdownload` va con
  `sm_cvar` (L4D2 lo esconde).
- **Votación de silenciar:** eliges voz, chat o ambos; dura hasta que termina la ronda, como advertencia
  (antes era voz y chat por el resto del mapa).
- **Elegir el tank** en `!votes` (solo el equipo infectado): el compañero elegido recibe el próximo tank, o
  el actual si ya hay uno en juego. Los admins ya tenían `sm_forcepass`, `sm_taketank`, `sm_givetank`.
- **Consejo del tank corregido:** con nuestro control del tank, un jugador tiene 2 barras de control y
  después el tank pasa a un bot.
- **`lef_campaigns` reemplaza a ACS:** la próxima campaña se vota en `!votes` en la pantalla de votación
  del juego (en cualquier momento), `!next` la muestra; sin votación, la siguiente de la lista.
- **Votación de modo de juego** en la pantalla de votación del juego (`!votes` > Cambiar modo de juego),
  con la lista de Vote_Mode; su votación vieja por el chat queda solo para admins.
- **Quad caps** posibles (`l4d2_dominators 0`, como en ZoneMod), a pedido del dueño.
- **Tecla M** (menú de equipos) vuelve a funcionar (`l4d_afk_commands_pressM_block 0`); sigue las mismas
  reglas de balance que `!survivors`/`!infected`.
- **Consejos para el tank:** controles de las rocas (clic derecho / E / R), la barra de control y `!pass`.
- **Mensajes del servidor** reescritos: `!menu`, `!votes`, `!wait`, `!rank`, estadísticas, el panel de
  inicio, consejos del tank.
- **`lef_ranks`:** un ranking por mapas ganados (Elo para equipos), `!rank` y `!top`; la mezcla
  balanceada usa sus puntos cuando un jugador tiene 5 mapas que cuenten (antes, los niveles del roster).
- **c5m5 (puente de The Parish):** ya no aparecen 4 botiquines en el camión junto al tank (ZoneMod los
  pensó como pastillas, con confogl); vuelven los objetos al azar normales del mapa.
- **`!wait`:** cuenta regresiva 3-2-1 con los pitidos de Ready-Up al terminar la espera; en el primer mapa
  de una campaña (sin refugio) quien se aleja mientras se espera vuelve teletransportado a donde estaba
  (congelar es una opción), por eso ahí no funcionaba.
- **Recordatorios del tank** (`lef_boss_spawns`): cada 2 minutos mientras falta el tank, y un aviso
  cuando los sobrevivientes están a 5% o menos.
- **Sonido de aparición de la witch** cambiado por su propia música: usaba el mismo sonido que el aviso
  del tank.
- **Todas las jugadas destacadas** (skeets, crowns, deadstops, pops...) se muestran en el chat.

## 2026-10-03

- **Corrección (primera noche con jugadores):**
  - El aviso de witch de Harry no tenía su archivo de traducción en el paquete: el armador no entendía
    nombres de archivo unidos con el operador `...` de SourcePawn. Ahora sí (ningún otro plugin estaba
    afectado).
  - El recordatorio del tank horde monitor usaba dos colores de equipo (`{red}` y `{blue}`), y la
    librería de colores no lo permite; ahora `{red}` y `{olive}`.
  - `l4d2_playstats` se pasaba de su espacio para la consola después de una sesión larga con muchos
    jugadores entrando y saliendo. Copia parchada con lugar para 32 bloques en vez de 10.
- **Vómito del boomer:** `vomit_collide_strict 0`. `l4d_vomit_trace_patch` hacía que el vómito necesitara
  el hitbox exacto del sobreviviente (elección de ZoneMod); los jugadores sentían que llegaba menos lejos.
  Su arreglo de los infectados que bloqueaban el vómito se mantiene.
- **Apagado** por ahora `boomer_horde_equalizer_refactored`: el dueño sospecha que algo hace mal.
- **Quitado** el `Dynamic_Light` de Silvers (la luz extra donde apuntan las linternas de los
  sobrevivientes), a pedido del dueño.
- **Tus propios ajustes:** `cfg/lefordianos/custom.cfg` se ejecuta al final de `common.cfg` en cada mapa,
  así sus valores ganan sobre server.cfg y las configs de los plugins; las actualizaciones solo traen
  `custom.example.cfg`.
- **Transiciones de mapas** (`l4d2_map_transitions` + `l4d2_transition_info_fix` de Harry Potter) para
  unir campañas en versus.
- **Corrección (primera prueba en el servidor):** 20 plugins de correcciones no cargaban porque sus
  archivos de gamedata no estaban en el paquete: el armador solo encontraba la gamedata cargada a la
  antigua (`LoadGameConfigFile`), no la forma nueva `new GameData(...)`. Ahora encuentra las dos.
- **Corrección:** `l4d_afk_commands` necesita una extensión Actions más nueva que la del repo competitivo;
  el paquete ahora trae Actions 3.9.2 (mantiene todas las funciones anteriores).
- **Corrección:** `l4d2_survivor_mourn_fix` necesita `sceneprocessor`; ahora está incluido.
- **Corrección (segunda prueba en el servidor):**
  - `pause` tiraba errores cada segundo durante la pausa: necesita `sv_maxplayers`, que solo existe con
    l4dtoolz. Copia parchada en `plugins/pause`.
  - `si_class_announce` llamaba a Ready-Up sin revisar que estuviera cargado. Copia parchada en
    `plugins/si_class_announce`.
  - `lerpmonitor` permitía como máximo 67 ms (un valor para 100 tick), así que quien tenía el lerp por
    defecto del juego (100 ms) iba a espectadores. Ahora hasta 100 ms.
  - Los jugadores con Steam en "Español - Latinoamérica" veían todo en inglés: SourceMod lo trata como
    otro idioma (`las`). Ahora cada traducción en español del paquete también lo cubre.
- **Panel de inicio:** muestra las clases iniciales del equipo infectado; se queda 15 s después de que los
  sobrevivientes salen del refugio y se esconde con el primer golpe de un infectado (hasta 60 s).
- **Se anuncia cuando aparece una witch** (`tank_witch_spawn_notify` de Harry Potter).
- La opción **Próxima campaña** de `!votes` y `!menu` solo aparece en los mapas finales: ACS solo permite
  esa votación ahí y en otros mapas respondía "solo en un mapa final" (clave `"finale_only"`). Para
  cambiar de campaña a mitad, sigue `!votes` > Cambiar mapa.
- **ACS en español:** solo traía inglés, chino, francés y ruso; agregamos español (y español
  latinoamericano).
- **Corrección:** los ajustes cambiados por votación o admin (modo T1, probabilidad de tank/witch, tank
  horde monitor, voz entre equipos) se deshacían en el mapa siguiente, porque cada cambio de mapa vuelve a
  ejecutar las configs. Ahora duran hasta que el servidor se vacía (clave `"persist"` de `lef_votes`, y el
  propio `lef_t1_mode`).
- **Config lite:** addons del workshop de los jugadores apagados para todos (`l4d2_addons_eclipse 0` en
  `common.cfg`).
- **Config lite:** un `server.cfg` de ejemplo (a partir del del repo competitivo y del de Harry Potter,
  revisado con la wiki de Valve) y `test_bots.cfg` / `test_off.cfg` para probar solo con bots.

## 2026-10-02

### Plugins nuevos
- **`lef_round_start`**: panel de inicio de ronda (dónde sale tank/witch, equipos, comandos) y `!wait`,
  una votación que mantiene cerrado el refugio hasta que entre un amigo. `+1` en el chat solo da un
  consejo privado. Sin Ready-Up.
- **`lef_game_hints`**: solo avisos, para rushear, quedarse atrás y guardar un infectado mucho tiempo.
  Consejos para quien pasa a ser tank (o recibe el tank).
- **`lef_bot_protect`**: los bots sobrevivientes reciben 15% menos daño de los jugadores infectados,
  para que no sean muertes gratis.
- **`lef_steam_bans`**: avisa a los admins de los baneos VAC, de juego y de comunidad de quien entra
  (solo baneos, sin horas). Usa REST in Pawn y una clave de la API web de Steam.
- **`lef_votes`**:
  - `!votes` desde un archivo de config: mapas, equipos, expulsar con baneo de 5 minutos (como en
    vanilla), AFK, silenciar, reglas, pausa solo por votación;
  - una categoría *Lefordianos* en `!admin`;
  - después de cada votación, la lista de quién votó Sí y No;
  - la votación de próxima campaña de ACS se abre en los mapas finales.
- **`lef_menu`**: `!menu` con todos los comandos para jugadores del servidor.
- **`lef_client_cvars`**: expulsa a quien tenga cvars de cliente que dan ventaja (brillo total, sin
  niebla...), la lista de 59 cvars de ZoneMod, sin confogl.
- **`lef_saferoom_doors`**: quién abrió la puerta del refugio inicial, quién cerró la del final dejando
  compañeros afuera.
- **`lef_t1_mode`**: modo de solo armas T1 que se prende y apaga (votación, admin o cvar).
- **`lef_karma_sounds`**: sonidos propios en los karma kills (esperando los archivos de sonido).

### Cambios
- **`lef_teams_panel`**:
  - mezcla balanceada, con un roster de SteamID y niveles;
  - les dice a los que entran y a los espectadores cómo emparejar los equipos.
- **`l4d2_tank_horde_monitor`** (parchado): interruptor y recordatorio de la regla; instalado apagado.

### Config lite
- Armada: 177 plugins para Windows y Linux.
- **Ajustes:**
  - valores de ZoneMod en los plugins de juego elegidos;
  - 50% de probabilidad de tank y 50% de witch por mapa;
  - nadie puede unirse al equipo que ya tiene más humanos;
  - ACS anuncia su votación en el chat.
- **Archivos de mapas:**
  - configs de Stripper generadas desde las de ZoneMod, sin los reworks especiales y algunos cambios
    globales;
  - configs por modo de juego con el `gamemode-based_configs` de Harry Potter.
- **Plugins de otras fuentes:**
  - antitrampas: SMAC y Little Anti-Cheat (srcdslab), LAC solo registrando;
  - extensión REST in Pawn.

### Herramientas y documentación
- **Herramientas:** de armado en Python para Windows y Linux: compilador fijo de SourceMod 1.12, repos
  de referencia fijados, extensiones fijadas, armador del paquete lite, generador de Stripper.
- **Documentación:** créditos de cada fuente; documentos en inglés y español; guía de FastDL; AGENTS.md
  para sesiones de IA.
- **Referencias:** plugins de AlliedModders importados (Mart, NoroHime, Silvers, pan0s). Repos de
  AoC-Gamers revisados.

## 2026-10-01

- **Inicio del repo.** Lectura de los repos de referencia; lista de ideas; lista bilingüe de plugins
  para la config lite.
- **`lef_teams_panel`**: reescritura del Players Panel de -=BwA=- Jester (`!teams`, `!swapwith`, menú
  de admin Team Management).
- **`lef_boss_spawns`**:
  - probabilidad de tank/witch por mapa, igual para los dos equipos;
  - mismos lugares en las dos mitades;
  - % anunciados.
- **`lef_score_info`**: `!score` explica el puntaje de versus (cuánto vale el mapa, la diferencia, lo
  que falta).
- **`lef_comeback_bonus`**: un bono para el equipo que va perdiendo (hecho, no está en el paquete lite).
- **`lef_admin_restore`**: `!heal` y `!restore` para deshacer el griefing (daño de equipo, derribos,
  objetos perdidos).
- **`l4d_tank_control_eq`**: parchado para funcionar sin Ready-Up.
