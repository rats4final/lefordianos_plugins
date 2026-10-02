[English](README.md)

# Plugins de otros autores

Código original de plugins de otros autores de AlliedModders, guardado **sin cambios** como
referencia. Una carpeta por autor, y dentro una carpeta por plugin.

Cuando reescribimos o mejoramos uno de estos, la versión nueva va en [`plugins/`](../plugins/) y el
original se queda aquí, para poder compararlos siempre.

| Autor | Plugin | Fuente | Nuestra versión |
|---|---|---|---|
| -=BwA=- Jester | `l4d2_bwa_teamspanel` (Players Panel and Switch Menu 1.2.2) | Foros de AlliedModders | [`lef_teams_panel`](../plugins/lef_teams_panel/README.es.md) |
| Mart | Throwable / Explosion announcers, Upgrade pack announce, Scripted HUD | AlliedModders | — |
| NoroHime | `l4d_announce_healer` | AlliedModders | — |
| SilverShot | `l4d_fire_glow`, `l4d_pipebomb_ignore` | AlliedModders | — |
| Buster "Mr. Zero" Nielsen; fork de cravenge y Dragokas | `sceneprocessor` 1.33.3 (lo necesita el `l4d2_survivor_mourn_fix` de Harry; copia del repo Rotoblin-AZMod de Harry Potter) | [AlliedModders t=241585](https://forums.alliedmods.net/showthread.php?t=241585) | — |
| pan0s | `l4d2_menu`, `l4d2_srs` (contenido de los zip, sin binarios compilados) | AlliedModders | — |

Las versiones y enlaces al foro de cada uno están en [CREDITS.es.md](../CREDITS.es.md). No se guardan archivos compilados (`.smx`, `.so`, `.dll`).

Para agregar uno: crea `alliedmodders/<Autor>/<plugin>/`, pon el `.sp` (más los archivos de gamedata
o traducciones que tenga) adentro, y agrega una fila arriba con el enlace al foro.
