[English](README.md)

# lef_match — Lefordianos Match (partida)

Herramientas de admin para una partida de versus. Left 4 Dead 2.

## Qué hace

- **Mantiene los puntajes cuando un admin cambia el mapa dentro de la misma campaña.** El juego
  trata cualquier cambio de mapa forzado como una partida nueva y deja a los dos equipos en 0:
  reiniciar el capítulo, o elegir un mapa con *Cambiar mapa* de SourceMod (`sm_map`), el mission
  manager, `!votes`, `changelevel`... Con este plugin, si el mapa nuevo es de la misma campaña (y no es
  su primer mapa), cada equipo recupera los puntos que tenía **cuando empezó el capítulo que se estaba
  jugando** (el capítulo sin terminar no cuenta), y los equipos vuelven al lado en que empezaron ese
  capítulo.
- **Reiniciar capítulo** (`!restartchapter`): reinicia el capítulo que se está jugando, con los
  puntajes.
- **Volver al lobby** (`!returntolobby` / `!lobby`): manda a todos al lobby, como el voto "Volver al
  lobby" del juego cuando pasa.
- Los dos están en **`!admin` → Comandos de servidor** (los dos primeros), con un "¿seguro?".

Una campaña nueva, volver al primer mapa de una campaña (también el "Reiniciar campaña" del juego) o
un servidor vacío (todos volvieron al lobby, fin de la noche) empiezan de 0, como siempre.

## Comandos (admins con el permiso de cambiar mapa, `g`)

| Comando | Qué hace |
|---|---|
| `!restartchapter` | Reinicia este capítulo en 3 segundos; puntajes mantenidos. |
| `!returntolobby`, `!lobby` | Todos al lobby en 3 segundos. |

## Ajustes (`cfg/sourcemod/lef_match.cfg`)

| Cvar | Por defecto | Qué |
|---|---|---|
| `lef_match_keep_scores` | `1` | Mantener los puntajes en cambios de mapa forzados dentro de la campaña. `0` = lo que hace el juego. |
| `lef_match_delay` | `3` | Segundos de aviso antes de reiniciar o volver al lobby. |

## Cómo funciona

- Al empezar cada capítulo (primera mitad) anota los puntajes de los dos equipos de la campaña y cuál
  empieza como supervivientes. Cada 10 segundos anota qué jugadores están en qué equipo.
- Cuando un mapa empieza con los dos puntajes en 0 aunque el capítulo anterior tenía puntos, en la
  misma campaña, el mapa se cambió a la fuerza. Espera a que todos terminen de cargar (30 s como
  máximo, o hasta que los supervivientes salgan del refugio), devuelve los equipos al orden del
  capítulo con `sm_flipteams` de `lef_teams_panel` si volvieron cambiados, y pone los puntajes donde
  los pone `l4d2_setscores` del repo competitivo (más la copia del Versus Director, con Left4DHooks).
- "Misma campaña" lo dice `l4d2_mission_manager` de Harry. Sin él, solo reiniciar el mismo mapa
  mantiene los puntajes.
- Volver al lobby: cuando pasa el voto del juego, el servidor (`Director::FinishScenarioExit` en
  `server.dll`) les manda a todos los jugadores un mensaje `DisconnectToLobby`. Este plugin manda el
  mismo mensaje.

## Necesita

Left4DHooks, colors.inc. Opcional: `l4d2_mission_manager` (misma campaña), `lef_teams_panel`
(devolver los equipos), el menú de admin.

**Todavía no probado con jugadores** (2026-10-08): revisar el mensaje "puntajes mantenidos" en el chat
y el marcador después del primer reinicio.
