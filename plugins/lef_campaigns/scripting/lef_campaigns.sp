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
 * If another plugin changes the map first (e.g. l4d2_map_transitions on c9m2), that wins: our change
 * waits lef_campaigns_delay seconds and is cancelled by any map change.
 * Needs Harry Potter's l4d2_mission_manager for the list of campaigns.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>
#include <l4d2_mission_manager>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Campaigns",
	author      = "rats4final; replaces rikka0w0's Automatic Campaign Switcher",
	description = "Next campaign after a finale: voted one or the next in the list",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar g_cvDelay, g_cvAnnounce;
char   g_sNextMap[64];     // first map of the voted campaign ("" = follow the list)
bool   g_bChanging;

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

	HookEvent("finale_win", Event_FinaleWin, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_LeftStartArea, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	g_bChanging = false;
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
		ScheduleChange();
	}
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
