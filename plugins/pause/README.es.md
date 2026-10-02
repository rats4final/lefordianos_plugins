[English](README.md)

# pause (parchado)

**Pause plugin** de CanadaRox, Sir, Forgetest y A1m`, del repo L4D2-Competitive-Rework
(`addons/sourcemod/scripting/pause.sp`, versión 6.9.0, commit `f8df6a13`).

`!pause` pausa la partida; los dos equipos escriben `!ready` para quitar la pausa; los admins tienen
`sm_forcepause` / `sm_forceunpause`. Con `lef_votes`, los jugadores solo pueden pausar por votación.

## Nuestro cambio (6.9.0-lef1)

Durante la pausa, el panel mostraba "jugadores / máximo" usando `sv_maxplayers`, una cvar que solo existe
con l4dtoolz instalado. Sin l4dtoolz tiraba "Invalid convar handle" cada segundo. Ahora usa
`sv_maxplayers` si existe y, si no, el máximo propio del juego. Nada más cambió.
