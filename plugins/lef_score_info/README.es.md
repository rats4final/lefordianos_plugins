[English](README.md)

# lef_score_info — Lefordianos Score Info (información de puntaje)

Explica los puntajes del versus vanilla para que un mal mapa no se sienta perdido. **No cambia ningún
punto.** Left 4 Dead 2, solo versus.

## Qué ven los jugadores

**Cuando los supervivientes salen del cuarto seguro**
> [Puntos] Este mapa vale **500** puntos. Diferencia: **300** (60% de este mapa).

**Después de la primera mitad** (desde el punto de vista de cada jugador)
> [Puntos] Tu equipo hizo **420** de 500 en este mapa.
> [Puntos] El otro equipo necesita **421** (85% del mapa) para ganar este mapa.
> [Puntos] El otro equipo necesita **121** (25% del mapa) para pasar adelante en el total.

**Después del mapa**
> [Puntos] Tu equipo ganó este mapa, **420** a **380**.
> [Puntos] Tu equipo: **1200** pts, **2** mapas ganados | El otro equipo: **900** pts, **1** mapas ganados

`!score` muestra la tabla y cuánto vale este mapa en cualquier momento.

Los mensajes dicen "tu equipo" / "el otro equipo" a los jugadores y "los supervivientes" / "los
infectados" a los espectadores, porque el "Equipo A / Equipo B" interno del juego no le dice nada a
nadie.

## Mapas ganados

Se cuentan por mapa comparando el puntaje de ambos equipos en ese mapa, se mantienen durante toda la
campaña y se reinician cuando empieza una campaña nueva. Es para presumir y para el ánimo: una paliza
cuenta como **un** mapa perdido. El juego sigue decidiendo el ganador por puntos totales.

## Configuración (`cfg/sourcemod/lef_score_info.cfg`)

| Cvar | Por defecto | Significado |
|---|---|---|
| `lef_score_info_delay` | `5.0` | Segundos después de terminar una mitad antes de mostrar los mensajes (deja que el marcador se acomode). |

## Créditos y diferencias

Idea del `l4d2_score_difference` de MoYu (Forgetest, vikingo12). Ese plugin predice cuánto vale el
*próximo* mapa, para lo que necesita el Info Editor de Silvers; este anuncia cuánto vale cada mapa
cuando empieza, así que solo necesita Left4DHooks. No usen los dos a la vez: muestran líneas parecidas.

## Todavía no probado en el juego

Compila. Cosas para revisar: que "tu equipo / el otro equipo" sea correcto en ambas mitades (el juego
cambia de lado entre mitades), y que el conteo de mapas ganados se reinicie en una campaña nueva.
