[English](README.md)

# lef_campaigns — Lefordianos Campaigns (campañas)

Rotación de campañas. Reemplazó al Automatic Campaign Switcher (ACS) de rikka0w0 el 2026-10-04, para
que la próxima campaña se pueda votar en la pantalla de votación del propio juego. Left 4 Dead 2.

- Cuando termina una campaña (versus: los dos equipos jugaron el final; coop: los sobrevivientes escapan),
  el servidor cambia a la **próxima campaña** después de `lef_campaigns_delay` segundos (12, mientras se ve
  el marcador).
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
| `lef_campaigns_delay` | 12 | Segundos después del final antes de cambiar |
| `lef_campaigns_announce` | 1 | En los mapas finales, decir qué campaña sigue |

Necesita [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696) y el `l4d2_mission_manager`
de Harry Potter (la lista de campañas).
