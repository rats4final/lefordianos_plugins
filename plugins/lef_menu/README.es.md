[English](README.md)

# lef_menu — Lefordianos Menu (menú)

`!menu` (o `!lef`): un menú con todos los comandos para jugadores del servidor, para que nadie tenga que
recordarlos. Elegir una opción corre ese comando para el jugador, como si lo hubiera escrito.
Left 4 Dead 2.

Las herramientas de admin siguen en `!admin` (la categoría *Lefordianos* está en
[lef_votes](../lef_votes/README.es.md)).

| Grupo | Opciones |
|---|---|
| Equipos | Quién está en cada equipo, equipos de la ronda pasada, cambiar de lugar con un jugador, unirse a sobrevivientes / infectados, ir AFK |
| Votaciones | Iniciar una votación (`!votes`), votar armas T1, votar modo de juego |
| Info de la partida | Puntajes, tank y witch en este mapa, quién será el tank, bono de remontada |
| Partida | Pausar (inicia una votación), listos para quitar la pausa, ajustes del cliente que revisa el servidor |

Las opciones están en `addons/sourcemod/configs/lef_menu.cfg` (título en inglés y español, más el
comando). Una opción cuyo comando no existe en el servidor se oculta, así el mismo archivo sirve con
cualquier conjunto de plugins. Se recarga con `sm_menu_reload`.
