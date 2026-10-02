[Español](README.es.md)

# lef_bot_protect — Lefordianos Bot Protect

When there aren't enough players, survivor bots fill the empty spots, and infected players tend to
focus them because bots are easy targets. This takes a **small share** off the damage infected
**players** deal to survivor bots (default **15%**), so a bot isn't a free kill. Humans play exactly
as in vanilla. Left 4 Dead 2.

- Only damage from infected players (specials, tank, spit). Common infected, falls, fire and
  teammates are untouched.
- Only in versus and scavenge by default (`lef_bot_protect_versus_only`).
- Small hits like spit ticks keep their leftover fraction for the bot's next hit, so the total is
  exactly the configured share.

| Cvar | Default | What it does |
|---|---|---|
| `lef_bot_damage_reduction` | 15 | Percent less damage for survivor bots. 0 = off (vanilla) |
| `lef_bot_protect_versus_only` | 1 | Only when players control the infected |

This is a small balance change, chosen on purpose (2026-10-02). Set it to 0 for pure vanilla.

Needs [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696).
