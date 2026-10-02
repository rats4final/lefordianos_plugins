/**
 * Lefordianos Round Start
 *
 * Two things for the moments before survivors leave the saferoom, without Ready-Up (no F1, no
 * !ready, nothing new for randoms to learn):
 *
 *  1. Start panel: a small panel with this map's tank and witch spots, how many humans each team
 *     has and the commands to know. It goes away when survivors leave the saferoom, after
 *     lef_start_panel_time seconds, or when the player closes it.
 *
 *  2. Waiting for players ("+1"): !wait opens a small menu (1-4 players), then a vote asks
 *     "Wait for 1 more player?". If it passes, nobody can leave the saferoom (anyone who tries
 *     is sent back) until that many more humans are on the teams, or the countdown runs out.
 *     !extend votes for more time, !go votes to start now (admins: instantly).
 *     In versus one survivor leaving starts the round for everyone, so this stops an impatient
 *     player from starting without the friend who's still connecting.
 *     Typing "+1", "+2"... in chat (our usual habit) doesn't start a vote by itself, so nobody gets
 *     a surprise vote screen: that player just gets a private tip about !wait
 *     (lef_start_chat_trigger: 0 = nothing, 1 = tip, 2 = start the vote directly).
 *
 * If Ready-Up is loaded, this plugin steps aside: Ready-Up already holds the start and has a panel.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#include <builtinvotes>

#define PLUGIN_VERSION "1.0.0"

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR  2
#define TEAM_INFECTED  3

enum VoteKind
{
	Vote_None = 0,
	Vote_Wait,
	Vote_Extend,
	Vote_Go
}

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Round Start",
	author      = "rats4final; saferoom hold method from Ready-Up (Competitive Rework)",
	description = "Start-of-round info panel and a '+1' vote to wait for players, without Ready-Up",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar
	g_cvPanel,
	g_cvPanelTime,
	g_cvWaitTime,
	g_cvExtendTime,
	g_cvMaxExtends,
	g_cvChatTrigger;

bool  g_bLive;              // survivors have left the saferoom this round
float g_fRoundStart;
bool  g_bHolding;
int   g_iWaitTarget;        // humans on teams needed to stop waiting
float g_fHoldEnd;
int   g_iExtends;

Handle   g_hVote;
VoteKind g_eVoteKind;
int      g_iVoteAmount;

bool  g_bPanelClosed[MAXPLAYERS + 1];
bool  g_bRefreshing[MAXPLAYERS + 1];
float g_fPanelPausedUntil[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("lef_round_start.phrases");

	CreateConVar("lef_round_start_version", PLUGIN_VERSION, "Lefordianos Round Start version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvPanel       = CreateConVar("lef_start_panel", "1", "Show the start panel (tank/witch spots, teams, commands) until survivors leave the saferoom.", _, true, 0.0, true, 1.0);
	g_cvPanelTime   = CreateConVar("lef_start_panel_time", "40", "Hide the start panel after this many seconds even if nobody has left.", _, true, 5.0);
	g_cvWaitTime    = CreateConVar("lef_start_wait_time", "90", "Seconds to wait for players after a '+1' vote passes.", _, true, 10.0);
	g_cvExtendTime  = CreateConVar("lef_start_extend_time", "60", "Seconds an !extend vote adds.", _, true, 10.0);
	g_cvMaxExtends  = CreateConVar("lef_start_max_extends", "2", "How many times a wait can be extended per round.", _, true, 0.0);
	g_cvChatTrigger = CreateConVar("lef_start_chat_trigger", "1", "Typing '+1', '+2'... in chat before the round starts: 0 = nothing, 1 = private tip about !wait, 2 = start the wait vote.", _, true, 0.0, true, 2.0);
	AutoExecConfig(true, "lef_round_start");

	RegConsoleCmd("sm_wait", Cmd_Wait, "sm_wait [players] - vote to keep the saferoom closed until more players join");
	RegConsoleCmd("sm_extend", Cmd_Extend, "Vote to wait longer for players");
	RegConsoleCmd("sm_go", Cmd_Go, "Vote to stop waiting for players (admins: instantly)");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_LeftStartArea, EventHookMode_PostNoCopy);

	CreateTimer(1.0, Timer_Tick, _, TIMER_REPEAT);
}

bool ReadyUpLoaded()
{
	return LibraryExists("readyup");
}

public void OnMapStart()
{
	ResetRound();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetRound();
}

void ResetRound()
{
	g_bLive       = false;
	g_bHolding    = false;
	g_iExtends    = 0;
	g_fRoundStart = GetGameTime();
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bPanelClosed[i]      = false;
		g_fPanelPausedUntil[i] = 0.0;
	}
}

void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bHolding)
	{
		g_bLive = true;
	}
}

// ---------------------------------------------------------------------------
// Holding the saferoom
// ---------------------------------------------------------------------------

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (!g_bHolding || ReadyUpLoaded())
	{
		return Plugin_Continue;
	}

	if (client > 0 && IsClientInGame(client))
	{
		ReturnToSaferoom(client);
		if (!IsFakeClient(client))
		{
			PrintHintText(client, "%T", "Hint Held", client);
		}
	}
	return Plugin_Handled;
}

// Same as Ready-Up: the cheat command warp_to_start_area, allowed for one call.
void ReturnToSaferoom(int client)
{
	int flags = GetCommandFlags("warp_to_start_area");
	SetCommandFlags("warp_to_start_area", flags & ~FCVAR_CHEAT);
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
	{
		L4D_ReviveSurvivor(client);
	}
	FakeClientCommand(client, "warp_to_start_area");
	SetCommandFlags("warp_to_start_area", flags);

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
	SetEntPropFloat(client, Prop_Send, "m_flFallVelocity", 0.0);
}

int CountTeamHumans()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) >= TEAM_SURVIVOR || L4D_GetBotOfIdlePlayer(i) != 0))
		{
			count++;
		}
	}
	return count;
}

void StopHolding(const char[] phrase)
{
	if (!g_bHolding)
	{
		return;
	}
	g_bHolding = false;
	CPrintToChatAll("%t", phrase);
	PrintHintTextToAll("%t", "Hint Go");
}

Action Timer_Tick(Handle timer)
{
	if (ReadyUpLoaded())
	{
		return Plugin_Continue;
	}

	if (g_bHolding)
	{
		int missing = g_iWaitTarget - CountTeamHumans();
		int left    = RoundToCeil(g_fHoldEnd - GetGameTime());
		if (missing <= 0)
		{
			StopHolding("Wait Done Joined");
		}
		else if (left <= 0)
		{
			StopHolding("Wait Done Time");
		}
		else
		{
			PrintHintTextToAll("%t", "Hint Waiting", missing, left / 60, left % 60);
		}
	}

	if (!g_bLive && g_cvPanel.BoolValue && GetGameTime() - g_fRoundStart < g_cvPanelTime.FloatValue)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && !g_bPanelClosed[i] && GetGameTime() >= g_fPanelPausedUntil[i])
			{
				MenuSource source = GetClientMenu(i);
				if (source == MenuSource_None || source == MenuSource_RawPanel)
				{
					ShowStartPanel(i);
				}
			}
		}
	}
	return Plugin_Continue;
}

// ---------------------------------------------------------------------------
// Start panel
// ---------------------------------------------------------------------------

void ShowStartPanel(int client)
{
	Panel panel = new Panel();
	char line[128], map[64], tank[32], witch[32];

	GetCurrentMap(map, sizeof(map));
	FormatEx(line, sizeof(line), "%T", "Panel Title", client, map);
	panel.SetTitle(line);

	if (L4D_GetGameModeType() == GAMEMODE_VERSUS)
	{
		int half = GameRules_GetProp("m_bInSecondHalfOfRound");
		DescribeBoss(client, L4D2Direct_GetVSTankToSpawnThisRound(half), L4D2Direct_GetVSTankFlowPercent(half), tank, sizeof(tank));
		DescribeBoss(client, L4D2Direct_GetVSWitchToSpawnThisRound(half), L4D2Direct_GetVSWitchFlowPercent(half), witch, sizeof(witch));
		FormatEx(line, sizeof(line), "%T", "Panel Bosses", client, tank, witch);
		panel.DrawText(line);

		FormatEx(line, sizeof(line), "%T", "Panel Half", client, half ? 2 : 1);
		panel.DrawText(line);
	}

	FormatEx(line, sizeof(line), "%T", "Panel Teams", client, CountHumansOn(TEAM_SURVIVOR), CountHumansOn(TEAM_INFECTED), CountHumansOn(TEAM_SPECTATOR));
	panel.DrawText(line);

	if (g_bHolding)
	{
		int left = RoundToCeil(g_fHoldEnd - GetGameTime());
		FormatEx(line, sizeof(line), "%T", "Panel Waiting", client, g_iWaitTarget - CountTeamHumans(), left / 60, left % 60);
		panel.DrawText(line);
	}

	panel.DrawText(" ");
	FormatEx(line, sizeof(line), "%T", "Panel Commands", client);
	panel.DrawText(line);
	FormatEx(line, sizeof(line), "%T", "Panel Wait", client);
	panel.DrawText(line);

	panel.CurrentKey = 10;
	FormatEx(line, sizeof(line), "%T", "Panel Close", client);
	panel.DrawItem(line);

	g_bRefreshing[client] = true;
	panel.Send(client, Panel_Handler, 3);
	g_bRefreshing[client] = false;
	delete panel;
}

int Panel_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		g_bPanelClosed[client] = true;   // they pressed a key: leave them alone this round
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_Interrupted && !g_bRefreshing[client])
	{
		g_fPanelPausedUntil[client] = GetGameTime() + 15.0;   // another menu opened: don't cover it
	}
	return 0;
}

void DescribeBoss(int client, bool spawns, float flow, char[] buffer, int maxlength)
{
	if (spawns && flow > 0.0)
	{
		FormatEx(buffer, maxlength, "%d%%", RoundToNearest(flow * 100.0));
	}
	else
	{
		FormatEx(buffer, maxlength, "%T", "Panel None", client);
	}
}

int CountHumansOn(int team)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		int t = GetClientTeam(i);
		if (t == TEAM_SPECTATOR && L4D_GetBotOfIdlePlayer(i) != 0)
		{
			t = TEAM_SURVIVOR;   // idle players keep their survivor spot
		}
		if (t == team)
		{
			count++;
		}
	}
	return count;
}

// ---------------------------------------------------------------------------
// Votes: wait / extend / go
// ---------------------------------------------------------------------------

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (client == 0 || g_cvChatTrigger.IntValue == 0 || g_bLive || g_bHolding || ReadyUpLoaded())
	{
		return;
	}

	char text[8];
	strcopy(text, sizeof(text), sArgs);
	TrimString(text);
	if (strlen(text) != 2 || text[0] != '+' || text[1] < '1' || text[1] > '4')
	{
		return;
	}

	int amount = text[1] - '0';
	if (g_cvChatTrigger.IntValue == 2)
	{
		StartWaitVote(client, amount);
	}
	else
	{
		CPrintToChat(client, "%T", "Tip Wait", client, amount);
	}
}

Action Cmd_Wait(int client, int args)
{
	if (args > 0)
	{
		int amount = GetCmdArgInt(1);
		StartWaitVote(client, amount >= 1 && amount <= 4 ? amount : 1);
	}
	else if (CanUse(client))
	{
		ShowWaitMenu(client);
	}
	return Plugin_Handled;
}

void ShowWaitMenu(int client)
{
	Menu menu = new Menu(WaitMenu_Handler);
	char text[64], info[4];
	FormatEx(text, sizeof(text), "%T", "Wait Menu Title", client);
	menu.SetTitle(text);
	for (int n = 1; n <= 4; n++)
	{
		FormatEx(text, sizeof(text), "%T", n == 1 ? "Wait Menu One" : "Wait Menu Many", client, n);
		IntToString(n, info, sizeof(info));
		menu.AddItem(info, text);
	}
	menu.Display(client, 20);
}

int WaitMenu_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char info[4];
		menu.GetItem(param, info, sizeof(info));
		StartWaitVote(client, StringToInt(info));
	}
	return 0;
}

Action Cmd_Extend(int client, int args)
{
	if (!CanUse(client))
	{
		return Plugin_Handled;
	}
	if (!g_bHolding)
	{
		CPrintToChat(client, "%T", "Not Waiting", client);
		return Plugin_Handled;
	}
	if (g_iExtends >= g_cvMaxExtends.IntValue)
	{
		CPrintToChat(client, "%T", "No More Extends", client);
		return Plugin_Handled;
	}
	StartVote(client, Vote_Extend, g_cvExtendTime.IntValue);
	return Plugin_Handled;
}

Action Cmd_Go(int client, int args)
{
	if (!CanUse(client))
	{
		return Plugin_Handled;
	}
	if (!g_bHolding)
	{
		CPrintToChat(client, "%T", "Not Waiting", client);
		return Plugin_Handled;
	}
	if (CheckCommandAccess(client, "sm_go_admin", ADMFLAG_GENERIC, true))
	{
		LogAction(client, -1, "\"%L\" stopped waiting for players", client);
		StopHolding("Wait Done Admin");
		return Plugin_Handled;
	}
	StartVote(client, Vote_Go, 0);
	return Plugin_Handled;
}

bool CanUse(int client)
{
	if (client == 0 || !IsClientInGame(client))
	{
		return false;
	}
	if (ReadyUpLoaded())
	{
		CPrintToChat(client, "%T", "Ready Up Loaded", client);
		return false;
	}
	if (g_bLive)
	{
		CPrintToChat(client, "%T", "Already Live", client);
		return false;
	}
	return true;
}

void StartWaitVote(int client, int amount)
{
	if (!CanUse(client))
	{
		return;
	}
	if (g_bHolding)
	{
		CPrintToChat(client, "%T", "Already Waiting", client);
		return;
	}
	StartVote(client, Vote_Wait, amount);
}

void StartVote(int client, VoteKind kind, int amount)
{
	if (GetClientTeam(client) <= TEAM_SPECTATOR && L4D_GetBotOfIdlePlayer(client) == 0)
	{
		CPrintToChat(client, "%T", "Join A Team", client);
		return;
	}
	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(client, "%T", "Vote Busy", client);
		return;
	}
	int delay = CheckBuiltinVoteDelay();
	if (delay > 0)
	{
		CPrintToChat(client, "%T", "Vote Delay", client, delay);
		return;
	}

	int[] voters = new int[MaxClients];
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) >= TEAM_SURVIVOR || L4D_GetBotOfIdlePlayer(i) != 0))
		{
			voters[count++] = i;
		}
	}

	char title[128];
	switch (kind)
	{
		case Vote_Wait:   FormatEx(title, sizeof(title), "%T", amount == 1 ? "Vote Wait One" : "Vote Wait Many", LANG_SERVER, amount);
		case Vote_Extend: FormatEx(title, sizeof(title), "%T", "Vote Extend", LANG_SERVER, amount);
		case Vote_Go:     FormatEx(title, sizeof(title), "%T", "Vote Go", LANG_SERVER);
	}

	g_eVoteKind   = kind;
	g_iVoteAmount = amount;
	g_hVote = CreateBuiltinVote(VoteAction_Handler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(g_hVote, title);
	SetBuiltinVoteInitiator(g_hVote, client);
	SetBuiltinVoteResultCallback(g_hVote, VoteResult_Handler);
	DisplayBuiltinVote(g_hVote, voters, count, 15);
	FakeClientCommand(client, "Vote Yes");
}

void VoteAction_Handler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	if (action == BuiltinVoteAction_End)
	{
		delete vote;
		g_hVote     = null;
		g_eVoteKind = Vote_None;
	}
	else if (action == BuiltinVoteAction_Cancel)
	{
		DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
	}
}

void VoteResult_Handler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	int yes;
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			yes = item_info[i][BUILTINVOTEINFO_ITEM_VOTES];
		}
	}

	// The round may have started while the vote was on screen.
	if (yes * 2 <= num_votes || g_bLive)
	{
		DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
		return;
	}

	char passed[64];
	FormatEx(passed, sizeof(passed), "%T", "Vote Passed", LANG_SERVER);
	DisplayBuiltinVotePass(vote, passed);

	switch (g_eVoteKind)
	{
		case Vote_Wait:
		{
			g_bHolding    = true;
			g_iWaitTarget = CountTeamHumans() + g_iVoteAmount;
			g_fHoldEnd    = GetGameTime() + g_cvWaitTime.FloatValue;
			CPrintToChatAll("%t", "Wait Started", g_iVoteAmount, g_cvWaitTime.IntValue);
		}
		case Vote_Extend:
		{
			g_iExtends++;
			g_fHoldEnd += float(g_iVoteAmount);
			CPrintToChatAll("%t", "Wait Extended", g_iVoteAmount);
		}
		case Vote_Go:
		{
			StopHolding("Wait Done Vote");
		}
	}
}
