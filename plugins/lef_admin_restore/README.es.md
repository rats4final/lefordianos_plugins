[English](README.md)

# lef_admin_restore — Lefordianos Admin Restore (restaurar por admin)

**Deshacer el griefing.** Cuando alguien le dispara, quema, derriba o mata a un compañero, un admin
puede devolverle a la víctima exactamente lo que le quitaron. Una mejora del `admin_hp` de Harry
Potter, cuyo `!hp` solo cura a todos los supervivientes al máximo. Left 4 Dead 2.

## Comandos (solo admins, ver Acceso abajo)

| Comando | Qué hace |
|---|---|
| `!heal <jugador>` / `!heal @survivors` | Curación completa, como un botiquín: levanta si está caído, vida al máximo, sin blanco y negro. Sin argumento abre un menú. |
| `!restore <jugador>` | Devuelve lo que le quitaron sus *compañeros* (ver abajo). Sin argumento abre un menú con quién tiene algo para deshacer. |
| `!teamdamage` | Lista el daño de equipo que se puede deshacer, por ejemplo `Nick: 45 HP, 1 derribo(s), objetos (Troll)`. |

Ambos menús también están en `!admin` → **Player Commands** (Comandos de jugador): "Curar
supervivientes" y "Deshacer daño de equipo".

## Qué devuelve `!restore`

Para cada superviviente el plugin anota en silencio lo que le hicieron sus compañeros (humanos o
bots). Con el **primer** golpe de un compañero toma una foto de su vida, su conteo de derribos y sus
objetos; después va sumando el daño de equipo, los derribos y una posible muerte por un compañero.

`!restore` entonces:

| Qué pasó | Qué recupera |
|---|---|
| Los compañeros le hicieron 45 de daño | +45 de vida (hasta el máximo) |
| Un compañero lo derribó y lo levantaron | Se le descuenta ese derribo, así no queda en blanco y negro por eso |
| Está caído ahora mismo por un compañero | Lo levanta, y vuelve a la vida/derribos que tenía antes |
| Un compañero lo mató | **Lo revive junto a un compañero** (que no sea el atacante, si se puede), con la vida y los derribos que tenía antes |
| Objetos: arma principal, pistola(s)/cuerpo a cuerpo, arrojable, botiquín/desfibrilador/mejora, pastillas/adrenalina | Cada espacio que ahora está **vacío** recupera lo que tenía. Después de revivir, se reemplaza todo. La munición no se guarda. |

El daño de los infectados **no** se deshace. Solo lo que hicieron los compañeros.

El registro se olvida después de **5 minutos** sin daño de equipo, al empezar la ronda, cuando el
jugador cambia de equipo, o después de restaurar.

## Avisos para los admins

Los admins (quien tenga acceso) reciben un mensaje en el chat cuando:

- un jugador le hizo **25+** de daño de equipo a un compañero (`lef_restore_notify_damage`),
- un jugador derriba a un compañero,
- un jugador mata a un compañero.

> [Restaurar] Troll le hizo 60 de daño de equipo a Nick. !restore para deshacer.

El daño accidental de los bots se registra, así se puede deshacer, pero no genera mensajes.

## Acceso

`lef_restore_access` define los permisos de admin necesarios. Por defecto es `z` (solo root). Con
cualquiera de los permisos listados alcanza, por ejemplo `"cz"` para kick *o* root. El nombre de
override `lef_admin_restore` también funciona en `admin_overrides.cfg`.

## Configuración (`cfg/sourcemod/lef_admin_restore.cfg`)

| Cvar | Por defecto | Significado |
|---|---|---|
| `lef_restore_access` | `z` | Permisos de admin necesarios. |
| `lef_restore_memory` | `300` | Segundos después del último golpe de un compañero en que todavía se puede deshacer. |
| `lef_restore_notify_damage` | `25` | Daño de equipo que dispara un aviso a los admins (0 = solo derribos/muertes). |

## Funciona con

- [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696) (necesario): levantar y revivir.
- `l4d_heartbeat` de Silvers/Harry Potter (opcional): si está cargado, los derribos se ajustan a
  través de él para que los dos no se peleen por el estado de blanco y negro.

## Todavía no probado en el juego

Compila. Cosas para revisar: muerte por un compañero → `!restore` lo revive junto al equipo con sus
objetos; derribo por un compañero → `!restore` lo levanta con su vida de antes; las armas cuerpo a
cuerpo y las pistolas dobles vuelven bien; el sonido del latido se detiene cuando se deshace el
blanco y negro.
