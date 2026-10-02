[English](README.md)

# lef_bot_protect — Lefordianos Bot Protect (proteger bots)

Cuando no hay suficientes jugadores, los bots sobrevivientes ocupan los lugares vacíos, y los infectados
suelen hacerles focus porque son blancos fáciles. Esto le quita una **pequeña parte** al daño que los
**jugadores** infectados le hacen a los bots sobrevivientes (**15%** por defecto), para que un bot no sea
una muerte gratis. Los humanos juegan exactamente como en vanilla. Left 4 Dead 2.

- Solo el daño de jugadores infectados (especiales, tank, escupida). Los infectados comunes, las caídas,
  el fuego y los compañeros no cambian.
- Solo en versus y scavenge por defecto (`lef_bot_protect_versus_only`).
- Los golpes chicos como los ticks de escupida guardan la fracción que sobra para el siguiente golpe del
  bot, así el total es exactamente el porcentaje configurado.

| Cvar | Por defecto | Qué hace |
|---|---|---|
| `lef_bot_damage_reduction` | 15 | Porcentaje menos de daño para los bots sobrevivientes. 0 = apagado (vanilla) |
| `lef_bot_protect_versus_only` | 1 | Solo cuando los jugadores controlan a los infectados |

Es un cambio de balance chico, elegido a propósito (2026-10-02). Con 0 queda vanilla puro.

Necesita [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696).
