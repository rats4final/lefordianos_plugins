[English](README.md)

# lef_steam_bans — Lefordianos Steam Bans (baneos de Steam)

Cuando un jugador entra, le pregunta a Steam si su cuenta tiene **baneos VAC**, **baneos de juego** (del
antitrampas propio de un juego) o un **baneo de la Comunidad de Steam**, y les avisa a los admins. Solo
mira baneos: **ni horas, ni perfil, ni amigos**, nada más del jugador. Left 4 Dead 2 (sirve en cualquier
juego Source).

- Los admins (bandera genérica, override `lef_bans_notify`) lo ven en el chat; `lef_bans_announce 1` le
  avisa a todos.
- Todo lo que encuentra va a `logs/lef_steam_bans.log`.
- Cada cuenta se consulta una vez por arranque del servidor; los cambios de mapa no vuelven a preguntar.
- `sm_checkbans <jugador>` vuelve a preguntar y también te dice cuando no hay nada.
- Nunca expulsa, salvo que pongas `lef_bans_kick_vac_days` (ej. 365 = expulsar baneos VAC del último año).

## Configurar

1. Saca una clave de la API web de Steam en <https://steamcommunity.com/dev/apikey> (sirve cualquier
   nombre de dominio).
2. En el servidor, ponla en `cfg/sourcemod/lef_steam_bans.cfg` (se crea al cargar la primera vez):
   `lef_bans_apikey "TUCLAVE"`. **Mantenla privada**: nunca la pongas en este repo ni en una config
   compartida.
3. Cambia de mapa o reinicia.

Sin clave el plugin no hace nada (una línea en el log de errores dice por qué).

## Ajustes

| Cvar | Por defecto | Qué hace |
|---|---|---|
| `lef_bans_apikey` | (vacío) | Clave de la API web de Steam |
| `lef_bans_announce` | 0 | 0 = solo admins, 1 = todos |
| `lef_bans_game_bans` | 1 | También informar baneos de juego |
| `lef_bans_community` | 0 | También informar baneos de la Comunidad de Steam |
| `lef_bans_kick_vac_days` | 0 | Expulsar si el último baneo VAC es más nuevo que estos días. 0 = nunca |

## Necesita

La extensión **REST in Pawn** ([sm-ripext](https://github.com/ErikMinekus/sm-ripext)); el paquete lite la
incluye para Windows y Linux (`tools/get_extensions.py`).

## Créditos

Idea del VAC Status Checker de StevoTVR (que Harry Potter tiene como `vacbans`), que usa la extensión
Socket en su lugar.
