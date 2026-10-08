[Español](CONNECTION.es.md)

# Connection problems

Errors players hit when joining the server, what we found about each, and what to do. Most of this
was learned on the owner's server in October 2026 (Windows, the server on the same PC the owner plays on).

## "No Steam logon" / "STEAM validation rejected"

**What it is:** the server asks Steam to confirm every player. When Steam doesn't answer in time, the
player is kicked. On 2026-10-03 four players were kicked in the same second, which means the
**server** lost touch with Steam, not each player.

**What we did:** lakwsh's l4dtoolz ships in the lite package with `sv_steam_bypass 1`, so the server
stops asking Steam. Since then it hasn't come back. The cost is in `cfg/server.example.cfg`: SteamIDs
are then not checked with Steam.

**Check it's on:** server console `plugin_print` lists **L4DToolZ**, and `sv_steam_bypass` says `1`.

### What the game's code and our logs say (2026-10-08)

**Status: the cause is still a suspicion; the bypass stops the kicks.**

**How it works** (read from the server's `engine.dll`): when a player joins, the server checks the
player's Steam ticket on the spot (the log says `STEAM USERID validated`) and asks Steam's servers to
confirm it. Steam's answer comes later. If it's a "no", the server writes
`STEAMAUTH: Client <name> received failure code <N>` and kicks the player. Four different answers all
give the same kick message, "No Steam logon":

| Code | Steam's answer |
|---|---|
| 1 | The player isn't connected to Steam |
| 6 | The player's game canceled the ticket |
| 7 | The ticket was already used |
| 8 | The ticket isn't valid (not from a Steam session that's online now) |

(Code 2 = "does not own this game", 3 = "VAC banned", 4 = "being used in another location", 5 =
"Client timed out".) The only way the engine skips the kick is LAN mode (`sv_lan 1`, or Steam failing
to load). `-insecure` doesn't help: it only turns VAC off, players are still checked.

**What our logs show** (`left4dead2/logs/`, 2026-10-02 to 10-05):
- 14 kicks, **all in one 52-minute window** (2026-10-03 23:13 to 10-04 00:05). Before it: none (a whole
  night on the old ZoneMod setup, 16 maps, plus the afternoon tests). After it: none either, but
  l4dtoolz was copied to the server at 00:02, so from then on the bypass may be what hides them.
- 13 of 14 were **code 8**, one code 6.
- They came in **waves: up to 6 players in the same second, 1.5 to 2 minutes after a map started**
  (map at 23:13:00, kicks 23:14:32; 23:49:56 → 23:51:47; 23:55:22 → 23:56:53; 00:03:28 → 00:05:20).
- Friends in different places got code 8 at the same moment, and so did the owner, who plays on the
  server's own PC.

**What it points to (suspicion):** when many unrelated players get "invalid ticket" at once, the
problem is on the **server's side of the conversation with Steam**: the server's connection to Steam
(the owner's PC and internet) dropped or reconnected during that window, and Steam stopped accepting
the tickets the server had. A short Steam outage would look the same. It's not a plugin (none of ours
touch Steam authentication) and not the players' internet.

**Why we can't see it any more:** with `sv_steam_bypass 1`, l4dtoolz takes the SteamID from the
player's ticket and tells the game it's valid without asking Steam, so there's no answer to log. The
one thing that still shows the server losing Steam is the console: the engine prints
`Connection to Steam servers lost.` and then `Connection to Steam servers successful.` These lines go
to the console only, not to `logs/`. To keep them, start the server with `-condebug` (writes
`left4dead2/console.log`; the server repo's `start-server.bat` does it since 2026-10-08) and search it
for "Steam servers" after a bad night. **`console.log` only grows** (everything the console prints,
every night): delete it every few weeks with the server stopped.

## "Duplicate client connection" then "STEAM validation rejected"

The server still holds an old connection of that account (the game crashed, or the player reconnected
too fast). Wait a minute and retry, or find it in `status` and `kickid <userid>`. The `UserID` in the
message is in hexadecimal (`f` = 15).

## "Reservation request with bogus payload data" when the owner starts the lobby

**Status: strong suspicion, not yet confirmed (2026-10-04).** Keep watching it in the next games.

**Symptom:** when the owner (whose PC also runs the server) creates the lobby and starts the game,
it fails sometimes and works other times. When a friend starts it, it always works. The server
console shows:

```
ReplyReservationRequest:  Reservation request with bogus payload data from 192.168.0.8:27005 [512 bytes]
```

**What the game's code does** (read from the server's `engine.dll`):
1. The lobby leader's game asks the server for a secret number (a "challenge"). The server picks one
   and remembers it **for the IP that asked** (only the IP, not the port).
