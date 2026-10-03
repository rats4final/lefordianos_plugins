/**
 * Lefordianos Teams Panel
 *
 * A rewrite of "Jesters Players Panel and Switch Menu" by -=BwA=- Jester
 * (which itself built on TeamSWITCH by SkyDavid, l4d_teamspanel by OtterNas3
 * and SpecStaysSpec by DieTeetasse). The original lives in
 * alliedmodders/BwA-Jester/ for reference.
 *
 * What it does:
 *  - !teams       shows who is on each team, and lets players join one.
 *  - !lastteams   shows the teams saved at the end of the last round.
 *  - !swapwith    asks a player on another team to trade places with you.
 *  - A "Team Management" category in the SourceMod !admin menu to move,
 *    swap, flip, shuffle, balance and restore teams.
 *  - Balance hints: a player who joins the team that already has 2+ more humans is told
 *    how to switch, and spectators are told when there's a free spot (a bot) to take.
 *  - Balanced shuffle: splits the players so both teams are as even as possible.
 *    A player's strength is their lef_ranks points once they have enough ranked maps;
 *    otherwise their level from configs/lef_roster.cfg (our regulars) or the default
 *    level, turned into points (level 3 = 1000, each level = lef_teams_level_points).
 *
 * What it deliberately leaves to other plugins (see README.md):
 *  - Join/spectate commands  -> l4d_afk_commands or playermanagement.
 *    When one of those is loaded, joining from the panel goes through it,
 *    so its anti-abuse rules still apply.
 *  - Pausing                 -> pause.smx
 *  - Keeping spectators spec -> l4d2_spec_stays_spec
 *  - Automatic team repair   -> l4d2_fix_team_shuffle
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "2.2.0"

#define TEAM_NONE      0
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR  2
#define TEAM_INFECTED  3

#define ZC_TANK 8

// Which campaign team a saved player belonged to. In versus the two teams trade
// sides every round, so we remember "team A / team B" instead of "survivor /
// infected", and work out the side again when restoring.
#define SLOT_SPECTATOR -1
#define SLOT_TEAM_A    0
#define SLOT_TEAM_B    1

#define ROSTER_FILE    "configs/lef_roster.cfg"
#define MAX_BALANCE    16   // 2^16 splits to try at most

#define PANEL_TIME     20
#define PANEL_NAME_LEN 20

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Teams Panel",
	author      = "rats4final; original by -=BwA=- Jester",
	description = "Teams panel, player swap requests and admin team management",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

static const char g_sClassNames[][] = { "", "Smoker", "Boomer", "Hunter", "Spitter", "Jockey", "Charger", "Witch", "Tank" };

enum struct SavedPlayer
{
	char auth[32];
	char name[MAX_NAME_LENGTH];
	int  slot;
}

enum struct RosterEntry
{
	char name[MAX_NAME_LENGTH];
	int  level;
}

ArrayList g_aLastTeams;
StringMap g_smRoster;
char      g_sLastTeamsMap[64];

ConVar
	g_cvJoinFromPanel,
	g_cvSwapRequests,
	g_cvRequestTimeout,
	g_cvRequestCooldown,
	g_cvBalanceHints,
	g_cvSpecHintInterval,
	g_cvRosterLevel,
	g_cvLevelPoints,
	g_cvRankedGames,
	g_cvRandomLevel,
	g_cvSurvivorLimit,
	g_cvMaxInfected;

TopMenu       g_hTopMenu;
TopMenuObject g_tmoCategory = INVALID_TOPMENUOBJECT;

// Admin menu flow, kept per admin so two admins don't step on each other.
int g_iMenuFirstTarget[MAXPLAYERS + 1];

// Swap requests, indexed by the player who was asked.
int   g_iRequestFrom[MAXPLAYERS + 1];
int   g_iRequestFromTeam[MAXPLAYERS + 1];
int   g_iRequestToTeam[MAXPLAYERS + 1];
float g_fRequestExpire[MAXPLAYERS + 1];
float g_fNextRequest[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	MarkNativeAsOptional("LefRanks_GetRating");
	return APLRes_Success;
}

// From lef_ranks (optional): points and ranked maps played.
native int LefRanks_GetRating(int client, int &games);

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("lef_teams_panel.phrases");

	CreateConVar("lef_teams_panel_version", PLUGIN_VERSION, "Lefordianos Teams Panel version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvJoinFromPanel   = CreateConVar("lef_teams_panel_join", "1", "Let players join a team by pressing its number in the !teams panel. 0 = view only.", _, true, 0.0, true, 1.0);
	g_cvSwapRequests    = CreateConVar("lef_teams_panel_swap_requests", "1", "Let players ask each other to swap teams with !swapwith.", _, true, 0.0, true, 1.0);
	g_cvRequestTimeout  = CreateConVar("lef_teams_panel_request_timeout", "20", "Seconds a swap request stays open.", _, true, 5.0, true, 60.0);
	g_cvRequestCooldown = CreateConVar("lef_teams_panel_request_cooldown", "15", "Seconds a player must wait between swap requests.", _, true, 0.0);
	g_cvRosterLevel     = CreateConVar("lef_teams_roster_level", "3", "Balanced shuffle: level of a roster player whose entry has no \"level\".", _, true, 0.0, true, 10.0);
	g_cvRandomLevel     = CreateConVar("lef_teams_random_level", "2", "Balanced shuffle: level of a player who isn't in the roster.", _, true, 0.0, true, 10.0);
	g_cvBalanceHints     = CreateConVar("lef_teams_balance_hints", "1", "Versus: tell a player who joins the team with 2+ more humans how to switch, and tell spectators about free spots.", _, true, 0.0, true, 1.0);
	g_cvSpecHintInterval = CreateConVar("lef_teams_spec_hint_interval", "60", "Seconds between free-spot reminders to spectators. 0 = off.", _, true, 0.0);
	g_cvLevelPoints     = CreateConVar("lef_teams_level_points", "100", "Balanced shuffle: points per roster level (level 3 = 1000, the lef_ranks starting points).", _, true, 1.0);
	g_cvRankedGames     = CreateConVar("lef_teams_ranked_games", "5", "Balanced shuffle: use a player's lef_ranks points once they have this many ranked maps.", _, true, 0.0);
	AutoExecConfig(true, "lef_teams_panel");

	g_cvSurvivorLimit = FindConVar("survivor_limit");
	g_cvMaxInfected   = FindConVar("z_max_player_zombies");

	RegConsoleCmd("sm_teams", Cmd_Teams, "Show who is on each team");
	RegConsoleCmd("sm_lastteams", Cmd_LastTeams, "Show the teams saved at the end of the last round");
	RegConsoleCmd("sm_swapwith", Cmd_SwapWith, "sm_swapwith [player] - ask a player on another team to trade places with you");

	RegAdminCmd("sm_moveplayer", Cmd_MovePlayer, ADMFLAG_KICK, "sm_moveplayer <player> <spec|surv|inf> - move a player to a team");
	RegAdminCmd("sm_swapplayers", Cmd_SwapPlayers, ADMFLAG_KICK, "sm_swapplayers <player1> <player2> - swap two players on different teams");
	RegAdminCmd("sm_flipteams", Cmd_FlipTeams, ADMFLAG_KICK, "Swap everyone on survivors with everyone on infected");
	RegAdminCmd("sm_shuffleteams", Cmd_ShuffleTeams, ADMFLAG_KICK, "Randomly split the playing players into two new teams");
	RegAdminCmd("sm_restoreteams", Cmd_RestoreTeams, ADMFLAG_KICK, "Put everyone back on the teams saved at the end of the last round");
	RegAdminCmd("sm_balanceteams", Cmd_BalanceTeams, ADMFLAG_KICK, "Split the playing players into the two most even teams (levels from the roster)");
	RegAdminCmd("sm_roster", Cmd_Roster, ADMFLAG_KICK, "Show each player's level for the balanced shuffle");
	RegAdminCmd("sm_roster_reload", Cmd_RosterReload, ADMFLAG_CONFIG, "Reload configs/lef_roster.cfg");

	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_team", Event_PlayerTeam);
	CreateTimer(15.0, Timer_SpecHint, _, TIMER_REPEAT);

	g_aLastTeams = new ArrayList(sizeof(SavedPlayer));
	g_smRoster   = new StringMap();
	LoadRoster();

	TopMenu topmenu;
	if (LibraryExists("adminmenu") && (topmenu = GetAdminTopMenu()) != null)
	{
		OnAdminMenuReady(topmenu);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_hTopMenu    = null;
		g_tmoCategory = INVALID_TOPMENUOBJECT;
	}
}

public void OnClientDisconnect(int client)
{
	g_iRequestFrom[client]     = 0;
	g_iMenuFirstTarget[client] = 0;
	g_fNextRequest[client]     = 0.0;
}

// ---------------------------------------------------------------------------
// Saving teams at the end of each round
// ---------------------------------------------------------------------------

// Pre-hook on purpose: the game hasn't flipped the sides yet, so the
// "which side is team A" answer still matches the round that just ended.
public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
	SaveTeams();
	return Plugin_Continue;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	// Versus is handled by the forward above.
	if (L4D_GetGameModeType() != GAMEMODE_VERSUS)
	{
		SaveTeams();
	}
}

void SaveTeams()
{
	ArrayList snapshot = new ArrayList(sizeof(SavedPlayer));
	bool      flipped  = AreTeamsFlipped();
	bool      anyoneOnATeam;
	SavedPlayer p;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || !GetClientAuthId(i, AuthId_Steam2, p.auth, sizeof(p.auth)))
		{
			continue;
		}

		switch (GetClientTeam(i))
		{
			case TEAM_SURVIVOR: p.slot = flipped ? SLOT_TEAM_B : SLOT_TEAM_A;
			case TEAM_INFECTED: p.slot = flipped ? SLOT_TEAM_A : SLOT_TEAM_B;
			case TEAM_SPECTATOR: p.slot = SLOT_SPECTATOR;
			default: continue;
		}

		if (p.slot != SLOT_SPECTATOR)
		{
			anyoneOnATeam = true;
		}

		GetClientName(i, p.name, sizeof(p.name));
		snapshot.PushArray(p);
	}

	// An empty server ending a round shouldn't wipe the last real teams.
	if (!anyoneOnATeam)
	{
		delete snapshot;
		return;
	}

	delete g_aLastTeams;
	g_aLastTeams = snapshot;
	GetCurrentMap(g_sLastTeamsMap, sizeof(g_sLastTeamsMap));
}

// ---------------------------------------------------------------------------
// !teams and !lastteams
// ---------------------------------------------------------------------------

Action Cmd_Teams(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[Teams] This command is for players.");
		return Plugin_Handled;
	}

	ShowTeamsPanel(client);
	return Plugin_Handled;
}

void ShowTeamsPanel(int client)
{
	Panel panel = new Panel();
	char  line[128];
	bool  canJoin = g_cvJoinFromPanel.BoolValue;

	FormatEx(line, sizeof(line), "%T", "Panel Title", client);
	panel.SetTitle(line);

	// Item numbers 1, 2, 3 line up with the team numbers so the handler can use them directly.
	FormatEx(line, sizeof(line), "%T", "Panel Spectators", client, CountHumans(TEAM_SPECTATOR) - CountIdleHumans());
	DrawHeader(panel, line, canJoin);
	DrawSpectators(panel, client);

	FormatEx(line, sizeof(line), "%T", "Panel Survivors", client, CountHumans(TEAM_SURVIVOR) + CountIdleHumans(), GetTeamCapacity(TEAM_SURVIVOR));
	DrawHeader(panel, line, canJoin);
	DrawSurvivors(panel, client);

	if (HasInfectedTeam())
	{
		FormatEx(line, sizeof(line), "%T", "Panel Infected", client, CountHumans(TEAM_INFECTED), GetTeamCapacity(TEAM_INFECTED));
		DrawHeader(panel, line, canJoin);
		DrawInfected(panel, client);
	}

	FormatEx(line, sizeof(line), "%T", "Panel Close", client);
	panel.CurrentKey = 10;
	panel.DrawItem(line, ITEMDRAW_CONTROL);

	panel.Send(client, TeamsPanel_Handler, PANEL_TIME);
	delete panel;
}

void DrawHeader(Panel panel, const char[] text, bool selectable)
{
	if (selectable)
	{
		panel.DrawItem(text);
	}
	else
	{
		panel.DrawText(text);
	}
}

void DrawSpectators(Panel panel, int viewer)
{
	char line[128], name[MAX_NAME_LENGTH];
	bool any;

	for (int i = 1; i <= MaxClients; i++)
	{
		// Idle survivors are technically spectators; they're listed with their bot instead.
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SPECTATOR || GetIdleBot(i) != 0)
		{
			continue;
		}

		GetPanelName(i, name, sizeof(name));
		FormatEx(line, sizeof(line), "   %s", name);
		panel.DrawText(line);
		any = true;
	}

	DrawNobodyIfEmpty(panel, viewer, any);
}

void DrawSurvivors(Panel panel, int viewer)
{
	char line[128], name[MAX_NAME_LENGTH], status[32];
	bool any;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR)
		{
			continue;
		}

		int shown = i;
		if (IsFakeClient(i))
		{
			// A bot covering for an idle player shows that player's name.
			int idle = GetIdleOwner(i);
			if (idle != 0)
			{
				shown = idle;
			}
		}

		GetPanelName(shown, name, sizeof(name));

		if (!IsPlayerAlive(i))
		{
			FormatEx(status, sizeof(status), " (%T)", "Status Dead", viewer);
		}
		else if (L4D_IsPlayerIncapacitated(i))
		{
			FormatEx(status, sizeof(status), " (%T)", "Status Down", viewer);
		}
		else
		{
			status[0] = '\0';
		}

		if (shown != i)
		{
			Format(status, sizeof(status), "%s (%T)", status, "Status Away", viewer);
		}

		if (shown == i && IsFakeClient(i))
		{
			FormatEx(line, sizeof(line), "   [%T] %s%s", "Bot", viewer, name, status);
		}
		else
		{
			FormatEx(line, sizeof(line), "   %s%s", name, status);
		}

		panel.DrawText(line);
		any = true;
	}

	DrawNobodyIfEmpty(panel, viewer, any);
}

void DrawInfected(Panel panel, int viewer)
{
	char line[128], name[MAX_NAME_LENGTH], status[32];
	bool any;

	// Survivors don't normally get to see the infected lineup, so don't leak it here.
	bool showClasses = GetClientTeam(viewer) != TEAM_SURVIVOR;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_INFECTED)
		{
			continue;
		}

		GetPanelName(i, name, sizeof(name));
		status[0] = '\0';

		int zclass = GetEntProp(i, Prop_Send, "m_zombieClass");

		if (!IsPlayerAlive(i))
		{
			if (showClasses)
			{
				FormatEx(status, sizeof(status), " (%T)", "Status Dead", viewer);
			}
		}
		else if (zclass == ZC_TANK)
		{
			// Everyone knows when a Tank is up.
			strcopy(status, sizeof(status), " (Tank)");
		}
		else if (showClasses)
		{
			if (L4D_IsPlayerGhost(i))
			{
				FormatEx(status, sizeof(status), " (%s, %T)", g_sClassNames[ClampClass(zclass)], "Status Ghost", viewer);
			}
			else
			{
				FormatEx(status, sizeof(status), " (%s)", g_sClassNames[ClampClass(zclass)]);
			}
		}

		FormatEx(line, sizeof(line), "   %s%s", name, status);
		panel.DrawText(line);
		any = true;
	}

	DrawNobodyIfEmpty(panel, viewer, any);
}

void DrawNobodyIfEmpty(Panel panel, int viewer, bool any)
{
	if (!any)
	{
		char line[64];
		FormatEx(line, sizeof(line), "%T", "Panel Nobody", viewer);
		panel.DrawText(line);
	}

	panel.DrawText(" ");
}

int TeamsPanel_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select && param2 >= TEAM_SPECTATOR && param2 <= TEAM_INFECTED && g_cvJoinFromPanel.BoolValue)
	{
		JoinTeam(param1, param2);
	}

	return 0;
}

Action Cmd_LastTeams(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[Teams] This command is for players.");
		return Plugin_Handled;
	}

	if (g_aLastTeams.Length == 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "No Saved Teams");
		return Plugin_Handled;
	}

	Panel panel = new Panel();
	char  line[128];

	FormatEx(line, sizeof(line), "%T", "Panel Last Title", client, g_sLastTeamsMap);
	panel.SetTitle(line);

	// Show each saved group under the side it plays on right now.
	DrawSavedGroup(panel, client, TEAM_SURVIVOR);
	if (HasInfectedTeam())
	{
		DrawSavedGroup(panel, client, TEAM_INFECTED);
	}
	DrawSavedGroup(panel, client, TEAM_SPECTATOR);

	FormatEx(line, sizeof(line), "%T", "Panel Close", client);
	panel.CurrentKey = 10;
	panel.DrawItem(line, ITEMDRAW_CONTROL);

	panel.Send(client, LastTeamsPanel_Handler, PANEL_TIME);
	delete panel;
	return Plugin_Handled;
}

void DrawSavedGroup(Panel panel, int viewer, int team)
{
	char line[128], phrase[32];
	bool flipped = AreTeamsFlipped();
	bool any;
	SavedPlayer p;

	FormatEx(phrase, sizeof(phrase), "Team %d", team);
	FormatEx(line, sizeof(line), "%T", phrase, viewer);
	panel.DrawText(line);

	for (int i = 0; i < g_aLastTeams.Length; i++)
	{
		g_aLastTeams.GetArray(i, p);
		if (SlotToTeam(p.slot, flipped) != team)
		{
			continue;
		}

		TruncateUtf8(p.name, PANEL_NAME_LEN);

		if (FindClientByAuth(p.auth) == 0)
		{
			FormatEx(line, sizeof(line), "   %s (%T)", p.name, "Status Not Here", viewer);
		}
		else
		{
			FormatEx(line, sizeof(line), "   %s", p.name);
		}

		panel.DrawText(line);
		any = true;
	}

	DrawNobodyIfEmpty(panel, viewer, any);
}

int LastTeamsPanel_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

// ---------------------------------------------------------------------------
// Joining a team from the panel
// ---------------------------------------------------------------------------

void JoinTeam(int client, int team)
{
	if (!IsClientInGame(client))
	{
		return;
	}

	char teamPhrase[16];
	FormatEx(teamPhrase, sizeof(teamPhrase), "Team %d", team);

	if (GetClientTeam(client) == team && GetIdleBot(client) == 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "Already On Team", teamPhrase);
		return;
	}

	// Prefer the server's join plugin (l4d_afk_commands / playermanagement):
	// it has the anti-abuse rules, and players get the same behaviour as typing the command.
	static const char joinCommands[][] = { "", "sm_spec", "sm_survivors", "sm_infected" };
	if (CommandExists(joinCommands[team]))
	{
		FakeClientCommand(client, joinCommands[team]);
		return;
	}

	// Basic fallback when no join plugin is installed.
	if (team == TEAM_INFECTED && !HasInfectedTeam())
	{
		CPrintToChat(client, "%t %t", "Tag", "No Infected Team");
		return;
	}

	if (GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client) && (L4D_IsPlayerPinned(client) || L4D_IsPlayerIncapacitated(client)))
	{
		CPrintToChat(client, "%t %t", "Tag", "Cannot Leave Pinned");
		return;
	}

	if (!PutOnTeam(client, team))
	{
		CPrintToChat(client, "%t %t", "Tag", "Team Full", teamPhrase);
		return;
	}

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	CPrintToChatAll("%t %t", "Tag", "Joined Team", name, teamPhrase);
}

// ---------------------------------------------------------------------------
// !swapwith — ask someone on another team to trade places
// ---------------------------------------------------------------------------

Action Cmd_SwapWith(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[Teams] This command is for players.");
		return Plugin_Handled;
	}

	if (!g_cvSwapRequests.BoolValue)
	{
		CPrintToChat(client, "%t %t", "Tag", "Swap Disabled");
		return Plugin_Handled;
	}

	float wait = g_fNextRequest[client] - GetGameTime();
	if (wait > 0.0)
	{
		CPrintToChat(client, "%t %t", "Tag", "Swap Cooldown", RoundToCeil(wait));
		return Plugin_Handled;
	}

	if (args > 0)
	{
		char arg[MAX_NAME_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));

		int target = FindTarget(client, arg, true, false);
		if (target > 0)
		{
			SendSwapRequest(client, target);
		}

		return Plugin_Handled;
	}

	Menu menu    = new Menu(SwapWithMenu_Handler);
	int  myTeam  = GetClientTeam(client);
	char title[64], info[16], display[96], name[MAX_NAME_LENGTH], shortTeam[16];

	FormatEx(title, sizeof(title), "%T", "Swap Menu Title", client);
	menu.SetTitle(title);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}

		int team = GetClientTeam(i);
		if (team < TEAM_SPECTATOR || team == myTeam)
		{
			continue;
		}

		GetClientName(i, name, sizeof(name));
		FormatEx(shortTeam, sizeof(shortTeam), "Short %d", team);
		FormatEx(display, sizeof(display), "[%T] %s", shortTeam, client, name);
		IntToString(GetClientUserId(i), info, sizeof(info));
		menu.AddItem(info, display);
	}

	if (menu.ItemCount == 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "Swap No Targets");
		delete menu;
		return Plugin_Handled;
	}

	menu.Display(client, PANEL_TIME);
	return Plugin_Handled;
}

int SwapWithMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));

		int target = GetClientOfUserId(StringToInt(info));
		if (target == 0)
		{
			CPrintToChat(param1, "%t %t", "Tag", "Player Gone");
		}
		else
		{
			SendSwapRequest(param1, target);
		}
	}

	return 0;
}

void SendSwapRequest(int client, int target)
{
	char targetName[MAX_NAME_LENGTH];
	GetClientName(target, targetName, sizeof(targetName));

	if (target == client)
	{
		CPrintToChat(client, "%t %t", "Tag", "Swap Self");
		return;
	}

	int fromTeam = GetClientTeam(client);
	int toTeam   = GetClientTeam(target);

	if (fromTeam == toTeam)
	{
		CPrintToChat(client, "%t %t", "Tag", "Swap Same Team", targetName);
		return;
	}

	if (g_iRequestFrom[target] != 0 && g_fRequestExpire[target] > GetGameTime())
	{
		CPrintToChat(client, "%t %t", "Tag", "Swap Target Busy", targetName);
		return;
	}

	g_iRequestFrom[target]     = GetClientUserId(client);
	g_iRequestFromTeam[target] = fromTeam;
	g_iRequestToTeam[target]   = toTeam;
	g_fRequestExpire[target]   = GetGameTime() + g_cvRequestTimeout.FloatValue;
	g_fNextRequest[client]     = GetGameTime() + g_cvRequestCooldown.FloatValue;

	char clientName[MAX_NAME_LENGTH], title[192], teamPhrase[16], item[64], info[16];
	GetClientName(client, clientName, sizeof(clientName));
	FormatEx(teamPhrase, sizeof(teamPhrase), "Team %d", fromTeam);

	Menu menu = new Menu(SwapRequestMenu_Handler);
	FormatEx(title, sizeof(title), "%T", "Swap Request Title", target, clientName, teamPhrase);
	menu.SetTitle(title);

	// Each answer carries the requester's userid, so a leftover menu from an
	// older request can't answer (or cancel) a newer one.
	FormatEx(item, sizeof(item), "%T", "Swap Accept", target);
	FormatEx(info, sizeof(info), "y%d", g_iRequestFrom[target]);
	menu.AddItem(info, item);
	FormatEx(item, sizeof(item), "%T", "Swap Decline", target);
	FormatEx(info, sizeof(info), "n%d", g_iRequestFrom[target]);
	menu.AddItem(info, item);
	menu.ExitButton = false;
	menu.Display(target, g_cvRequestTimeout.IntValue);

	CPrintToChat(client, "%t %t", "Tag", "Swap Sent", targetName);
}

int SwapRequestMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
		return 0;
	}

	if (action != MenuAction_Select && action != MenuAction_Cancel)
	{
		return 0;
	}

	int target = param1;
	if (!IsClientInGame(target))
	{
		return 0;
	}

	// Which request is this menu about? (Item 0 carries it even when the menu was cancelled.)
	char info[16];
	menu.GetItem(action == MenuAction_Select ? param2 : 0, info, sizeof(info));
	if (StringToInt(info[1]) != g_iRequestFrom[target] || g_iRequestFrom[target] == 0)
	{
		return 0;
	}

	int requester = GetClientOfUserId(g_iRequestFrom[target]);
	g_iRequestFrom[target] = 0;

	if (requester == 0)
	{
		if (action == MenuAction_Select)
		{
			CPrintToChat(target, "%t %t", "Tag", "Swap Invalid");
		}
		return 0;
	}

	char targetName[MAX_NAME_LENGTH], requesterName[MAX_NAME_LENGTH];
	GetClientName(target, targetName, sizeof(targetName));
	GetClientName(requester, requesterName, sizeof(requesterName));

	if (action == MenuAction_Cancel)
	{
		CPrintToChat(requester, "%t %t", "Tag", "Swap Expired", targetName);
		return 0;
	}

	if (info[0] != 'y')
	{
		CPrintToChat(requester, "%t %t", "Tag", "Swap Declined", targetName);
		return 0;
	}

	// Someone may have switched team while the question was open.
	if (GetClientTeam(requester) != g_iRequestFromTeam[target] || GetClientTeam(target) != g_iRequestToTeam[target])
	{
		CPrintToChat(target, "%t %t", "Tag", "Swap Invalid");
		CPrintToChat(requester, "%t %t", "Tag", "Swap Invalid");
		return 0;
	}

	int want[MAXPLAYERS + 1];
	want[requester] = g_iRequestToTeam[target];
	want[target]    = g_iRequestFromTeam[target];

	if (ApplyAssignment(want, requester) == 0)
	{
		CPrintToChatAll("%t %t", "Tag", "Swap Done", requesterName, targetName);
	}

	return 0;
}

// ---------------------------------------------------------------------------
// Admin commands
// ---------------------------------------------------------------------------

Action Cmd_MovePlayer(int client, int args)
{
	if (args < 2)
	{
		CReplyToCommand(client, "%t %t", "Tag", "Usage Move");
		return Plugin_Handled;
	}

	char arg[MAX_NAME_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));
	int target = FindTarget(client, arg, true, false);
	if (target <= 0)
	{
		return Plugin_Handled;
	}

	GetCmdArg(2, arg, sizeof(arg));
	int team = ParseTeam(arg);
	if (team == TEAM_NONE)
	{
		CReplyToCommand(client, "%t %t", "Tag", "Bad Team", arg);
		return Plugin_Handled;
	}

	AdminMovePlayer(client, target, team);
	return Plugin_Handled;
}

Action Cmd_SwapPlayers(int client, int args)
{
	if (args < 2)
	{
		CReplyToCommand(client, "%t %t", "Tag", "Usage Swap");
		return Plugin_Handled;
	}

	char arg[MAX_NAME_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));
	int first = FindTarget(client, arg, true, false);
	if (first <= 0)
	{
		return Plugin_Handled;
	}

	GetCmdArg(2, arg, sizeof(arg));
	int second = FindTarget(client, arg, true, false);
	if (second <= 0)
	{
		return Plugin_Handled;
	}

	AdminSwapPlayers(client, first, second);
	return Plugin_Handled;
}

Action Cmd_FlipTeams(int client, int args)
{
	AdminFlipTeams(client);
	return Plugin_Handled;
}

Action Cmd_ShuffleTeams(int client, int args)
{
	AdminShuffleTeams(client);
	return Plugin_Handled;
}

Action Cmd_RestoreTeams(int client, int args)
{
	AdminRestoreTeams(client);
	return Plugin_Handled;
}

Action Cmd_BalanceTeams(int client, int args)
{
	AdminBalanceTeams(client);
	return Plugin_Handled;
}

Action Cmd_Roster(int client, int args)
{
	ReplyToCommand(client, "[Teams] %d player(s) in the roster. Strength of the players here (balanced shuffle):", g_smRoster.Size);

	bool inRoster;
	char name[MAX_NAME_LENGTH], rosterName[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		bool ranked;
		int  level;
		int  points = GetPlayerStrength(i, inRoster, ranked, level, rosterName, sizeof(rosterName));
		GetClientName(i, name, sizeof(name));
		ReplyToCommand(client, "  %s: %d points (%s; level %d, %s)", name, points,
			ranked ? "from the ranking" : "from the level", level, inRoster ? rosterName : "not in roster");
	}
	return Plugin_Handled;
}

Action Cmd_RosterReload(int client, int args)
{
	LoadRoster();
	ReplyToCommand(client, "[Teams] %d player(s) in the roster.", g_smRoster.Size);
	return Plugin_Handled;
}

// ---------------------------------------------------------------------------
// Balance hints
// ---------------------------------------------------------------------------

// Humans per side; idle players count for survivors (their bot keeps their place).
int CountSideHumans(int team)
{
	return team == TEAM_SURVIVOR ? CountHumans(TEAM_SURVIVOR) + CountIdleHumans() : CountHumans(team);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvBalanceHints.BoolValue || event.GetBool("disconnect") || event.GetBool("isbot"))
	{
		return;
	}
	int team = event.GetInt("team");
	if (team == TEAM_SURVIVOR || team == TEAM_INFECTED)
	{
		// The event fires before the team changes; check once it has.
		CreateTimer(1.0, Timer_CheckNewcomer, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_CheckNewcomer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client) || !HasInfectedTeam())
	{
		return Plugin_Stop;
	}

	int team = GetClientTeam(client);
	if (team != TEAM_SURVIVOR && team != TEAM_INFECTED)
	{
		return Plugin_Stop;
	}

	int other = team == TEAM_SURVIVOR ? TEAM_INFECTED : TEAM_SURVIVOR;
	int mine = CountSideHumans(team), theirs = CountSideHumans(other);
	if (mine >= theirs + 2 && theirs < GetTeamCapacity(other))
	{
		char teamPhrase[16];
		FormatEx(teamPhrase, sizeof(teamPhrase), "Team %d", other);
		CPrintToChat(client, "%t %t", "Tag", "Hint Switch", mine, theirs, teamPhrase, JoinCommand(other));
	}
	return Plugin_Stop;
}

Action Timer_SpecHint(Handle timer)
{
	static float next;
	float interval = g_cvSpecHintInterval.FloatValue;
	if (!g_cvBalanceHints.BoolValue || interval <= 0.0 || GetGameTime() < next || !HasInfectedTeam())
	{
		return Plugin_Continue;
	}

	// Suggest the side with fewer humans that still has room.
	int survivors = CountSideHumans(TEAM_SURVIVOR), infected = CountSideHumans(TEAM_INFECTED);
	int team;
	if (survivors <= infected && survivors < GetTeamCapacity(TEAM_SURVIVOR) && FindFreeSurvivorBot() != 0)
	{
		team = TEAM_SURVIVOR;
	}
	else if (infected < survivors && infected < GetTeamCapacity(TEAM_INFECTED))
	{
		team = TEAM_INFECTED;
	}
	else
	{
		return Plugin_Continue;
	}

	char teamPhrase[16];
	FormatEx(teamPhrase, sizeof(teamPhrase), "Team %d", team);
	bool told;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SPECTATOR && GetIdleBot(i) == 0)
		{
			CPrintToChat(i, "%T %T", "Tag", i, team == TEAM_SURVIVOR ? "Hint Free Bot" : "Hint Free Spot", i, teamPhrase, JoinCommand(team));
			told = true;
		}
	}
	if (told)
	{
		next = GetGameTime() + interval;
	}
	return Plugin_Continue;
}

// The command to suggest: l4d_afk_commands' if loaded (its anti-abuse rules apply), else our panel.
char[] JoinCommand(int team)
{
	char command[16] = "!teams";
	if (CommandExists(team == TEAM_SURVIVOR ? "sm_survivors" : "sm_infected"))
	{
		strcopy(command, sizeof(command), team == TEAM_SURVIVOR ? "!survivors" : "!infected");
	}
	return command;
}

// ---------------------------------------------------------------------------
// Roster and balanced shuffle
// ---------------------------------------------------------------------------

void LoadRoster()
{
	g_smRoster.Clear();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), ROSTER_FILE);
	if (!FileExists(path))
	{
		return;
	}

	KeyValues kv = new KeyValues("Roster");
	if (!kv.ImportFromFile(path))
	{
		LogError("Couldn't read %s", ROSTER_FILE);
		delete kv;
		return;
	}

	if (kv.GotoFirstSubKey())
	{
		char id[64];
		do
		{
			kv.GetSectionName(id, sizeof(id));
			NormalizeSteamId(id);

			RosterEntry entry;
			kv.GetString("name", entry.name, sizeof(entry.name), id);
			entry.level = kv.GetNum("level", -1);
			g_smRoster.SetArray(id, entry, sizeof(entry));
		}
		while (kv.GotoNextKey());
	}

	delete kv;
}

// Accepts STEAM_0:/STEAM_1: (made STEAM_1:, as L4D2 reports it), [U:1:n] and 7656... as given.
void NormalizeSteamId(char[] id)
{
	TrimString(id);
	if (strncmp(id, "steam_", 6, false) == 0)
	{
		for (int i = 0; i < 5; i++)
		{
			id[i] = CharToUpper(id[i]);
		}
		if (id[6] == '0')
		{
			id[6] = '1';
		}
	}
	else if (id[0] == '[')
	{
		id[1] = CharToUpper(id[1]);
	}
}

// A player's level for the balanced shuffle: from the roster (by any SteamID format), else the default.
// A player's strength for the balanced shuffle, in lef_ranks points: their ranking once they have
// enough ranked maps, else their roster (or default) level turned into points.
int GetPlayerStrength(int client, bool &inRoster, bool &ranked, int &level, char[] rosterName = "", int nameLength = 0)
{
	level  = GetPlayerLevel(client, inRoster, rosterName, nameLength);
	ranked = false;
	if (GetFeatureStatus(FeatureType_Native, "LefRanks_GetRating") == FeatureStatus_Available)
	{
		int games;
		int rating = LefRanks_GetRating(client, games);
		if (games >= g_cvRankedGames.IntValue)
		{
			ranked = true;
			return rating;
		}
	}
	return 1000 + (level - 3) * g_cvLevelPoints.IntValue;
}

int GetPlayerLevel(int client, bool &inRoster, char[] rosterName = "", int nameLength = 0)
{
	static const AuthIdType types[] = { AuthId_Steam2, AuthId_Steam3, AuthId_SteamID64 };

	char auth[64];
	RosterEntry entry;
	for (int t = 0; t < sizeof(types); t++)
	{
		if (!GetClientAuthId(client, types[t], auth, sizeof(auth)))
		{
			continue;
		}
		NormalizeSteamId(auth);
		if (g_smRoster.GetArray(auth, entry, sizeof(entry)))
		{
			inRoster = true;
			if (nameLength > 0)
			{
				strcopy(rosterName, nameLength, entry.name);
			}
			return entry.level >= 0 ? entry.level : g_cvRosterLevel.IntValue;
		}
	}

	inRoster = false;
	return g_cvRandomLevel.IntValue;
}

// Tries every way to split the playing players (8 players = 70 even splits) and keeps the one
// where the two teams' levels add up closest. Ties: spread the roster players evenly, then pick
// at random, so the same group doesn't always end up with the same teams.
void AdminBalanceTeams(int admin)
{
	int  players[MAXPLAYERS], levels[MAXPLAYERS];
	bool inRoster[MAXPLAYERS];
	int  count;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) >= TEAM_SURVIVOR)
		{
			if (count == MAX_BALANCE)
			{
				ReplyToAdmin(admin, "%t %t", "Tag", "Too Many To Balance", MAX_BALANCE);
				return;
			}
			players[count] = i;
			bool ranked;
			int  level;
			levels[count]  = GetPlayerStrength(i, inRoster[count], ranked, level);
			count++;
		}
	}

	if (count < 2 || !HasInfectedTeam())
	{
		ReplyToAdmin(admin, "%t %t", "Tag", "Not Enough Players");
		return;
	}

	int survivorCap = GetTeamCapacity(TEAM_SURVIVOR);
	int infectedCap = GetTeamCapacity(TEAM_INFECTED);
	int small = count / 2, big = count - small;

	int best = -1, bestDiff, bestRosterDiff, bestSurvivors, bestInfected, ties;
	for (int mask = 0; mask < (1 << count); mask++)   // bit k set = players[k] on survivors
	{
		int survivors, levelS, levelI, rosterS, rosterI;
		for (int k = 0; k < count; k++)
		{
			if (mask & (1 << k))
			{
				survivors++;
				levelS  += levels[k];
				rosterS += view_as<int>(inRoster[k]);
			}
			else
			{
				levelI  += levels[k];
				rosterI += view_as<int>(inRoster[k]);
			}
		}

		if ((survivors != small && survivors != big) || survivors > survivorCap || count - survivors > infectedCap)
		{
			continue;
		}

		int diff       = levelS > levelI ? levelS - levelI : levelI - levelS;
		int rosterDiff = rosterS > rosterI ? rosterS - rosterI : rosterI - rosterS;

		if (best == -1 || diff < bestDiff || (diff == bestDiff && rosterDiff < bestRosterDiff))
		{
			ties = 1;
		}
		else if (diff == bestDiff && rosterDiff == bestRosterDiff)
		{
			if (GetRandomInt(1, ++ties) != 1)
			{
				continue;
			}
		}
		else
		{
			continue;
		}

		best           = mask;
		bestDiff       = diff;
		bestRosterDiff = rosterDiff;
		bestSurvivors  = levelS;
		bestInfected   = levelI;
	}

	if (best == -1)
	{
		ReplyToAdmin(admin, "%t %t", "Tag", "Not Enough Players");
		return;
	}

	int want[MAXPLAYERS + 1];
	for (int k = 0; k < count; k++)
	{
		want[players[k]] = (best & (1 << k)) ? TEAM_SURVIVOR : TEAM_INFECTED;
	}

	ApplyAssignment(want, admin);
	LogAction(admin, -1, "\"%L\" balanced the teams (points %d vs %d)", admin, bestSurvivors, bestInfected);
	CPrintToChatAll("%t %t", "Tag", "Admin Balanced", AdminName(admin), bestSurvivors, bestInfected);
}

void AdminMovePlayer(int admin, int target, int team)
{
	char teamPhrase[16], targetName[MAX_NAME_LENGTH];
	FormatEx(teamPhrase, sizeof(teamPhrase), "Team %d", team);
	GetClientName(target, targetName, sizeof(targetName));

	if (GetClientTeam(target) == team)
	{
		ReplyToAdmin(admin, "%t %t", "Tag", "Player Already On Team", targetName, teamPhrase);
		return;
	}

	if (team == TEAM_INFECTED && !HasInfectedTeam())
	{
		ReplyToAdmin(admin, "%t %t", "Tag", "No Infected Team");
		return;
	}

	int want[MAXPLAYERS + 1];
	want[target] = team;

	if (ApplyAssignment(want, admin) == 0)
	{
		LogAction(admin, target, "\"%L\" moved \"%L\" to team %d", admin, target, team);
		CPrintToChatAll("%t %t", "Tag", "Admin Moved", AdminName(admin), targetName, teamPhrase);
	}
}

void AdminSwapPlayers(int admin, int first, int second)
{
	char firstName[MAX_NAME_LENGTH], secondName[MAX_NAME_LENGTH];
	GetClientName(first, firstName, sizeof(firstName));
	GetClientName(second, secondName, sizeof(secondName));

	int firstTeam  = GetClientTeam(first);
	int secondTeam = GetClientTeam(second);

	if (first == second || firstTeam == secondTeam)
	{
		ReplyToAdmin(admin, "%t %t", "Tag", "Swap Players Same Team", firstName, secondName);
		return;
	}

	int want[MAXPLAYERS + 1];
	want[first]  = secondTeam;
	want[second] = firstTeam;

	if (ApplyAssignment(want, admin) == 0)
	{
		LogAction(admin, -1, "\"%L\" swapped \"%L\" and \"%L\"", admin, first, second);
		CPrintToChatAll("%t %t", "Tag", "Admin Swapped", AdminName(admin), firstName, secondName);
	}
}

void AdminFlipTeams(int admin)
{
	int want[MAXPLAYERS + 1];
	int moved;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}

		switch (GetClientTeam(i))
		{
			case TEAM_SURVIVOR: want[i] = TEAM_INFECTED;
			case TEAM_INFECTED: want[i] = TEAM_SURVIVOR;
			default: continue;
		}

		moved++;
	}

	if (moved == 0 || !HasInfectedTeam())
	{
		ReplyToAdmin(admin, "%t %t", "Tag", "Not Enough Players");
		return;
	}

	ApplyAssignment(want, admin);
	LogAction(admin, -1, "\"%L\" flipped the teams", admin);
	CPrintToChatAll("%t %t", "Tag", "Admin Flipped", AdminName(admin));
}

void AdminShuffleTeams(int admin)
{
	int players[MAXPLAYERS];
	int count;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) >= TEAM_SURVIVOR)
		{
			players[count++] = i;
		}
	}

	if (count < 2 || !HasInfectedTeam())
	{
		ReplyToAdmin(admin, "%t %t", "Tag", "Not Enough Players");
		return;
	}

	// Fisher-Yates shuffle, then deal the players out alternately.
	for (int i = count - 1; i > 0; i--)
	{
		int j    = GetRandomInt(0, i);
		int tmp  = players[i];
		players[i] = players[j];
		players[j] = tmp;
	}

	int want[MAXPLAYERS + 1];
	int survivorCap = GetTeamCapacity(TEAM_SURVIVOR);
	int infectedCap = GetTeamCapacity(TEAM_INFECTED);
	int survivors, infected;

	for (int k = 0; k < count; k++)
	{
		bool toSurvivors = (k % 2 == 0);
		if (toSurvivors && survivors >= survivorCap)
		{
			toSurvivors = false;
		}
		else if (!toSurvivors && infected >= infectedCap)
		{
			toSurvivors = true;
		}

		if (toSurvivors)
		{
			want[players[k]] = TEAM_SURVIVOR;
			survivors++;
		}
		else
		{
			want[players[k]] = TEAM_INFECTED;
			infected++;
		}
	}

	ApplyAssignment(want, admin);
	LogAction(admin, -1, "\"%L\" shuffled the teams", admin);
	CPrintToChatAll("%t %t", "Tag", "Admin Shuffled", AdminName(admin));
}

void AdminRestoreTeams(int admin)
{
	if (g_aLastTeams.Length == 0)
	{
		ReplyToAdmin(admin, "%t %t", "Tag", "No Saved Teams");
		return;
	}

	bool flipped = AreTeamsFlipped();
	int  want[MAXPLAYERS + 1];
	bool known[MAXPLAYERS + 1];
	int  wanted[TEAM_INFECTED + 1];
	char auth[32];
	SavedPlayer p;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || !GetClientAuthId(i, AuthId_Steam2, auth, sizeof(auth)))
		{
			continue;
		}

		int index = g_aLastTeams.FindString(auth);
		if (index == -1)
		{
			continue;
		}

		g_aLastTeams.GetArray(index, p);
		want[i]  = SlotToTeam(p.slot, flipped);
		known[i] = true;
		wanted[want[i]]++;
	}

	// Players who weren't saved keep their seat if there's room left, otherwise they step aside.
	int free[TEAM_INFECTED + 1];
	free[TEAM_SURVIVOR] = GetTeamCapacity(TEAM_SURVIVOR) - wanted[TEAM_SURVIVOR];
	free[TEAM_INFECTED] = GetTeamCapacity(TEAM_INFECTED) - wanted[TEAM_INFECTED];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (known[i] || !IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}

		int team = GetClientTeam(i);
		if (team == TEAM_SURVIVOR || team == TEAM_INFECTED)
		{
			if (free[team] > 0)
			{
				free[team]--;
			}
			else
			{
				want[i] = TEAM_SPECTATOR;
			}
		}
	}

	bool anyChange;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (want[i] != TEAM_NONE && IsClientInGame(i) && GetClientTeam(i) != want[i])
		{
			anyChange = true;
			break;
		}
	}

	if (!anyChange)
	{
		ReplyToAdmin(admin, "%t %t", "Tag", "Teams Already Match");
		return;
	}

	ApplyAssignment(want, admin);
	LogAction(admin, -1, "\"%L\" restored the teams saved on %s", admin, g_sLastTeamsMap);
	CPrintToChatAll("%t %t", "Tag", "Admin Restored", AdminName(admin));
}

// ---------------------------------------------------------------------------
// Admin menu ("Team Management" category in !admin)
// ---------------------------------------------------------------------------

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	if (topmenu == g_hTopMenu)
	{
		return;
	}

	g_hTopMenu    = topmenu;
	g_tmoCategory = g_hTopMenu.AddCategory("lef_teams", AdminCategory_Handler, "sm_moveplayer", ADMFLAG_KICK);
	if (g_tmoCategory == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	// The command names let server owners change access with admin_overrides.cfg.
	g_hTopMenu.AddItem("lef_teams_show", AdminItem_Handler, g_tmoCategory, "sm_teams", ADMFLAG_KICK, "show");
	g_hTopMenu.AddItem("lef_teams_move", AdminItem_Handler, g_tmoCategory, "sm_moveplayer", ADMFLAG_KICK, "move");
	g_hTopMenu.AddItem("lef_teams_swap", AdminItem_Handler, g_tmoCategory, "sm_swapplayers", ADMFLAG_KICK, "swap");
	g_hTopMenu.AddItem("lef_teams_flip", AdminItem_Handler, g_tmoCategory, "sm_flipteams", ADMFLAG_KICK, "flip");
	g_hTopMenu.AddItem("lef_teams_shuffle", AdminItem_Handler, g_tmoCategory, "sm_shuffleteams", ADMFLAG_KICK, "shuffle");
	g_hTopMenu.AddItem("lef_teams_balance", AdminItem_Handler, g_tmoCategory, "sm_balanceteams", ADMFLAG_KICK, "balance");
	g_hTopMenu.AddItem("lef_teams_restore", AdminItem_Handler, g_tmoCategory, "sm_restoreteams", ADMFLAG_KICK, "restore");
}

void AdminCategory_Handler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle || action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "Menu Category", param);
	}
}

void AdminItem_Handler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	char info[16];
	topmenu.GetInfoString(object_id, info, sizeof(info));

	if (action == TopMenuAction_DisplayOption)
	{
		char phrase[32];
		FormatEx(phrase, sizeof(phrase), "Menu %s", info);
		FormatEx(buffer, maxlength, "%T", phrase, param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (StrEqual(info, "show"))
		{
			ShowTeamsPanel(param);
		}
		else if (StrEqual(info, "move") || StrEqual(info, "swap"))
		{
			ShowPlayerPicker(param, StrEqual(info, "swap"));
		}
		else
		{
			ShowConfirm(param, info);
		}
	}
}

void ShowPlayerPicker(int admin, bool isSwap)
{
	Menu menu = new Menu(isSwap ? PickFirstForSwap_Handler : PickForMove_Handler);
	char title[64];
	FormatEx(title, sizeof(title), "%T", "Menu Pick Player", admin);
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	AddPlayersToMenu(menu, admin, TEAM_NONE);

	if (menu.ItemCount == 0)
	{
		CPrintToChat(admin, "%t %t", "Tag", "Not Enough Players");
		delete menu;
		ReturnToCategory(admin);
		return;
	}

	menu.Display(admin, MENU_TIME_FOREVER);
}

// Adds every human the admin can target, tagged with their team. Skips anyone on excludeTeam.
void AddPlayersToMenu(Menu menu, int admin, int excludeTeam)
{
	char info[16], display[96], name[MAX_NAME_LENGTH], shortTeam[16];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || !CanUserTarget(admin, i))
		{
			continue;
		}

		int team = GetClientTeam(i);
		if (team < TEAM_SPECTATOR || team == excludeTeam)
		{
			continue;
		}

		GetClientName(i, name, sizeof(name));
		FormatEx(shortTeam, sizeof(shortTeam), "Short %d", team);
		FormatEx(display, sizeof(display), "[%T] %s", shortTeam, admin, name);
		IntToString(GetClientUserId(i), info, sizeof(info));
		menu.AddItem(info, display);
	}
}

int PickForMove_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		ReturnToCategory(param1);
	}
	else if (action == MenuAction_Select)
	{
		int target = GetMenuTarget(menu, param2, param1);
		if (target == 0)
		{
			ShowPlayerPicker(param1, false);
			return 0;
		}

		g_iMenuFirstTarget[param1] = GetClientUserId(target);

		char title[96], name[MAX_NAME_LENGTH], item[32], phrase[16], info[4];
		GetClientName(target, name, sizeof(name));

		Menu teams = new Menu(PickTeam_Handler);
		FormatEx(title, sizeof(title), "%T", "Menu Pick Team", param1, name);
		teams.SetTitle(title);
		teams.ExitBackButton = true;

		int current = GetClientTeam(target);
		int lastTeam = HasInfectedTeam() ? TEAM_INFECTED : TEAM_SURVIVOR;
		for (int team = TEAM_SPECTATOR; team <= lastTeam; team++)
		{
			FormatEx(phrase, sizeof(phrase), "Team %d", team);
			FormatEx(item, sizeof(item), "%T", phrase, param1);
			IntToString(team, info, sizeof(info));
			teams.AddItem(info, item, team == current ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}

		teams.Display(param1, MENU_TIME_FOREVER);
	}

	return 0;
}

int PickTeam_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		ShowPlayerPicker(param1, false);
	}
	else if (action == MenuAction_Select)
	{
		char info[4];
		menu.GetItem(param2, info, sizeof(info));

		int target = GetClientOfUserId(g_iMenuFirstTarget[param1]);
		if (target == 0)
		{
			CPrintToChat(param1, "%t %t", "Tag", "Player Gone");
		}
		else
		{
			AdminMovePlayer(param1, target, StringToInt(info));
		}

		ReturnToCategory(param1);
	}

	return 0;
}

int PickFirstForSwap_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		ReturnToCategory(param1);
	}
	else if (action == MenuAction_Select)
	{
		int first = GetMenuTarget(menu, param2, param1);
		if (first == 0)
		{
			ShowPlayerPicker(param1, true);
			return 0;
		}

		g_iMenuFirstTarget[param1] = GetClientUserId(first);

		char title[96], name[MAX_NAME_LENGTH];
		GetClientName(first, name, sizeof(name));

		Menu second = new Menu(PickSecondForSwap_Handler);
		FormatEx(title, sizeof(title), "%T", "Menu Pick Second", param1, name);
		second.SetTitle(title);
		second.ExitBackButton = true;

		AddPlayersToMenu(second, param1, GetClientTeam(first));

		if (second.ItemCount == 0)
		{
			CPrintToChat(param1, "%t %t", "Tag", "Swap No Targets");
			delete second;
			ShowPlayerPicker(param1, true);
			return 0;
		}

		second.Display(param1, MENU_TIME_FOREVER);
	}

	return 0;
}

int PickSecondForSwap_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		ShowPlayerPicker(param1, true);
	}
	else if (action == MenuAction_Select)
	{
		int first  = GetClientOfUserId(g_iMenuFirstTarget[param1]);
		int second = GetMenuTarget(menu, param2, param1);

		if (first == 0)
		{
			CPrintToChat(param1, "%t %t", "Tag", "Player Gone");
		}
		else if (second != 0)
		{
			AdminSwapPlayers(param1, first, second);
		}

		ReturnToCategory(param1);
	}

	return 0;
}

// Flip, shuffle and restore move a lot of people at once, so ask first.
void ShowConfirm(int admin, const char[] what)
{
	Menu menu = new Menu(Confirm_Handler);
	char title[96], phrase[32], item[32];

	FormatEx(phrase, sizeof(phrase), "Menu %s", what);
	FormatEx(title, sizeof(title), "%T", "Menu Confirm", admin, phrase);
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	FormatEx(item, sizeof(item), "%T", "Yes", admin);
	menu.AddItem(what, item);
	FormatEx(item, sizeof(item), "%T", "No", admin);
	menu.AddItem("", item);

	menu.Display(admin, MENU_TIME_FOREVER);
}

int Confirm_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
	{
		ReturnToCategory(param1);
	}
	else if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));

		if (StrEqual(info, "flip"))
		{
			AdminFlipTeams(param1);
		}
		else if (StrEqual(info, "shuffle"))
		{
			AdminShuffleTeams(param1);
		}
		else if (StrEqual(info, "restore"))
		{
			AdminRestoreTeams(param1);
		}
		else if (StrEqual(info, "balance"))
		{
			AdminBalanceTeams(param1);
		}

		ReturnToCategory(param1);
	}

	return 0;
}

int GetMenuTarget(Menu menu, int item, int admin)
{
	char info[16];
	menu.GetItem(item, info, sizeof(info));

	int target = GetClientOfUserId(StringToInt(info));
	if (target == 0)
	{
		CPrintToChat(admin, "%t %t", "Tag", "Player Gone");
	}

	return target;
}

void ReturnToCategory(int admin)
{
	if (g_hTopMenu != null && g_tmoCategory != INVALID_TOPMENUOBJECT && IsClientInGame(admin))
	{
		g_hTopMenu.DisplayCategory(g_tmoCategory, admin);
	}
}

// ---------------------------------------------------------------------------
// Moving players
// ---------------------------------------------------------------------------

/**
 * Puts each client i on team want[i] (TEAM_NONE = leave alone).
 * Everyone who changes side steps out to spectators first, so seats and survivor
 * bots free up before anyone is placed — the same order playermanagement uses.
 *
 * @return  How many players could not be placed (they end up as spectators).
 */
