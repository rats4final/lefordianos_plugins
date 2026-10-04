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
