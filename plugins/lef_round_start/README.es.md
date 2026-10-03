[English](README.md)

# lef_round_start — Lefordianos Round Start (inicio de ronda)

Los momentos antes de que los sobrevivientes salgan del refugio, **sin Ready-Up**: nadie tiene que
apretar F1 ni escribir `!ready`. Left 4 Dead 2.

## Panel de inicio

Un panel chico con **dónde sale el tank y la witch** en este mapa, las **clases iniciales del equipo
infectado**, qué mitad de la ronda es, cuántos humanos tiene cada equipo y los comandos que conviene
saber. Desaparece `lef_start_panel_after_leave` segundos (15) después de que los sobrevivientes salen del
refugio, con el primer golpe de un infectado a un sobreviviente, después de `lef_start_panel_time`
segundos (60), o cuando el jugador aprieta **0**. Se hace a un lado si se abre otro menú.

## Esperar a un amigo (`!wait`)

En versus, que un sobreviviente salga del refugio empieza la ronda para todos. Cuando un amigo todavía
se está conectando:

1. Alguien escribe `!wait` (también está en `!menu`) y elige a cuántos jugadores esperar (1 a 4).
2. Una votación Sí/No pregunta "¿Esperar a 1 jugador más antes de salir del refugio?".
3. Si pasa, **nadie puede salir del refugio**: quien lo intenta vuelve adentro. Una cuenta regresiva se
   muestra en el cuadro de avisos.
4. La espera termina (después de una cuenta regresiva 3-2-1) cuando entran esos jugadores a los equipos, cuando se acaba el tiempo
   (`lef_start_wait_time`, 90 s), o cuando pasa una votación de `!go` (los admins: al instante).
   `!extend` vota más tiempo (`lef_start_extend_time`, hasta `lef_start_max_extends` veces).

Escribir `+1`, `+2`... en el chat (nuestra costumbre) **no** inicia una votación por sí solo, así nadie
se encuentra con una votación sorpresa: ese jugador solo recibe un consejo privado sobre `!wait`. Con
`lef_start_chat_trigger 2`, `+N` inicia la votación directo; con `0`, no hay consejo.

Después, `lef_teams_panel` le dice al que entra a qué equipo unirse para emparejar.

## Ajustes

| Cvar | Por defecto | Qué hace |
|---|---|---|
| `lef_start_panel` | 1 | Mostrar el panel de inicio |
| `lef_start_panel_time` | 60 | Esconderlo después de estos segundos como máximo |
| `lef_start_panel_after_leave` | 15 | Segundos que se queda después de que los sobrevivientes salen del refugio |
| `lef_start_wait_time` | 90 | Segundos de espera cuando pasa una votación de `!wait` |
| `lef_start_extend_time` | 60 | Segundos que agrega una votación de `!extend` |
| `lef_start_max_extends` | 2 | Alargues por ronda |
| `lef_start_chat_trigger` | 1 | `+1` en el chat: 0 = nada, 1 = consejo privado, 2 = iniciar la votación |
| `lef_start_countdown` | 3 | Segundos de cuenta regresiva 3-2-1 (con los pitidos de Ready-Up) antes de terminar la espera. 0 = nada |
| `lef_start_freeze` | 1 | Congelar a los sobrevivientes mientras se espera: 0 = nunca, 1 = solo en el primer mapa de una campaña (no hay refugio que los retenga), 2 = siempre |

## Ready-Up

Si Ready-Up está cargado, este plugin se hace a un lado: Ready-Up ya retiene el inicio y tiene su propio
panel. Retener el refugio usa el mismo método que Ready-Up (`warp_to_start_area`).

## Necesita

[Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696) y la extensión BuiltinVotes.
