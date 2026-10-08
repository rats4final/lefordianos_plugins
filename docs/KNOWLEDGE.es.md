[English](KNOWLEDGE.md)

# Base de conocimientos

Problemas que encontramos corriendo el servidor, qué los causa (o qué sospechamos) y qué hacer. Una
línea cada uno; la explicación larga está en el documento enlazado. **Estado:** *confirmado* = sabemos
la causa y el arreglo funcionó; *sospecha* = la mejor idea, seguimos mirando; *por verificar* = todavía
no se investigó.

Cuando aparezca algo nuevo, agrégalo acá (y en `KNOWLEDGE.md`).

## Entrar al servidor

| Síntoma | Estado | Causa | Qué hacer |
|---|---|---|---|
| "No Steam logon" / "STEAM validation rejected", varios jugadores echados a la vez | confirmado | El servidor pierde contacto con Steam y echa a quien no puede verificar | l4dtoolz con `sv_steam_bypass 1` (prendido en nuestro paquete). Costo: los SteamID no se verifican con Steam. [CONNECTION](CONNECTION.es.md#no-steam-logon--steam-validation-rejected) |
| "Duplicate client connection" y después "STEAM validation rejected" | confirmado | El servidor todavía tiene la conexión vieja de ese jugador | Esperar un minuto, o `kickid <userid>`. [CONNECTION](CONNECTION.es.md#duplicate-client-connection-y-después-steam-validation-rejected) |
| "Reservation request with bogus payload data" cuando el dueño inicia la sala | **sospecha** | La PC del dueño llega a su propio servidor por dos caminos (IP local y pública) y los mezcla | Regla de firewall en la PC del dueño que bloquea el camino por la IP pública. Funcionó en la primera prueba. [CONNECTION](CONNECTION.es.md#reservation-request-with-bogus-payload-data-cuando-el-dueño-inicia-la-sala) |
| "La sesión ya no está disponible" con `connect` | sospecha | El servidor sigue reservado por una sala que falló | Esperar un minuto o `sv_cookie 0`; siempre poner el puerto (`:27016`). [CONNECTION](CONNECTION.es.md#la-sesión-ya-no-está-disponible-con-connect) |
| "Server is enforcing consistency for this file: addons/xxx.vpk" | confirmado | `sv_consistency 1` compara los addons por ruta; el servidor y el jugador tienen la campaña en rutas distintas | La misma ruta en los dos: todos usan la copia del Workshop (`addons/workshop/<id>.vpk`). [CONNECTION](CONNECTION.es.md#server-is-enforcing-consistency-for-this-file-addons) |

## Archivos de configuración

| Síntoma | Estado | Causa | Qué hacer |
|---|---|---|---|
| Lluvia de "Unknown command" con pedazos de palabras en español (p. ej. `a de RCON`) | confirmado | El motor corta las líneas de los cfg en las letras con acento | Los cfg del juego van solo en ASCII, comentarios incluidos. `build_lite.py` avisa |
| "Unknown command" para `sv_allowdownload`, `sv_downloadurl` | confirmado | L4D2 esconde algunos cvars de los archivos cfg | Ponerlos con `sm_cvar` |
| Un ajuste cambiado por voto o por un admin vuelve atrás al cambiar de mapa | confirmado | Cada cambio de mapa vuelve a correr todas las configs | Los cambios permanentes van en `cfg/lefordianos/custom.cfg` (corre al final); nuestros plugins vuelven a aplicar solos lo votado |
| Un valor en el `cfg/sourcemod/<plugin>.cfg` de un plugin no hace efecto | confirmado | `lefordianos/common.cfg` y `custom.cfg` corren después y ganan | Cambiarlo en `custom.cfg` |
| `auto_all_bot_game_enable` da "Unknown command" | confirmado | Ese cvar no existe en L4D2 | Borrar la línea |
| `sm_onlyforce 1` rompe el voto de pausa | confirmado | Solo permite pausas forzadas por un admin | Dejar `sm_onlyforce 0` |

## Plugins

| Síntoma | Estado | Causa | Qué hacer |
|---|---|---|---|
| `l4d2_chainsaw_fix` no carga en Windows | confirmado | Arregla un crash que solo pasa en Linux; no tiene gamedata de Windows a propósito | No hace daño; el repo del servidor lo deja en `plugins/disabled/` |
| Un plugin falla por gamedata o traducción faltante | confirmado | El empaquetador no encontró un archivo (los plugins cargan gamedata de varias formas) | Arreglado en `build_lite.py`; si vuelve a pasar, revisar cómo lo carga el plugin |
| Un plugin ya compilado falla con "requires a newer Actions" | confirmado | Los `.smx` de otros repos piden extensiones más nuevas | Incluimos Actions 3.9.2 con `get_extensions.py` |
| Los jugadores latinoamericanos ven inglés | confirmado | SourceMod le da a "Spanish - Latin America" el código `las`, sin caer en `es` | `build_lite.py` copia cada traducción `es` a `las` |
| Plugins competitivos dan error por `sv_maxplayers` o Ready-Up | confirmado | Asumen los lugares de l4dtoolz / Ready-Up, que no usamos | Copias parcheadas en `plugins/pause`, `plugins/si_class_announce` |
| "Hordas infinitas" | **sospecha** | `boomer_horde_equalizer_refactored` (apagado desde 2026-10-04), o `l4d2_antibaiter` | El equalizer sigue apagado; timer del antibaiter en 30 s |
| Al caer el jockey, los sobrevivientes quedan aturdidos más de lo esperado | por verificar | Probablemente vanilla (las caídas de jockey/hunter aturden a los que están cerca) | Si no: sospechosos `l4d2_getup_slide_fix`, `l4d2_godframes_control_merge` |
