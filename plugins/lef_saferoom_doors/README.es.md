[English](README.md)

# lef_saferoom_doors — Lefordianos Saferoom Doors (puertas del refugio)

Avisa a todos quién usa las puertas del refugio. Left 4 Dead 2.

| Puerta | Qué se anuncia |
|---|---|
| Refugio inicial | "X abrió la puerta del refugio." una vez por ronda, o "La puerta del refugio se abrió sola." |
| Refugio final | Por defecto solo "X cerró la puerta del refugio final con 2 compañero(s) todavía afuera." Con `lef_doors_end 2`, cada vez que se abre o cierra. |

Las aperturas de la puerta inicial y los "cerró con compañeros afuera" también quedan en el log del
servidor, así los admins pueden revisar después quién le cerró la puerta al equipo.

## Configuración (`cfg/sourcemod/lef_saferoom_doors.cfg`)

| Cvar | Por defecto | Significado |
|---|---|---|
| `lef_doors_start` | `1` | Anunciar quién abre la puerta del refugio inicial. |
| `lef_doors_end` | `1` | Puerta final: 0 = nada, 1 = solo si la cierran con compañeros afuera, 2 = cada apertura/cierre. |
| `lef_doors_cooldown` | `3.0` | Segundos entre mensajes del mismo jugador (evita el spam de abrir y cerrar). |

Necesita [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696), que distingue la
puerta inicial de la final.

## Todavía no probado en el juego

Compila. Revisar: que el mensaje inicial salga una sola vez por ronda, el caso "se abrió sola", y que
un compañero afuera (vivo o caído) se cuente cuando cierran la puerta final.
