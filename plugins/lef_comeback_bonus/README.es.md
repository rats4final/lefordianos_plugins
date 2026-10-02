[English](README.md)

# lef_comeback_bonus — Lefordianos Comeback Bonus (bono de remontada)

Le da al equipo que va perdiendo una oportunidad justa de remontar en el versus vanilla. Left 4 Dead 2,
solo versus.

## Cómo funciona

1. **Al empezar cada mapa** mira los puntajes totales. Si un equipo va perdiendo por al menos **100**
   puntos (`lef_comeback_min_gap`), el bono se activa para ese equipo en este mapa.
2. **Durante la mitad en que ese equipo juega de supervivientes**, gana un **15%** extra
   (`lef_comeback_percent`) de los puntos de distancia que recorre.
3. **Con límite en la diferencia** (`lef_comeback_cap_to_gap`): el bono los ayuda a alcanzar, pero el
   bono solo nunca los pone adelante.

Como es un porcentaje de la distancia que *realmente* recorren, el equipo que pierde igual tiene que
jugar bien. Morir al 10% significa el 15% de muy poco.

**Ejemplo.** Después del mapa 1 el puntaje es 400–40 (diferencia 360). El mapa 2 vale 500. El equipo
que pierde llega al cuarto seguro: 500 de distancia + 75 de bono = 575. El equipo que gana también
llega: 500. La diferencia baja de 360 a 285.

## Qué ven los jugadores

> [Remontada] El otro equipo va perdiendo por **360**: como supervivientes en este mapa ganan **+15%** de su distancia.

(cuando los supervivientes salen del cuarto seguro, si el bono está activo) y después de su mitad:

> [Remontada] **+75** de bono de remontada para el otro equipo.

`!comeback` muestra si está activo en este mapa.

## Requisitos

- [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696)
- **`l4d2_penalty_bonus`** del repo competitivo (`addons/sourcemod/plugins/optional/`). Suma los puntos
  convirtiendo la penalidad del desfibrilador del juego en un bono, así aparecen en el marcador normal
  y cuentan aunque el equipo muera. Nuestro plugin no carga sin él.

## Configuración (`cfg/sourcemod/lef_comeback_bonus.cfg`)

| Cvar | Por defecto | Significado |
|---|---|---|
| `lef_comeback_enable` | `1` | Activado/desactivado. |
| `lef_comeback_percent` | `15` | Bono como % de los puntos de distancia que recorre el equipo que pierde. |
| `lef_comeback_min_gap` | `100` | Solo se activa cuando un equipo va perdiendo por al menos esto al empezar el mapa. |
| `lef_comeback_cap_to_gap` | `1` | Nunca dar más que la diferencia. |

## Cómo se mide la distancia

El bono se calcula justo antes de que el juego cuente la mitad, a partir del progreso de cada
superviviente según el propio juego (el valor con el que puntúa): el valor del mapa × el progreso
promedio del equipo. Es una **estimación** de los puntos de distancia: el bono puede diferir en un
punto o dos del 15% exacto, pero el número anunciado siempre es el número que se suma.

## Todavía no probado en el juego

Compila. Cosas para revisar: que el bono aparezca en el marcador de fin de ronda, que vaya al equipo
correcto en ambas mitades, y que nunca sea más que la diferencia.