int ApplyAssignment(const int[] want, int notify)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (want[i] == TEAM_NONE || !IsClientInGame(i))
		{
			continue;
		}

		int team = GetClientTeam(i);
		if (team != want[i] && (team == TEAM_SURVIVOR || team == TEAM_INFECTED))
		{
			StepAside(i);
		}
	}

	int failed;
	char name[MAX_NAME_LENGTH], teamPhrase[16];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (want[i] == TEAM_NONE || !IsClientInGame(i) || PutOnTeam(i, want[i]))
		{
			continue;
		}

		failed++;
		GetClientName(i, name, sizeof(name));
		FormatEx(teamPhrase, sizeof(teamPhrase), "Team %d", want[i]);
		ReplyToAdmin(notify, "%t %t", "Tag", "Could Not Move", name, teamPhrase);
	}

	return failed;
}

// Moves a player to spectators. A living Special Infected dies instead of being
// handed to the AI; a Tank is left to the game (it passes to another player or the AI).
void StepAside(int client)
{
	if (GetClientTeam(client) == TEAM_INFECTED && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_TANK)
	{
		ForcePlayerSuicide(client);
	}

	ChangeClientTeam(client, TEAM_SPECTATOR);
}

bool PutOnTeam(int client, int team)
{
	int current = GetClientTeam(client);
	if (current == team && GetIdleBot(client) == 0)
	{
		return true;
	}

	if (team == TEAM_SPECTATOR)
	{
		StepAside(client);
		return true;
	}

	if (CountHumans(team) >= GetTeamCapacity(team))
	{
		return false;
	}

	if (team == TEAM_INFECTED)
	{
		if (current == TEAM_SURVIVOR)
		{
			StepAside(client);
		}

		ChangeClientTeam(client, TEAM_INFECTED);
		return GetClientTeam(client) == TEAM_INFECTED;
	}

	// An idle player just takes their own bot back.
	if (GetIdleBot(client) != 0)
	{
		L4D_TakeOverBot(client);
		return GetClientTeam(client) == TEAM_SURVIVOR;
	}

	// Survivors: take over a free survivor bot, the way Left4DHooks documents it.
	int bot = FindFreeSurvivorBot();
	if (bot == 0)
	{
		return false;
	}

	if (current != TEAM_SPECTATOR)
	{
		StepAside(client);
	}

	L4D_SetHumanSpec(bot, client);
	L4D_TakeOverBot(client);
	return GetClientTeam(client) == TEAM_SURVIVOR;
}

