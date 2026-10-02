[English](README.md)

# lef_votes — Lefordianos Votes (votaciones)

`!votes`: los jugadores deciden cosas juntos en la pantalla de votación del propio juego (F1 = Sí,
F2 = No). Los admins tienen las mismas opciones en `!admin`, donde se hacen al instante, sin votar.
Left 4 Dead 2.

## Qué se puede votar

Todo está en `addons/sourcemod/configs/lef_votes.cfg`, por grupos. Agregar una votación normalmente es
agregar una entrada con un comando del servidor, sin programar. Se recarga con `sm_votes_reload`.

| Grupo | Votaciones |
|---|---|
| Mapas | Cambiar mapa (campaña → lista de mapas del mission manager), reiniciar este mapa, cambiar modo de juego (abre el `!votemode` de Vote_Mode) |
| Equipos | Mezclar, mezcla balanceada (niveles del roster), intercambiar sobrevivientes e infectados, volver a los equipos de la ronda pasada (`lef_teams_panel`) |
| Jugadores | Expulsar, mover a espectadores (AFK), silenciar voz y chat por el resto del mapa |
| Reglas | Probabilidad de tank y witch 0 / 50 / 100 %, solo armas T1 sí/no, tank horde monitor sí/no |
| Partida | Pausar, voz entre equipos sí/no |

Tipos de entrada: `command` (corre un comando del servidor si la votación pasa), `client` (abre el menú
de otro plugin, sin votar acá; se oculta si ese plugin no está), `map`, `restart`, `kick`, `spec`,
`mute`, `pause`. El archivo de config explica cada uno.

## Expulsar funciona como en vanilla

La votación de expulsión del juego además impide volver por un rato. La expulsión de SourceMod no, así
que un troll expulsado podía volver enseguida. Acá expulsar por votación es expulsar más un baneo corto:
`lef_votes_kick_ban_minutes` (5 por defecto; 0 = solo expulsar). Los admins con alguna bandera de
`lef_votes_immune_flags` (por defecto `b`) no pueden ser expulsados, movidos ni silenciados por votación.

## Pausa solo por votación

Para que los randoms no pausen cuando quieran, los jugadores no pueden usar `!pause` directo: escribirlo
inicia una votación de pausa. Si pasa, el juego se pausa como siempre (`pause.smx`), y quitar la pausa
funciona igual que antes (los dos equipos `!ready`). Los admins sí pueden `!pause` directo, y tienen
**forzar pausa** y **forzar quitar pausa** en el menú de admin. Se apaga con `lef_votes_pause_by_vote 0`.

## Menú de admin

`!admin` → **Lefordianos**:

- **Hacer una opción de votación ya**: todas las de arriba, sin votar.
- **Forzar pausa / Forzar quitar pausa** (`sm_forcepause` / `sm_forceunpause` de `pause.smx`).
- **Aprobar / cancelar la votación actual** (también `sm_vp` y `sm_vc`).

## Ajustes

| Cvar | Por defecto | Qué hace |
|---|---|---|
| `lef_votes_pass_percent` | 50 | Una votación pasa si más de este porcentaje de los votos son Sí |
| `lef_votes_min_players` | 1 | Jugadores necesarios en el servidor para iniciar una votación |
| `lef_votes_time` | 20 | Segundos que la votación queda en pantalla |
| `lef_votes_spectators_call` | 0 | Los espectadores pueden iniciar votaciones |
| `lef_votes_spectators_vote` | 1 | Los espectadores pueden votar |
| `lef_votes_kick_ban_minutes` | 5 | Minutos que un expulsado por votación no puede volver (0 = solo expulsar) |
| `lef_votes_immune_flags` | b | Banderas de admin que no se pueden expulsar, mover ni silenciar por votación |
| `lef_votes_pause_by_vote` | 1 | Los jugadores solo pueden pausar con una votación |

La pantalla de votación muestra un solo texto para todos, en el idioma del servidor; los menús siguen el
idioma de cada jugador (inglés o español).

## Necesita

- [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696) y la extensión **BuiltinVotes**.
- Opcional: `l4d2_mission_manager` de Harry Potter (votar mapa), `pause.smx` (pausa), `basecomm`
  (silenciar; viene con SourceMod), `lef_teams_panel`, `lef_t1_mode`, `lef_boss_spawns`,
  `l4d2_tank_horde_monitor`, Vote_Mode. Una votación de un plugin que no está no hace nada.

## Créditos

Ideas del `l4d_votes_5` archivado de Harry Potter y de su `l4d2_vote_change` (votaciones definidas en un
archivo de config). El include del mission manager es de Harry Potter (basado en el de rikka0w0).
