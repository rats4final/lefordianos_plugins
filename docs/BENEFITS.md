[Español](BENEFITS.es.md)

# What the lite config gives you

A plain overview of what changes on the server and why it's better, grouped by who notices it. Every
plugin, one by one, is in [configs/lite/PLUGINS.md](../configs/lite/PLUGINS.md); what was built when is
in [CHANGELOG.md](../CHANGELOG.md).

The rule behind every choice: **vanilla versus, minus its bugs and annoyances**. The few balance
changes we chose on purpose are listed at the end.

## Fair matches

- **Same tank and witch for both teams** (`lef_boss_spawns`): each map rolls once whether there's a
  tank and/or witch (50% each by default), and the second team gets the same answer **in the same
  spot**. In vanilla one team could get a tank before a drop and the other after it.
- **Everyone knows where they spawn**: the start panel and the chat show "Tank: 63%, Witch: none", so
  the first team isn't surprised by something the second team knows is coming.
- **Same escape route, same alarm cars and same SI first-hit classes for both teams** (fixes from the
  competitive repo).
- **Tank turns in order** (`l4d_tank_control_eq`) and the tank can be passed to a teammate who wants it
  (`l4d_tank_pass`).
- **Even teams**:
  - nobody can join the team that already has more humans;
  - newcomers and spectators are told where they're needed;
  - `!wait` keeps the saferoom closed until a friend joins;
  - a **balanced shuffle** splits our regulars evenly.
- **A ranking** (`!rank`, `!top`) from map wins, which the balanced shuffle uses once players have
  a few maps.
- **Bots aren't free kills**: survivor bots take 15% less damage from infected players.

## Fewer bugs and exploits

About 80 fixes from the competitive repo (ZoneMod's `generalfixes`), Harry Potter, MoYu, Lux and
Silvers. Some players will notice:
- **Shoves, staggers and get-ups** behave consistently: shove direction, stagger direction, Ellis'
  get-up.
- **Infected abilities**: tongues don't break or float; chargers, jockeys and boomers lose a dozen bugs.
- **Tank**: tanks don't freeze; rocks and punches hit what they should; finales don't skip tank stages.
- **Witch**: she keeps the right target and doesn't get stuck.
- **Defibs and items**: defibs don't fail; failed pill passes come back; weapon spawns can't be
  over-looted.
- **Exploits blocked**: rocket jumps, ghost-spawn teleports, damage after switching teams, infinite
  grenades, air revives, the jockey deadstop spam, and others.
- **Server stability**: crash fixes, buffer overflows that silently reset cvars, console spam.

## Information while playing

- `!score` explains the score: what this map is worth, the gap, and what's still possible.
- Tank damage report, survivor MVP and round stats at the end of each round.
- **Who did what**: who threw a molotov or bile, who blew up a gascan, who deployed ammo, who opened
  the saferoom and who closed it on teammates, karma kills.
- **Witch spawns** are announced in chat with their own sound (the witch's tune), different from the tank's.
- **Tank reminders**: while a tank is still to come, chat reminds where it spawns every 2 minutes, and
  warns when survivors are getting close.
- **Skill reports** in chat: skeets, crowns, deadstops, pops, level charges, death charges and more.
- **Who voted**: after every vote, the list of who voted Yes and who voted No.
- **Hints, never punishments**: warnings to rushers, to players left behind and to infected held
  too long, and tips for new tank players.

## Easier for everyone

- **English and Spanish everywhere**: menus and messages follow each player's game language,
  including Steam's "Spanish - Latin America".

- **`!menu`**: every player command in one place, so nobody has to memorise them.
- **`!votes`**: the game's own vote screen for:
  - changing the map, restarting, picking the next campaign;
  - shuffling or balancing teams;
  - kicking a troll (with a 5-minute ban, like vanilla);
  - moving an AFK player, muting someone's voice, chat or both until the round ends;
  - turning T1-only mode or the tank/witch chance up or down;
  - all talk;
  - pausing (only by vote, so randoms can't abuse it).
- **Joining teams**: `!survivors`, `!infected`, `!afk` with sensible anti-abuse rules. Spectators
  stay spectators across maps.
- **No intro cutscenes** on first maps; **campaign rotation**, with the next campaign voted on the
  game's vote screen (`!votes`) and shown with `!next`.
- **Quad caps** are possible (four capping infected at once), like in ZoneMod: a chosen change.
- Pass pills with Reload; hittables glow while a tank is up; dead commons' ragdolls disappear.

## For admins

- **`!admin`** gets:
  - *Team Management*: move, swap, flip, shuffle, balanced shuffle, restore last round's teams;
  - *Lefordianos*: run any vote option instantly, force pause/unpause, pass or cancel a vote.
- **`!heal` / `!restore`** undo griefing: team damage, incaps, team kills and lost items.
- Per-game-mode settings in plain files (`cfg/sourcemod/gamemode_cvars/<mode>.cfg`), without confogl.
- Server messages and connect messages, with translations.

## Anti-cheat

- **SMAC** and **Little Anti-Cheat** (Little Anti-Cheat logs only at first).
- **Client settings**: checks for the 59 client settings ZoneMod checks (full brightness, no fog,
  flashlight tweaks...).
- **Peeking and wallhacks**: blocks third-person peeking and the "mat_hack" wallhack, and hides ghost
  infected from wallhacks.
- **Lerp and rate**: watches players' lerp and rate settings.
- **Workshop addons off** for everyone (`l4d2_addons_eclipse 0`): some give advantages (brighter
  maps, see-through props). Players lose their skins on this server.
- **Steam bans**: tells admins when a joining player has VAC, game or community bans. It only looks
  at bans: no hours, no profile.
- **No more "No Steam logon" kicks**: l4dtoolz's `sv_steam_bypass 1` lets players in when Steam fails
  to confirm them. The price: SteamIDs aren't checked with Steam, so a hacked client could pose as an
  admin, and the Steam ban checks above can be fooled.

## Balance changes we chose on purpose

These change vanilla, so they're listed honestly. Each can be turned off in `PLUGINS.md` or its config:
- **Tank and witch chance**: 50% each per map, the same for both teams (vanilla uses its own odds).
- **Survivor bots**: take 15% less damage from infected players.
- **ZoneMod gameplay picks**:
  - no bunny-hopping, louder jockeys, fixed SI spawn order, no spitter while a tank is up;
  - SI regain health when they despawn;
  - equal alarm cars;
  - quad caps possible (`l4d2_dominators 0`);
  - a forced horde if infected wait too long to attack;
  - a few tank tweaks.
- **Map changes**: ZoneMod's Stripper map fixes (blocked exploits, stuck spots, a few props and
  items), without its special event reworks. Scripted tanks and witches are kept.