// Prefers a living bot nobody has gone idle on; falls back to a dead one.
int FindFreeSurvivorBot()
{
	int dead;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR || GetIdleOwner(i) != 0)
		{
			continue;
		}

		if (IsPlayerAlive(i))
		{
			return i;
		}

		if (dead == 0)
		{
			dead = i;
		}
	}

	return dead;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// The human who went idle on this survivor bot, or 0.
int GetIdleOwner(int bot)
{
	if (!HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
	{
		return 0;
	}

	int owner = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
	return (owner != 0 && IsClientInGame(owner) && !IsFakeClient(owner)) ? owner : 0;
}

// The survivor bot this human is idle on, or 0.
int GetIdleBot(int client)
{
	if (GetClientTeam(client) != TEAM_SPECTATOR)
	{
		return 0;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && GetIdleOwner(i) == client)
		{
			return i;
		}
	}

	return 0;
}

int CountHumans(int team)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			count++;
		}
	}
	return count;
}

int CountIdleHumans()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && GetIdleOwner(i) != 0)
		{
			count++;
		}
	}
	return count;
}

int GetTeamCapacity(int team)
{
	switch (team)
	{
		case TEAM_SURVIVOR: return g_cvSurvivorLimit.IntValue;
		case TEAM_INFECTED: return HasInfectedTeam() ? g_cvMaxInfected.IntValue : 0;
	}
	return MaxClients;
}

