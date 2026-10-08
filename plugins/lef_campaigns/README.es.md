[English](README.md)

# lef_campaigns — Lefordianos Campaigns (campañas)

Rotación de campañas. Reemplazó al Automatic Campaign Switcher (ACS) de rikka0w0 el 2026-10-04, para
que la próxima campaña se pueda votar en la pantalla de votación del propio juego. Left 4 Dead 2.

- **Versus**, cuando los dos equipos jugaron el final: la pantalla final del juego deja votar **jugar de
  nuevo** (revancha) o el **lobby** durante 30 segundos (`sv_pz_endgame_vote_period`, en
  `lefordianos/common.cfg`; los 12 del juego no dejaban tiempo), más 5. La revancha la hace el juego. Si
  no, el juego mandaría a todos al lobby: este plugin cambia a la **próxima campaña** en su lugar, salvo
  que más jugadores hayan votado el lobby que jugar de nuevo, que haya pasado un voto "Volver al lobby", o
  que un admin haya usado `!lobby` (`lef_match`). Cómo funciona la pantalla final se leyó del
  `server.dll` (2026-10-08); todavía sin probar con jugadores.
- **Coop**: el servidor cambia a la próxima campaña `lef_campaigns_delay` segundos (12) después de que los
  sobrevivientes escapan.
- La próxima campaña es la votada con **`!votes` > Mapas > Próxima campaña** (eliges una campaña y
  después hay una votación Sí/No con F1/F2), en cualquier momento de la campaña. Sin votación, es la
  siguiente en la lista del mission manager de Harry Potter: primero las oficiales, después las del
  Workshop (Big Wat Night...).
- En un mapa final, 20 segundos después de salir del refugio, el chat dice qué campaña sigue y cómo votar
  otra.
- Si otro plugin cambia el mapa primero (ej. `l4d2_map_transitions` en `c9m2_lots`), ese gana: nuestro
  cambio se cancela con cualquier cambio de mapa.

| Comando | Qué hace |
|---|---|
| `!next` | Qué campaña sigue |
| `sm_setnextcampaign <primer mapa>` / `clear` | Fijar u olvidar la próxima campaña (admins con permiso de cambiar mapa; es lo que corre la votación) |

| Cvar | Por defecto | Qué hace |
|---|---|---|
| `lef_campaigns_delay` | 12 | Coop: segundos después del escape antes de cambiar (versus sigue la pantalla final) |
| `lef_campaigns_announce` | 1 | En los mapas finales, decir qué campaña sigue |

Necesita [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696) y el `l4d2_mission_manager`
de Harry Potter (la lista de campañas).
