[English](README.md)

# lef_teams_panel — Lefordianos Teams Panel (panel de equipos)

Una reescritura del **"Jesters Players Panel and Switch Menu"** de -=BwA=- Jester (el original está en
[`alliedmodders/BwA-Jester/`](../../alliedmodders/BwA-Jester/)). Solo Left 4 Dead 2.

## Qué hace

**Para todos**

| Comando | Qué pasa |
|---|---|
| `!teams` | Panel con espectadores, supervivientes e infectados. Presiona **1/2/3** para unirte a ese equipo. |
| `!lastteams` | Muestra cómo estaban los equipos al final de la última ronda (marca a quien no está). |
| `!swapwith [jugador]` | Le pide a un jugador de otro equipo que cambie de lugar contigo. Le aparece un menú Sí/No. |

El panel muestra a los supervivientes muertos/caídos/ausentes, y a los bots como lugares libres. Las
clases de los infectados **solo las ven los infectados y los espectadores**, así los supervivientes
no se enteran de qué les viene.

**Para admins** (permiso de kick, `c`): una categoría **"Gestión de equipos"** en `!admin`:

| Opción del menú | Comando |
|---|---|
| Ver equipos | `sm_teams` |
| Mover a un jugador de equipo | `sm_moveplayer <jugador> <spec\|surv\|inf>` |
| Intercambiar dos jugadores | `sm_swapplayers <jugador1> <jugador2>` |
| Invertir equipos (supervivientes ↔ infectados) | `sm_flipteams` |
| Mezclar equipos al azar | `sm_shuffleteams` |
| Mezcla balanceada (niveles del roster) | `sm_balanceteams` |
| Restaurar los equipos de la última ronda | `sm_restoreteams` |

Invertir, mezclar, balancear y restaurar preguntan "¿estás seguro?" primero en el menú. El acceso se puede
cambiar por comando en `admin_overrides.cfg`.

## Lo que deja a otros plugins (a propósito)

El panel viejo intentaba hacer todo solo. Otros plugins hacen estos trabajos mejor, así que este
trabaja junto a ellos:

| Trabajo | Usar este plugin | Por qué |
|---|---|---|
| Comandos `!spec` / `!survivors` / `!infected` | `l4d_afk_commands` (Harry Potter), o `playermanagement` | Reglas contra abusos: no cambiar de equipo estando atrapado, recargando, cubierto de bilis, justo después de aparecer, etc. |
| Pausar | `pause.smx` (repo competitivo) | Ambos equipos tienen que estar listos para reanudar, y no aparecen SI por culpa de la pausa. |
| Que los espectadores sigan siéndolo al cambiar de mapa | `l4d2_spec_stays_spec` | Dedicado y mantenido. |
| Arreglar equipos que se mezclaron al cambiar de mapa | `l4d2_fix_team_shuffle` | Funciona solo; `!restoreteams` aquí es el botón manual. |

Unirse desde el panel usa el plugin de equipos que esté cargado, así que sus reglas siguen
aplicándose. Si no hay ninguno instalado, el panel usa un cambio de equipo básico propio que respeta
los límites de los equipos y no deja salir a un superviviente atrapado o caído.

## Correcciones respecto al original

- **Restaurar equipos nunca funcionó**: el original nunca guardaba el Steam ID de nadie, así que nunca
  podía reconocer a los jugadores. Además suponía que los equipos siempre cambian de lado entre mapas.
  Esta versión guarda el "equipo A/B de la campaña" y calcula de qué lado juega cada equipo ahora.
- **Se adueñaba del comando `jointeam` del juego**, que usa el menú de equipos de la tecla M.
- **"Los espectadores siguen siéndolo" podía mover a la persona equivocada**: los temporizadores
  guardaban el lugar del jugador, no su ID. (Esta función ahora la hace `l4d2_spec_stays_spec`.)
- **Búsqueda de bots propensa a fallar**: se saltaba el lugar 1 y podía leer más allá del último
  lugar cuando no había ningún bot superviviente.
- **Los títulos del panel estaban al revés** ("Actual" vs "Último mapa").
- **Invertir equipos perdía la cuenta** a mitad del proceso.
- **Los pedidos de cambio se podían contestar tarde**: aceptar un menú viejo después de que los equipos
  cambiaran igual hacía el cambio. Ahora los pedidos vencen y se revisan otra vez antes de mover a nadie.
- **Los menús de admin compartían estado global**: dos admins usando el menú a la vez se pisaban.
- **Tenía su propia gamedata/firmas**: se rompen con las actualizaciones del juego. Ahora usa las
  funciones de Left4DHooks (`L4D_SetHumanSpec`, `L4D_TakeOverBot`), que se mantienen al día.

## Lo que se sacó del original

Pausar/reanudar (usar `pause.smx`), los alias de comandos de equipo (usar `l4d_afk_commands`), la
restauración automática de espectadores (usar `l4d2_spec_stays_spec`) y el menú de registro de depuración.

## Mezcla balanceada y el roster

Las mezclas al azar muchas veces dejan a todos los habituales en un mismo equipo. La mezcla balanceada le
da un nivel a cada jugador y reparte a los jugadores para que los niveles de los dos equipos sumen lo más
parecido posible.

- Nuestros habituales van en `addons/sourcemod/configs/lef_roster.cfg` (cópialo de
  `lef_roster.example.cfg` la primera vez; las actualizaciones solo traen el ejemplo, así tu lista nunca
  se sobrescribe): SteamID (cualquier formato:
  `STEAM_1:…`, `[U:1:…]` o `7656…`), un nombre y un nivel opcional de 1 (nuevo) a 5 (el mejor). El
  archivo explica cómo encontrar un SteamID.
- Quien no está en el roster cuenta como `lef_teams_random_level` (2); un habitual sin nivel cuenta como
  `lef_teams_roster_level` (3). Así, sin poner ningún nivel, los habituales simplemente se reparten parejo.
- Prueba todas las formas de repartir (8 jugadores = 70 repartos parejos). Entre repartos igual de parejos,
  reparte a los habituales por igual y después elige uno al azar, para que el mismo grupo no quede siempre
  con los mismos equipos.
- `sm_roster` muestra el nivel de cada jugador y si está en el roster; `sm_roster_reload` vuelve a leer el
  archivo. También se puede votar desde `!votes` (lef_votes).

## Configuración (`cfg/sourcemod/lef_teams_panel.cfg`, se crea al cargarlo por primera vez)

| Cvar | Por defecto | Significado |
|---|---|---|
| `lef_teams_panel_join` | `1` | Presionar el número de un equipo en `!teams` te une a él. `0` = solo ver. |
| `lef_teams_panel_swap_requests` | `1` | Permitir `!swapwith`. |
| `lef_teams_panel_request_timeout` | `20` | Segundos que un pedido de cambio queda abierto. |
| `lef_teams_panel_request_cooldown` | `15` | Segundos entre pedidos de cambio del mismo jugador. |
| `lef_teams_roster_level` | `3` | Mezcla balanceada: nivel de un habitual sin `"level"`. |
| `lef_teams_random_level` | `2` | Mezcla balanceada: nivel de quien no está en el roster. |

## Requisitos

SourceMod 1.12+, [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696).
Traducciones: inglés y español.

## Todavía no probado en el juego

Compila, pero no se usó en un servidor. Cosas para revisar la primera vez: intercambiar un
superviviente con un infectado a mitad de ronda, invertir equipos con un tank vivo, `!restoreteams`
después de un cambio de mapa, y mezclar con equipos desparejos.
