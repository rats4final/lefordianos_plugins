[English](CHANGELOG.md)

# Registro de cambios

Lo que se hizo, por fecha. Nada de esto se probó todavía en un servidor real. Los detalles y razones
están en [IDEAS.es.md](IDEAS.es.md); lo que cada parte le da a los jugadores está en
[docs/BENEFITS.es.md](docs/BENEFITS.es.md).

## 2026-10-03

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