2. The leader's game sends the reservation locked (encrypted) with that number.
3. The server unlocks it with the number it remembers **for the IP the reservation came from**, and
   checks for a fixed marker inside (`0xFEEDBEEF`). If the marker isn't there: "bogus payload data".
   ("bogus payload size" is a different check: empty, over 1024 bytes, or not a multiple of 8.)

So the error means the reservation came from a different IP than the one that got the number.

**Why the owner:** the owner's PC can reach the server two ways: directly on the local network
(the server sees `192.168.0.8`), or out to the public IP and back in through the router (the server
sees another address). The game sometimes asks for the number one way and sends the reservation the
other way: a race, so it's intermittent. Friends only have the public way, so it always matches.

**What seems to fix it:** block the long way on the owner's PC only, so the game can only use the
local one. PowerShell as administrator (put the server's public IP, shown as "WAN IP" in the router):

```powershell
New-NetFirewallRule -DisplayName "L4D2 bloquear vuelta por IP publica" -Direction Outbound -Protocol UDP -RemoteAddress <public IP> -RemotePort 27016 -Action Block -Profile Any
```

Friends aren't affected (the rule only exists on the owner's PC). Windows can't block the local way
instead: its firewall doesn't filter a PC's traffic to itself. First test (2026-10-04): no "bogus"
line, only `-> Reservation cookie ...: reason ReplyReservationRequest`, and the owner got in.

**If the public IP changes** (the ISP can change it), the rule must be recreated with the new one.
**If the owner can't get in at all with the rule**, remove it:

```powershell
Remove-NetFirewallRule -DisplayName "L4D2 bloquear vuelta por IP publica"
```

**Still to confirm:** that "bogus" doesn't come back over several game nights with the owner starting.
If it does, write down the IP after "from" and the bytes.

**Other things tried:** `mm_dedicated_force_servers` with the public IP worked one day and not the
next (consistent with the race). With the local IP, the lobby turns LAN-only and friends can't join.
The router's DMZ is not needed for this; leave it off.

## "The session is no longer available" with `connect`

Probably the server is still held ("reserved") by a lobby that failed to join. Wait about a minute,
or type `sv_cookie 0` in the server console (an l4dtoolz command that drops the reservation). Always
include the port: `connect <IP>:27016`; without it the game tries 27015.

## "Server is enforcing consistency for this file: addons/..."

**Status: found by the owner (2026-10), fix works.**

**Symptom:** a player is kicked while joining with a message like
`Server is enforcing consistency for this file: addons/bigwatnight.vpk` (the name changes with the
campaign).

**Why:** the server runs with `sv_consistency 1` (in `server.cfg`), so it compares the add-on files
the player loads with its own. The comparison goes by **path**: if the server has the campaign at one
path and the player at another (for example `addons/workshop/3122417079.vpk` from the Workshop on one
side, and a hand-copied `addons/bigwatnight.vpk` on the other), it doesn't match and the player is
kicked, even if it's the same campaign.

**Fix:** use the **same path for the add-on on the server and on every player's game**. The easy way
is for both to use the Workshop copy (`addons/workshop/<id>.vpk`): the players subscribe on the
Workshop, and the server gets the same file in `addons/workshop/`. If a player copied the file by
hand, they delete it and subscribe instead (or both use the same file name in `addons/`).

`sv_consistency 0` would also stop the kick, but then nobody's files are checked (modified models or
materials, e.g. see-through walls, get in). Not recommended.
