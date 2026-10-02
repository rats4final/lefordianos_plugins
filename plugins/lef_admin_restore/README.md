[Español](README.es.md)

# lef_admin_restore — Lefordianos Admin Restore

**Undo griefing.** When someone shoots, burns, incaps or kills a teammate, an admin can give the
victim back exactly what was taken. An improvement on Harry Potter's `admin_hp`, whose `!hp` only
heals every survivor to full. Left 4 Dead 2.

## Commands (admins only, see Access below)

| Command | What it does |
|---|---|
| `!heal <player>` / `!heal @survivors` | Full heal, like a medkit: revives if down, full HP, no more black-and-white. No argument opens a menu. |
| `!restore <player>` | Gives back what *teammates* took (see below). No argument opens a menu listing who has something to undo. |
| `!teamdamage` | Lists team damage that can be undone, e.g. `Nick: 45 HP, 1 incap(s), items (Troll)`. |

Both menus are also in `!admin` → **Player Commands**: "Heal survivors" and "Undo team damage".

## What `!restore` gives back

For each survivor the plugin quietly keeps a record of what teammates (human or bot) did to them.
On the **first** hit from a teammate it takes a snapshot of their health, incap count and items;
after that it adds up the team damage, incaps and a team kill.

`!restore` then:

| What happened | What they get back |
|---|---|
| Teammates did 45 damage | +45 HP (up to max) |
| A teammate incapped them, they got revived | The incap is taken off their count, so no black-and-white from it |
| They're down right now from a teammate | Revived, and back to the health/incap count they had before |
| A teammate killed them | **Respawned next to a teammate** (not the attacker, if possible), with the health and incap count they had before |
| Items: main gun, pistol(s)/melee, throwable, medkit/defib/upgrade, pills/adrenaline | Any slot that's now **empty** gets back what they had. After a respawn, everything is replaced. Ammo isn't tracked. |

Damage from the infected is **not** undone. Only what teammates did is.

The record is forgotten after **5 minutes** without team damage, at round start, when the player
changes team, or after a restore.

## Heads-up for admins

Admins (anyone with access) get a chat message when:

- a player has done **25+** team damage to a teammate (`lef_restore_notify_damage`),
- a player incaps a teammate,
- a player kills a teammate.

> [Restore] Troll did 60 team damage to Nick. !restore to undo.

Bots' accidental team damage is recorded, so it can be undone, but doesn't trigger messages.

## Access

`lef_restore_access` sets the admin flags needed. The default is `z` (root only). Any one of the
listed flags is enough, e.g. `"cz"` for kick *or* root. The override name `lef_admin_restore`
also works in `admin_overrides.cfg`.

## Settings (`cfg/sourcemod/lef_admin_restore.cfg`)

| Cvar | Default | Meaning |
|---|---|---|
| `lef_restore_access` | `z` | Admin flags needed. |
| `lef_restore_memory` | `300` | Seconds after the last team hit that it can still be undone. |
| `lef_restore_notify_damage` | `25` | Team damage that triggers an admin heads-up (0 = only incaps/kills). |

## Works with

- [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696) (required): revive and respawn.
- Harry Potter's `l4d_heartbeat` (optional): if loaded, incap counts are set through it so the two
  don't fight over black-and-white state.

## Not tested in-game yet

Compiles. Things to check: a team kill → `!restore` respawns them next to the team with their items;
an incap by a teammate → `!restore` revives them at their old health; melee and dual pistols come
back correctly; the heartbeat sound stops when black-and-white is undone.
