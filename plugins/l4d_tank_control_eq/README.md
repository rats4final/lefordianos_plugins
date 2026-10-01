# l4d_tank_control_eq (patched: no Ready-Up needed)

**L4D2 Tank Control** by arti, with contributions by Sheo, Sir and Altair-Sossai, from
L4D2-Competitive-Rework (`addons/sourcemod/scripting/l4d_tank_control_eq.sp`, version 0.0.29,
upstream commit `dac2c41f`).

## What it does

Gives the tank to every infected player in turn, so nobody gets it twice before everyone has had
it once. When a tank is passed to the AI, it goes back to the next player in line instead.

- `!tank` / `!boss` / `!witch`: who's getting the next tank (infected only by default).
- Admins: `sm_givetank <player>`, `sm_tankshuffle` (re-pick at random).
- `tankcontrol_print_all 1` lets everyone see who's next.

## Our change

The original includes `readyup.inc`, which makes the Ready-Up plugin a **hard requirement**: it
won't load without it. But the plugin never calls a single Ready-Up function. We removed that one
`#include`, so it runs on a server without Ready-Up. Nothing else is changed; the version is
marked `0.0.29-lef1`.

The file name is unchanged on purpose: it's a drop-in replacement, and other plugins that look
for it by name still find it.

When upstream updates, re-copy their file and remove the `#include <readyup>` line again.
