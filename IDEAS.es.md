[English](IDEAS.md)

# Ideas

Una lista que va creciendo. Agreguen lo que quieran y pasen las cosas a "Hecho" cuando estén listas.

**La regla general:** mantener la sensación vanilla. Las correcciones de bugs y las mejoras de
comodidad son bienvenidas; cualquier cosa que cambie el balance del juego debe ser opcional y estar
desactivada por defecto.

## En progreso

- **Config lite (sin confogl)**: un servidor con SourceMod simple: las correcciones de bugs del repo
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

- **lef_admin_restore**: `!heal`, `!restore`, `!teamdamage`, avisos a los admins. Falta probarlo en el juego.
- **lef_score_info** (opción A) y **lef_comeback_bonus** (opción C): hechos, falta probarlos en el juego.
- **lef_boss_spawns**: probabilidad de tank/witch por mapa (igual para ambos equipos), los jefes de la
  segunda mitad aparecen en el lugar de la primera (port del BossSpawning de confogl), % anunciado.
  Funciona con `witch_and_tankifier` / `l4d_boss_percent`, sin Ready-Up ni confogl.
- **l4d_tank_control_eq (parchado)**: rotación de tank sin el requisito de Ready-Up.
- **lef_teams_panel**: reescritura del panel de jugadores de BwA Jester. `!teams`, `!lastteams`,
  `!swapwith` y un menú de admin "Gestión de equipos" (mover, intercambiar, invertir, mezclar, restaurar).
