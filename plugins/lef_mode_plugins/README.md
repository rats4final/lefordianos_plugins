[Español](README.es.md)

# lef_mode_plugins — Lefordianos Mode Plugins

Turns plugins **off while a game mode is on**, and back on when the server leaves that mode.
Left 4 Dead 2 (any Source game, really).

Made for **mutation19** (Taaannnk!!, run by `lef_tanktime`): there every infected is a tank, and the
versus plugins that pick who gets the tank, which class spawns or whether a tank spawns at all would
fight with it.

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

The key is the `mp_gamemode` value; each `"off"` is a file under `addons/sourcemod/plugins/`.
Plugins are turned off in **reverse** list order and back on in list order, so list first the ones
other plugins depend on (`l4d_boss_percent` before `l4d2_tankrage`).

Turned off in mutation19, and why:

| Plugin | Why |
|---|---|
| `l4d_boss_percent`, `witch_and_tankifier`, `lef_boss_spawns` | Decide where and whether tank and witch spawn |
| `l4d_tank_control_eq` | Picks who gets the tank |
| `l4d2_fix_spawn_order` | Sets each infected's class from its own queue |
| `l4d2_tank_announce`, `l4d_tank_damage_announce` | A message for every tank: spam with 4 tanks all the time |
| `l4d2_tankrage` | Manages the tank's rage; Tank!Time! sets its own frustration time |
| `l4d2_antibaiter` | Forces a horde when infected wait |

## How it works

When `mp_gamemode` changes and after every map's configs, it compares the list for the current mode
with what's loaded: `sm plugins unload` for listed plugins that are loaded, `sm plugins load` for
plugins it turned off earlier that the new mode doesn't list. It only loads back what it turned off
itself. The server log says what it did. `sm_modeplugins` (admins) shows the list for the current mode.

Plugin files are matched whatever the slash (`\` on Windows, `/` on Linux).
