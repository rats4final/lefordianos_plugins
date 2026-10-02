[English](README.md)

# lef_t1_mode — Lefordianos T1 Mode (modo solo T1)

Un modo "solo armas T1" que se puede prender y apagar. Funciona con o sin confogl. Left 4 Dead 2.

## Qué se reemplaza

Se define en `addons/sourcemod/configs/lef_t1_mode.cfg` (una lista `"prohibida" "reemplazo"`;
`"none"` quita el arma). Por defecto:

| Prohibida | Pasa a ser |
|---|---|
| M16, rifle Desert | SMG |
| AK-47, SG552 | SMG con silenciador |
| Escopeta automática / SPAS | Escopeta de bomba / Chrome |
| Hunting rifle (15 balas), francotirador militar (30 balas) | Scout |

Permitidas: armas T1, pistolas, cuerpo a cuerpo, **Scout, AWP, lanzagranadas, M60**. El archivo trae
líneas comentadas para prohibir también el AWP, el lanzagranadas o la M60. Después de editar, `sm_t1_reload`.

Con el modo activo convierte las armas del mapa al empezar la ronda, las que aparecen después, y
cualquier arma prohibida que un superviviente agarre o traiga del mapa anterior.

## Cómo prenderlo y apagarlo

| Cómo | Comando |
|---|---|
| Cvar | `lef_t1_enable 1` / `0` |
| Admin | `sm_forcet1 on` / `off` (permiso de admin genérico, `b`) |
| Jugadores | `!t1` inicia una votación Sí/No en la pantalla de votación del juego (necesita la extensión builtinvotes) |

Si los supervivientes todavía están en el refugio inicial se aplica en el momento; si no, desde la
próxima ronda. Cuando salen del refugio con el modo activo, el chat dice "Solo armas T1 esta ronda".

Lo elegido por votación (`!t1`) o por un admin (`sm_forcet1`) dura toda la sesión: los cambios de mapa
vuelven a ejecutar las configs, que lo apagarían, así que se vuelve a aplicar después de ellas. Cuando el
servidor se vacía, vuelve al `lef_t1_enable` de las configs.

## Configuración (`cfg/sourcemod/lef_t1_mode.cfg`)

| Cvar | Por defecto | Significado |
|---|---|---|
| `lef_t1_enable` | `0` | El modo en sí. |
| `lef_t1_convert_held` | `1` | También reemplazar las armas prohibidas que se agarran o se traen del mapa anterior. |
| `lef_t1_vote_time` | `20` | Segundos que dura la votación `!t1`. |

## Cómo funciona

Usa las mismas funciones de armas que el `l4d2_weaponrules` del repo competitivo (de l4d2util), pero
con su propia lista, así nunca borra las reglas de armas de otro modo. El Scout y el AWP son armas de
CS:S; igual que `l4d2_sniper_precache`, las precarga en cada mapa para que convertir a ellas no crashee.

## Todavía no probado en el juego

Compila. Revisar: que las armas se conviertan al empezar la ronda, que un arma traída del mapa
anterior se cambie, que la votación `!t1` funcione, y que el Scout aparezca en mapas sin armas de CS.