bool HasInfectedTeam()
{
	int type = L4D_GetGameModeType();
	return type == GAMEMODE_VERSUS || type == GAMEMODE_SCAVENGE;
}

bool AreTeamsFlipped()
{
	return HasInfectedTeam() && GameRules_GetProp("m_bAreTeamsFlipped") != 0;
}

int SlotToTeam(int slot, bool flipped)
{
	switch (slot)
	{
		case SLOT_TEAM_A: return flipped ? TEAM_INFECTED : TEAM_SURVIVOR;
		case SLOT_TEAM_B: return flipped ? TEAM_SURVIVOR : TEAM_INFECTED;
	}
	return TEAM_SPECTATOR;
}

int FindClientByAuth(const char[] auth)
{
	char other[32];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientAuthId(i, AuthId_Steam2, other, sizeof(other)) && StrEqual(auth, other))
		{
			return i;
		}
	}
	return 0;
}

int ParseTeam(const char[] arg)
{
	if (StrEqual(arg, "1") || StrContains(arg, "spec", false) == 0)
	{
		return TEAM_SPECTATOR;
	}
	if (StrEqual(arg, "2") || StrContains(arg, "sur", false) == 0)
	{
		return TEAM_SURVIVOR;
	}
	if (StrEqual(arg, "3") || StrContains(arg, "inf", false) == 0)
	{
		return TEAM_INFECTED;
	}
	return TEAM_NONE;
}

