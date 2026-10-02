[English](README.md)

# l4d_tank_control_eq (parchado: no necesita Ready-Up)

**L4D2 Tank Control** de arti, con aportes de Sheo, Sir y Altair-Sossai, de L4D2-Competitive-Rework
(`addons/sourcemod/scripting/l4d_tank_control_eq.sp`, versión 0.0.29, commit de origen `dac2c41f`).

## Qué hace

Le da el tank a cada jugador infectado por turno, así nadie lo tiene dos veces antes de que todos lo
hayan tenido una. Cuando el tank pasa a la IA, vuelve al siguiente jugador en la fila.

- `!tank` / `!boss` / `!witch`: quién recibe el próximo tank (por defecto solo lo ven los infectados).
- Admins: `sm_givetank <jugador>`, `sm_tankshuffle` (vuelve a elegir al azar).
- `tankcontrol_print_all 1` deja que todos vean quién sigue.

## Nuestro cambio

El original incluye `readyup.inc`, lo que convierte al plugin Ready-Up en un **requisito obligatorio**:
no carga sin él. Pero el plugin nunca usa ni una sola función de Ready-Up. Quitamos ese único
`#include`, así funciona en un servidor sin Ready-Up. No se cambió nada más; la versión queda marcada
como `0.0.29-lef1`.

El nombre del archivo no cambia a propósito: es un reemplazo directo, y los otros plugins que lo
buscan por nombre lo siguen encontrando.

Cuando el original se actualice, vuelvan a copiar su archivo y quiten otra vez la línea `#include <readyup>`.
