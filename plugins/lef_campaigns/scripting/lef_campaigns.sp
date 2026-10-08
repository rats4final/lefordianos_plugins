/**
 * Lefordianos Campaigns
 *
 * Campaign rotation, replacing Automatic Campaign Switcher (ACS). When both teams have played a
 * campaign's finale (versus) or the survivors escape (coop), the server changes to the next
 * campaign: the one chosen with !votes > Next campaign (voted on the F1/F2 screen, any time during
 * the campaign), or else the next one in the mission manager's list (official campaigns first,
 * then custom ones like Big Wat Night).
 *
 *   !next                          which campaign comes next
 *   sm_setnextcampaign <map>       set it (server/admin; what the vote runs). "clear" forgets it.
 *
 * Versus: at the end of a campaign the game opens its own end panel, where players vote for 30 s
 * (sv_pz_endgame_vote_period, set in lefordianos/common.cfg; the game's default is 12) plus 5. Then
 * the game either plays the campaign again (rematch won) or sends everyone to the lobby with a
 * DisconnectToLobby message (read from server.dll). We let the rematch happen; instead of the lobby
 * we change to the next campaign, unless players chose the lobby: more votes for the panel's second
 * option than for "play again" (counted from the game's PZEndGameVoteStatsMsg), a passed "Return to
 * lobby" vote, or lef_match's !lobby (it runs lef_campaigns_allow_lobby first).
 * Coop: lef_campaigns_delay seconds after the survivors escape.
 *
 * If another plugin changes the map first (e.g. l4d2_map_transitions on c9m2), that wins: our timers
 * are cancelled by any map change.
 * Needs Harry Potter's l4d2_mission_manager for the list of campaigns.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>
#include <l4d2_mission_manager>

#define PLUGIN_VERSION "1.1.0"

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Campaigns",
	author      = "rats4final; replaces rikka0w0's Automatic Campaign Switcher",
	description = "Next campaign after a finale: voted one or the next in the list",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar g_cvDelay, g_cvAnnounce;
ConVar g_cvVotePeriod, g_cvVotePost;   // the game's end panel vote
char   g_sNextMap[64];     // first map of the voted campaign ("" = follow the list)
bool   g_bChanging;
bool   g_bCampaignOver;    // versus: the end panel is up
bool   g_bLobbyAllowed;    // players chose the lobby
int    g_iRematchVotes, g_iLobbyVotes;

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
	LoadTranslations("lef_campaigns.phrases");

	CreateConVar("lef_campaigns_version", PLUGIN_VERSION, "Lefordianos Campaigns version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvDelay    = CreateConVar("lef_campaigns_delay", "12", "Seconds after the finale ends before changing campaign (the scoreboard stays up meanwhile).", _, true, 3.0);
	g_cvAnnounce = CreateConVar("lef_campaigns_announce", "1", "On a finale map, tell everyone which campaign comes next and how to vote another.", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "lef_campaigns");

	RegConsoleCmd("sm_next", Cmd_Next, "Which campaign comes next");
	RegConsoleCmd("sm_nextcampaign", Cmd_Next, "Which campaign comes next");
	RegAdminCmd("sm_setnextcampaign", Cmd_SetNext, ADMFLAG_CHANGEMAP, "sm_setnextcampaign <first map of a campaign | clear>");

	RegServerCmd("lef_campaigns_allow_lobby", Cmd_AllowLobby, "Let the next return to the lobby through (lef_match runs it before !lobby)");

	HookEvent("finale_win", Event_FinaleWin, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_LeftStartArea, EventHookMode_PostNoCopy);

	g_cvVotePeriod = FindConVar("sv_pz_endgame_vote_period");
	g_cvVotePost   = FindConVar("sv_pz_endgame_vote_post_period");

	UserMsg msg = GetUserMessageId("DisconnectToLobby");
	if (msg != INVALID_MESSAGE_ID)
	{
		HookUserMessage(msg, Message_Lobby, true);
	}
	if ((msg = GetUserMessageId("PZEndGameVoteStatsMsg")) != INVALID_MESSAGE_ID)
	{
		HookUserMessage(msg, Message_VoteStats);
	}
	HookUserMessage(GetUserMessageId("VotePass"), Message_VotePass);
}

public void OnMapStart()
{
	g_bChanging = false;
	g_bCampaignOver = false;
	g_bLobbyAllowed = false;
	g_iRematchVotes = 0;
	g_iLobbyVotes = 0;
}

bool MissionManagerReady()
{
	return GetFeatureStatus(FeatureType_Native, "LMM_GetNumberOfMissions") == FeatureStatus_Available;
}

LMM_GAMEMODE CurrentMode()
{
	LMM_GAMEMODE mode = LMM_GetCurrentGameMode();
	return mode == LMM_GAMEMODE_UNKNOWN ? LMM_GAMEMODE_COOP : mode;
}

// First map of the campaign that comes next, and its display name for this client.
bool GetNext(int client, char[] map, int mapLen, char[] title, int titleLen)
{
	if (!MissionManagerReady())
	{
		return false;
	}
	LMM_GAMEMODE mode = CurrentMode();
	int count = LMM_GetNumberOfMissions(mode);
	if (count == 0)
	{
		return false;
	}

	int mission = -1;
	if (g_sNextMap[0] != '\0' && LMM_FindMapIndexByName(mode, mission, g_sNextMap) != -1 && mission >= 0)
	{
		// voted campaign
	}
	else
	{
		char current[64];
		GetCurrentMap(current, sizeof(current));
		int now = -1;
		LMM_FindMapIndexByName(mode, now, current);
		mission = now >= 0 ? (now + 1) % count : 0;
	}

	LMM_GetMapName(mode, mission, 0, map, mapLen);
	LMM_GetMissionLocalizedDisplayTitle(mode, mission, title, titleLen, client);
	return map[0] != '\0';
}

// ---------------------------------------------------------------------------
// End of a campaign
// ---------------------------------------------------------------------------

public void L4D2_OnEndVersusModeRound_Post()
{
	if (L4D_GetGameModeType() != GAMEMODE_VERSUS || GameRules_GetProp("m_bInSecondHalfOfRound") == 0)
	{
		return;
	}
	if (L4D_IsMissionFinalMap())
	{
		VersusCampaignOver();
	}
}

void VersusCampaignOver()
{
	if (g_bCampaignOver)
	{
		return;
	}
	g_bCampaignOver = true;

	int voteTime = g_cvVotePeriod != null ? g_cvVotePeriod.IntValue : 12;
	int postTime = g_cvVotePost != null ? g_cvVotePost.IntValue : 5;

	char map[64], title[128];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetNext(i, map, sizeof(map), title, sizeof(title)))
		{
			CPrintToChat(i, "%T", "Versus Over", i, title, voteTime);
		}
	}

	// In case the game's panel never sends anyone to the lobby: change a bit after it should have.
	CreateTimer(float(voteTime + postTime + 5), Timer_Change, _, TIMER_FLAG_NO_MAPCHANGE);
}

// The game is sending everyone back to the lobby (end panel without a rematch, or a lobby vote).
Action Message_Lobby(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (!g_bCampaignOver || g_bChanging || g_bLobbyAllowed || g_iLobbyVotes > g_iRematchVotes)
	{
		return Plugin_Continue;
	}

	// Can't change map from inside a message hook; do it next frame.
	RequestFrame(Frame_Change);
	return Plugin_Handled;
}

void Frame_Change()
{
	Timer_Change(null);
}

// The end panel's tally, per team: players, votes for option 1 ("play again"), for option 2, and one
// more number. Read from server.dll: options are stored as 1 and 2, and 1 winning means rematch.
Action Message_VoteStats(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int rematch, lobby;
	for (int team = 0; team < 2; team++)
	{
		msg.ReadByte();
		rematch += msg.ReadByte();
		lobby += msg.ReadByte();
		msg.ReadByte();
	}
	g_iRematchVotes = rematch;
	g_iLobbyVotes = lobby;
	return Plugin_Continue;
}

// A "Return to lobby" vote passed (the game's vote menu).
Action Message_VotePass(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char details[64];
	msg.ReadByte();
	msg.ReadString(details, sizeof(details));
	if (StrContains(details, "return_to_lobby", false) != -1)
	{
		g_bLobbyAllowed = true;
	}
	return Plugin_Continue;
}

Action Cmd_AllowLobby(int args)
{
	g_bLobbyAllowed = true;
	return Plugin_Handled;
}

void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	// Coop / realism: the survivors escaped. (Versus is handled when its second half ends.)
	if (L4D_GetGameModeType() == GAMEMODE_COOP)
	{
		ScheduleChange();
	}
}

void ScheduleChange()
{
	if (g_bChanging)
	{
		return;
	}
	char map[64], title[128];
	if (!GetNext(LANG_SERVER, map, sizeof(map), title, sizeof(title)))
	{
		LogError("No next campaign found (is l4d2_mission_manager loaded?)");
		return;
	}
	g_bChanging = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			GetNext(i, map, sizeof(map), title, sizeof(title));
			CPrintToChat(i, "%T", "Changing", i, title, g_cvDelay.IntValue);
		}
	}
	// A map change cancels this timer, so a map transition plugin acting first wins.
	CreateTimer(g_cvDelay.FloatValue, Timer_Change, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_Change(Handle timer)
{
	if (g_bCampaignOver)
	{
		if (g_bChanging)
		{
			return Plugin_Stop;
		}
		g_bChanging = true;
	}

	char map[64], title[128];
	if (GetNext(LANG_SERVER, map, sizeof(map), title, sizeof(title)) && IsMapValid(map))
	{
		LogMessage("Campaign over: changing to %s (%s)", map, title);
		g_sNextMap[0] = '\0';
		ServerCommand("changelevel %s", map);
	}
	else
	{
		g_bChanging = false;
		LogError("Next campaign map '%s' isn't valid", map);
	}
	return Plugin_Stop;
}

void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvAnnounce.BoolValue || !L4D_IsMissionFinalMap())
	{
		return;
	}
	CreateTimer(20.0, Timer_AnnounceNext, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_AnnounceNext(Handle timer)
{
	char map[64], title[128];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetNext(i, map, sizeof(map), title, sizeof(title)))
		{
			CPrintToChat(i, "%T", "Finale Next", i, title);
		}
	}
	return Plugin_Stop;
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

Action Cmd_Next(int client, int args)
{
	char map[64], title[128];
	int lang = client == 0 ? LANG_SERVER : client;
	if (!GetNext(lang, map, sizeof(map), title, sizeof(title)))
	{
		ReplyToCommand(client, "[Campaigns] The campaign list isn't available.");
		return Plugin_Handled;
	}
	CReplyToCommand(client, "%T", g_sNextMap[0] != '\0' ? "Next Voted" : "Next List", lang, title);
	return Plugin_Handled;
}

Action Cmd_SetNext(int client, int args)
{
	char map[64];
	GetCmdArg(1, map, sizeof(map));
	if (args < 1 || StrEqual(map, "clear", false))
	{
		g_sNextMap[0] = '\0';
		ReplyToCommand(client, "[Campaigns] Next campaign: back to the list order.");
		return Plugin_Handled;
	}
	if (!IsMapValid(map))
	{
		ReplyToCommand(client, "[Campaigns] Map '%s' isn't installed.", map);
		return Plugin_Handled;
	}
	strcopy(g_sNextMap, sizeof(g_sNextMap), map);

	char first[64], title[128];
	if (GetNext(LANG_SERVER, first, sizeof(first), title, sizeof(title)))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				GetNext(i, first, sizeof(first), title, sizeof(title));
				CPrintToChat(i, "%T", "Next Set", i, title);
			}
		}
	}
	LogAction(client, -1, "\"%L\" set the next campaign to %s", client, map);
	return Plugin_Handled;
}