int ClampClass(int zclass)
{
	return (zclass >= 0 && zclass < sizeof(g_sClassNames)) ? zclass : 0;
}

char[] AdminName(int admin)
{
	char name[MAX_NAME_LENGTH] = "Console";
	if (admin > 0 && IsClientInGame(admin))
	{
		GetClientName(admin, name, sizeof(name));
	}
	return name;
}

void GetPanelName(int client, char[] buffer, int maxlength)
{
	GetClientName(client, buffer, maxlength);
	TruncateUtf8(buffer, PANEL_NAME_LEN);
}

// Panels have a small size limit, so long names are cut — without splitting a multi-byte character.
void TruncateUtf8(char[] text, int maxBytes)
{
	if (strlen(text) <= maxBytes)
	{
		return;
	}

	int cut = maxBytes;
	while (cut > 0 && (text[cut] & 0xC0) == 0x80)
	{
		cut--;
	}
	text[cut] = '\0';
}

// Like CReplyToCommand, but works from menu callbacks too (where there is no command to reply to).
void ReplyToAdmin(int client, const char[] format, any...)
{
	char buffer[254];

	if (client == 0)
	{
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(buffer, sizeof(buffer), format, 3);
		CRemoveTags(buffer, sizeof(buffer));
		PrintToServer("%s", buffer);
		return;
	}

	if (!IsClientInGame(client))
	{
		return;
	}

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	CPrintToChat(client, "%s", buffer);
}
