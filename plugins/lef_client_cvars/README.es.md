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

## Todavía no probado en el juego

Compila. Para probar: `mat_fullbright` no se puede poner sin trampas, así que conviene probar con una
cvar de la lista que sí se pueda cambiar en consola, como `cl_bob`; el jugador debería ser expulsado con
un mensaje claro.
