[English](README.md)

# lef_mode_plugins — Lefordianos Mode Plugins (plugins por modo)

Apaga plugins **mientras un modo de juego está activo**, y los vuelve a prender cuando el servidor sale
de ese modo. Left 4 Dead 2 (en realidad, cualquier juego Source).

Hecho para **mutation19** (Taaannnk!!, lo maneja `lef_tanktime`): ahí todos los infectados son tanks, y
los plugins de versus que eligen quién es el tank, qué clase aparece o si sale tank pelearían con él.

## Config (`addons/sourcemod/configs/lef_mode_plugins.cfg`)

```
"ModePlugins"
{
	"mutation19"
	{
		"off"	"lefordianos/l4d_boss_percent.smx"
		"off"	"lefordianos/witch_and_tankifier.smx"
		...
	}
}
```

La clave es el valor de `mp_gamemode`; cada `"off"` es un archivo dentro de `addons/sourcemod/plugins/`.
Los plugins se apagan en orden **inverso** de la lista y se prenden en el orden de la lista, así que
pon primero los que otros necesitan (`l4d_boss_percent` antes que `l4d2_tankrage`).

Los que se apagan en mutation19, y por qué:

| Plugin | Por qué |
|---|---|
| `l4d_boss_percent`, `witch_and_tankifier`, `lef_boss_spawns` | Deciden dónde y si aparecen el tank y la witch |
| `l4d_tank_control_eq` | Elige quién es el tank |
| `l4d2_fix_spawn_order` | Pone la clase de cada infectado desde su propia cola |
| `l4d2_tank_announce`, `l4d_tank_damage_announce` | Un mensaje por cada tank: spam con 4 tanks todo el tiempo |
| `l4d2_tankrage` | Maneja la furia del tank; Tank!Time! pone su propio tiempo de frustración |
| `l4d2_antibaiter` | Fuerza una horda cuando los infectados esperan |

## Cómo funciona

Cuando cambia `mp_gamemode` y después de las configs de cada mapa, compara la lista del modo actual con
lo que está cargado: `sm plugins unload` para los de la lista que estén cargados, `sm plugins load` para
los que apagó antes y que el modo nuevo no lista. Solo vuelve a cargar lo que apagó él. El log del
servidor dice lo que hizo. `sm_modeplugins` (admins) muestra la lista del modo actual.

Los archivos se reconocen sin importar la barra (`\` en Windows, `/` en Linux).
