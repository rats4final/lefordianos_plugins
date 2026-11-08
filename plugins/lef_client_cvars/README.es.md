[English](README.md)

# lef_client_cvars — Lefordianos Client Cvars (cvars de cliente)

Revisa los ajustes del juego de cada jugador (cvars de cliente) y expulsa a quien use un valor que da
ventaja injusta: brillo total (`mat_fullbright`), sin niebla (`fog_*`), una linterna más grande o más
brillante (`cl_survivor_light_*`), ver a través de objetos, etc. Left 4 Dead 2.

Es una versión independiente del módulo **ClientSettings** de confogl (Confogl Team), así que funciona
**sin confogl**. Revisa **las mismas 59 cvars** que ZoneMod (el `cfg/cvar_tracking.cfg` del repo
competitivo), listadas en nuestro `cfg/lefordianos/client_cvars.cfg`.

Espiar en tercera persona es otra revisión, que hace el `l4d_thirdpersonshoulderblock` del repo
competitivo (también está en la config lite). SMAC y Little Anti-Cheat revisan otras cvars (wireframe,
`r_drawothermodels`...); juntos se cubren entre sí.

## Cómo funciona

Cada 5 segundos le pregunta a cada jugador por cada cvar de la lista:

- **Valor fuera de lo permitido:** se lo expulsa, con la cvar y el valor permitido en el mensaje de
  expulsión, así un jugador honesto puede corregirlo y volver. El chat dice quién y por qué; el log del
  servidor también.
- **El juego se niega a informar la cvar** (protegida o faltante, normalmente una trampa): también se
  lo expulsa, salvo que `lef_clientcvars_kick_missing 0`.

## La lista

`cfg/lefordianos/client_cvars.cfg`, una línea por cvar:

```
lef_trackclientcvar <cvar> <hasMin> <min> <hasMax> <max> [<acción: 0 expulsar, 1 solo registrar>]
```

El archivo empieza con `lef_resetclientcvars`, y `common.cfg` lo ejecuta en cada mapa. `!clientcvars`
muestra qué se revisa. El nombre del comando es distinto al de confogl (`confogl_trackclientcvar`) a
propósito, para que los dos puedan estar cargados sin chocar.

## Configuración (`cfg/sourcemod/lef_client_cvars.cfg`)

| Cvar | Por defecto | Significado |
|---|---|---|
| `lef_clientcvars_enable` | `1` | Activado/desactivado. |
| `lef_clientcvars_interval` | `5.0` | Segundos entre revisiones. |
| `lef_clientcvars_kick_missing` | `1` | Expulsar cuando el juego se niega a informar una cvar. |

## Mensaje propio para una cvar

Agrega `"Kicked Value <cvar>"` (chat) y/o `"Kick Reason Value <cvar>"` (pantalla de expulsión) en
`translations/lef_client_cvars.phrases.txt` (y `es/`), con los mismos argumentos que las frases generales
(nombre/cvar/valor, cvar/valor/permitido). `mat_fullbright` tiene uno: dice que eso es trampa y cómo volver.

## En uso

En el servidor del dueño desde el 2026-10-03. Expulsiones hasta ahora (al 2026-11-08): `mat_fullbright`
10, `cl_survivor_light_enable 0` 5, `r_flashlightmuzzleflash 0` 2, `cl_max_shadow_renderable_dist 0` 2,
`sv_consistency 0` 1. Hasta la 1.1.0 el mensaje de expulsión decía "permitido: g" en vez del valor
(SourceMod no tiene `%g`).

La tercera persona (`c_thirdpersonshoulder`) es otro plugin, `l4d_thirdpersonshoulderblock`: manda al
jugador a espectadores (`l4d_tpsblock_action 1`); nuestra copia parchada le dice por qué y cómo volver.
