[Español](README.es.md)

# lef_menu — Lefordianos Menu

`!menu` (or `!lef`): one menu with every player command on the server, so nobody has to remember
them. Picking an entry runs that command for the player, as if they had typed it. Left 4 Dead 2.

Admin tools stay in `!admin` (see [lef_votes](../lef_votes/) for the *Lefordianos* category).

| Group | Entries |
|---|---|
| Teams | Who is on each team, last round's teams, trade places with a player, join survivors / infected, go AFK |
| Votes | Start a vote (`!votes`), T1 weapons vote, game mode vote |
| Match info | Scores, tank and witch on this map, who becomes the tank, comeback bonus |
| Game | Pause (starts a vote), ready to unpause, client settings the server checks |

The entries are in `addons/sourcemod/configs/lef_menu.cfg` (title in English and Spanish, plus the
command). An entry whose command doesn't exist on the server is hidden, so the same file works with
any set of plugins. Reload with `sm_menu_reload`.
