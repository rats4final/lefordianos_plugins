[Español](README.es.md)

# l4d2_tank_horde_monitor (patched: on/off switch and rule reminder)

**L4D2 Tank Horde Monitor** by Derpduck, based on Visor's `l4d2_horde_equaliser`, from
L4D2-Competitive-Rework (version 1.3.1).

## What it does

During **infinite-horde events** (crescendos, gauntlets), when a tank appears the horde **pauses**,
so the survivors fight the tank, not tank + endless horde. If the survivors push ahead to skip the
tank, the horde comes back, stronger the further they push, up to full strength. Chat explains it
when it happens: "Horde has paused due to tank in play! Progressing by 12.5% will start the horde",
then the percent left, then the strength. It works on its own; confogl isn't needed.

## Our change

Random players don't know the rule and tend to rush, so:

- **On/off switch:** `l4d2_tank_horde_monitor_enable` (default `1`). With `0` the game behaves as
  vanilla (the horde keeps coming during the tank). Takes effect from the next tank.
- **Rule reminder:** `l4d2_tank_horde_monitor_hint` (default `1`). While the plugin is on, once per
  round when survivors leave the saferoom: "Rule: if a tank appears during a horde event, the horde
  pauses. Pushing ahead to skip the tank brings it back, stronger the further you go."
  (English and Spanish, in our own `lef_tank_horde_monitor.phrases.txt` so the original file isn't touched.)

Nothing else changed; the version is `1.3.1-lef1`. Same file name, so it's a drop-in replacement.
A vote to switch it on/off is planned for our `!votes` menu.

Needs Left4DHooks and the competitive repo's `l4d2_zombiemanager.txt` gamedata (Windows and Linux).
