/**
 * Lefordianos Match
 *
 * Admin tools for a versus match:
 *
 *  - Keeps the campaign scores when the map is changed by force inside the same campaign:
 *    restarting the chapter, or jumping to another chapter of it (SourceMod's "Change map", the
 *    mission manager, !votes, changelevel...). The game treats any forced map change as a new
 *    match and puts both teams back at 0.
 *  - sm_restartchapter: restarts the chapter being played. Scores are kept (see above).
 *  - sm_returntolobby: sends everyone back to the lobby, like the game's own "Return to lobby"
 *    vote does when it passes (a DisconnectToLobby message to every player, read from server.dll).
 *  - Both are in !admin > Server Commands, with an "are you sure?".
 *
 * How the scores are kept: at the start of every chapter (first half) it notes both teams'
 * campaign scores and which side each team starts on, and keeps noting which players are on
 * which campaign team. When a new map starts with both scores at 0, the previous chapter was in
 * the same campaign, it isn't the campaign's first map, and there were points to lose, the map
 * was changed by force: it puts the teams back in the chapter's order (sm_flipteams from
 * lef_teams_panel, if they came back swapped) and gives each team its points back.
 * A new campaign, a first map, or an empty server (people went back to the lobby) start from 0.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <l4d2_mission_manager>

#define PLUGIN_VERSION "1.0.0"

#define TEAM_SURVIVOR  2
#define TEAM_INFECTED  3

#define RESTORE_TRIES  30     // seconds to wait for players to finish loading before restoring
#define FORGET_DELAY   60.0   // map changes also disconnect everyone for a moment

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Match",
	author      = "rats4final",
	description = "Keeps versus scores on forced map changes, restart chapter, return to lobby",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar g_cvKeepScores;
ConVar g_cvDelay;

// Scores and sides at the start of the chapter being played (campaign teams: 0 = A, 1 = B).
bool g_bHaveChapter;
int  g_iChapterScore[2];
bool g_bChapterFlipped;          // true = team B started this chapter as survivors
char g_sChapterMap[64];

// Steam ID -> campaign team (0/1), kept up to date while playing.
StringMap g_smCampaignTeam;

bool   g_bChapterHandled;        // this map's first half was looked at
bool   g_bRestorePending;
int    g_iRestoreTries;
Handle g_hForgetTimer;

TopMenu g_hTopMenu;

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
	LoadTranslations("common.phrases");
	LoadTranslations("lef_match.phrases");

	CreateConVar("lef_match_version", PLUGIN_VERSION, "Lefordianos Match version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvKeepScores = CreateConVar("lef_match_keep_scores", "1", "Keep the campaign scores when the map is changed by force inside the same campaign (1 = yes).", _, true, 0.0, true, 1.0);
	g_cvDelay      = CreateConVar("lef_match_delay", "3", "Seconds of warning before restarting the chapter or returning to the lobby.", _, true, 0.0, true, 15.0);
	AutoExecConfig(true, "lef_match");

	RegAdminCmd("sm_restartchapter", Cmd_RestartChapter, ADMFLAG_CHANGEMAP, "Restart the chapter being played (versus scores are kept)");
	RegAdminCmd("sm_returntolobby", Cmd_ReturnToLobby, ADMFLAG_CHANGEMAP, "Send everyone back to the lobby");
	RegAdminCmd("sm_lobby", Cmd_ReturnToLobby, ADMFLAG_CHANGEMAP, "Send everyone back to the lobby");

	g_smCampaignTeam = new StringMap();

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

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
		g_hTopMenu = null;
	}
}

// ---------------------------------------------------------------------------
// Following the chapter
// ---------------------------------------------------------------------------

public void OnMapStart()
{
	g_bChapterHandled = false;
	g_bRestorePending = false;
	CreateTimer(10.0, Timer_Track, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bChapterHandled || L4D_GetGameModeType() != GAMEMODE_VERSUS || GameRules_GetProp("m_bInSecondHalfOfRound") != 0)
	{
		return;
	}

	g_bChapterHandled = true;
	CreateTimer(1.0, Timer_ChapterStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ChapterStart(Handle timer)
{
	char map[64];
	GetCurrentMap(map, sizeof(map));

	if (ScoresWereLost(map))
	{
		g_bRestorePending = true;
		g_iRestoreTries = 0;
		CreateTimer(1.0, Timer_Restore, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		NoteChapter(map);
	}

	return Plugin_Stop;
}

bool ScoresWereLost(const char[] map)
{
	if (!g_cvKeepScores.BoolValue || !g_bHaveChapter)
	{
		return false;
	}

	// There were points to lose, and now both teams are at 0: a forced map change.
	if (g_iChapterScore[0] == 0 && g_iChapterScore[1] == 0)
	{
		return false;
	}
	if (L4D2Direct_GetVSCampaignScore(0) != 0 || L4D2Direct_GetVSCampaignScore(1) != 0)
	{
		return false;
	}

	// Going back to the first map is a new campaign (the game's "Restart campaign" too).
	if (L4D_IsFirstMapInScenario())
	{
		return false;
	}

	return SameCampaign(g_sChapterMap, map);
}

bool SameCampaign(const char[] mapA, const char[] mapB)
{
	if (StrEqual(mapA, mapB, false))
	{
		return true;
	}

	if (GetFeatureStatus(FeatureType_Native, "LMM_FindMapIndexByName") != FeatureStatus_Available)
	{
		return false;
	}

	int missionA = -1, missionB = -1;
	if (LMM_FindMapIndexByName(LMM_GAMEMODE_VERSUS, missionA, mapA) == -1
		|| LMM_FindMapIndexByName(LMM_GAMEMODE_VERSUS, missionB, mapB) == -1)
	{
		return false;
	}

	return missionA != -1 && missionA == missionB;
}

void NoteChapter(const char[] map)
{
	g_bHaveChapter = true;
	g_iChapterScore[0] = L4D2Direct_GetVSCampaignScore(0);
	g_iChapterScore[1] = L4D2Direct_GetVSCampaignScore(1);
	g_bChapterFlipped = GameRules_GetProp("m_bAreTeamsFlipped") != 0;
	strcopy(g_sChapterMap, sizeof(g_sChapterMap), map);
}

// Which players are on which campaign team, so we know who's who after a forced map change.
Action Timer_Track(Handle timer)
{
	if (!g_bRestorePending && L4D_GetGameModeType() == GAMEMODE_VERSUS)
	{
		TrackTeams();
	}

	return Plugin_Continue;
}

void TrackTeams()
{
	int survivorTeam = GameRules_GetProp("m_bAreTeamsFlipped") != 0 ? 1 : 0;
	char auth[32];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || !GetClientAuthId(i, AuthId_Steam2, auth, sizeof(auth)))
		{
			continue;
		}

		switch (GetClientTeam(i))
		{
			case TEAM_SURVIVOR: g_smCampaignTeam.SetValue(auth, survivorTeam);
			case TEAM_INFECTED: g_smCampaignTeam.SetValue(auth, 1 - survivorTeam);
		}
	}
}

// ---------------------------------------------------------------------------
// Giving the points back
// ---------------------------------------------------------------------------

Action Timer_Restore(Handle timer)
{
	// Wait until nobody is still loading (or give up waiting), or survivors left the saferoom.
	if (++g_iRestoreTries < RESTORE_TRIES && AnyoneLoading() && !L4D_HasAnySurvivorLeftSafeArea())
	{
		return Plugin_Continue;
	}

	Restore();
	return Plugin_Stop;
}

bool AnyoneLoading()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
		{
			return true;
		}
	}

	return false;
}

void Restore()
{
	// The team that started this chapter as survivors, and the other one.
	int firstSurvivors = g_bChapterFlipped ? 1 : 0;

	// Who came back on the wrong side? Count the people we know on each side.
	int right, wrong, team;
	char auth[32];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || !GetClientAuthId(i, AuthId_Steam2, auth, sizeof(auth))
			|| !g_smCampaignTeam.GetValue(auth, team))
		{
			continue;
		}

		int side = GetClientTeam(i);
		if (side != TEAM_SURVIVOR && side != TEAM_INFECTED)
		{
			continue;
		}
		if ((side == TEAM_SURVIVOR) == (team == firstSurvivors))
		{
			right++;
		}
		else
		{
			wrong++;
		}
	}

	bool swapped = wrong > right;
	if (swapped && CommandExists("sm_flipteams"))
	{
		ServerCommand("sm_flipteams");
		ServerExecute();
		swapped = false;
		CPrintToChatAll("%t %t", "Tag", "Teams Put Back");
	}

	// Points follow the people: the survivors now are the chapter's first survivors, unless
	// they came back swapped and couldn't be moved.
	int survivorScore = g_iChapterScore[swapped ? 1 - firstSurvivors : firstSurvivors];
	int infectedScore = g_iChapterScore[swapped ? firstSurvivors : 1 - firstSurvivors];
	SetScores(survivorScore, infectedScore);

	g_bRestorePending = false;

	char map[64];
	GetCurrentMap(map, sizeof(map));
	NoteChapter(map);
	TrackTeams();

	LogMessage("Map changed by force inside the campaign: scores kept (survivors %d, infected %d)", survivorScore, infectedScore);
	CPrintToChatAll("%t %t", "Tag", "Scores Kept", survivorScore, infectedScore);
}

// Same places SetScores (competitive repo) writes, plus the Versus Director's own copy.
void SetScores(int survivorScore, int infectedScore)
{
	int survivorTeam = GameRules_GetProp("m_bAreTeamsFlipped") != 0 ? 1 : 0;
	int scores[2];
	scores[survivorTeam] = survivorScore;
	scores[1 - survivorTeam] = infectedScore;

	for (int t = 0; t < 2; t++)
	{
		L4D2Direct_SetVSCampaignScore(t, scores[t]);
		GameRules_SetProp("m_iCampaignScore", scores[t], _, t);
	}

	if (GetFeatureStatus(FeatureType_Native, "L4D2_SetVersusCampaignScores") == FeatureStatus_Available)
	{
		L4D2_SetVersusCampaignScores(scores);
	}
}

// ---------------------------------------------------------------------------
// Forgetting the match when everyone leaves (back to the lobby, end of the night)
// ---------------------------------------------------------------------------

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		delete g_hForgetTimer;
	}
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client) || HumansExcept(client) > 0 || g_hForgetTimer != null)
	{
		return;
	}

	g_hForgetTimer = CreateTimer(FORGET_DELAY, Timer_Forget);
}

Action Timer_Forget(Handle timer)
{
	g_hForgetTimer = null;
	if (HumansExcept(0) == 0)
	{
		Forget();
	}

	return Plugin_Stop;
}

int HumansExcept(int skip)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != skip && IsClientConnected(i) && !IsFakeClient(i))
		{
			count++;
		}
	}

	return count;
}

void Forget()
{
	g_bHaveChapter = false;
	g_smCampaignTeam.Clear();
}

// ---------------------------------------------------------------------------
// Restart chapter / return to lobby
// ---------------------------------------------------------------------------

Action Cmd_RestartChapter(int client, int args)
{
	RestartChapter(client);
	return Plugin_Handled;
}

Action Cmd_ReturnToLobby(int client, int args)
{
	ReturnToLobby(client);
	return Plugin_Handled;
}

void RestartChapter(int admin)
{
	TrackTeams();
	LogAction(admin, -1, "\"%L\" restarted the chapter", admin);
	CPrintToChatAll("%t %t", "Tag", "Restart Soon", AdminName(admin), g_cvDelay.IntValue);
	CreateTimer(g_cvDelay.FloatValue, Timer_RestartChapter, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_RestartChapter(Handle timer)
{
	char map[64];
	GetCurrentMap(map, sizeof(map));
	L4D_RestartScenarioFromVote(map);
	return Plugin_Stop;
}

void ReturnToLobby(int admin)
{
	if (GetUserMessageId("DisconnectToLobby") == INVALID_MESSAGE_ID)
	{
		CReplyToCommand(admin, "%t %t", "Tag", "No Lobby Message");
		return;
	}

	LogAction(admin, -1, "\"%L\" sent everyone back to the lobby", admin);
	CPrintToChatAll("%t %t", "Tag", "Lobby Soon", AdminName(admin), g_cvDelay.IntValue);
	CreateTimer(g_cvDelay.FloatValue, Timer_ReturnToLobby, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ReturnToLobby(Handle timer)
{
	Forget();

	// lef_campaigns turns the end-of-campaign lobby into the next campaign; tell it this one is wanted.
	if (CommandExists("lef_campaigns_allow_lobby"))
	{
		ServerCommand("lef_campaigns_allow_lobby");
		ServerExecute();
	}

	// What the game does when its "Return to lobby" vote passes (Director::FinishScenarioExit).
	Handle msg = StartMessageAll("DisconnectToLobby", USERMSG_RELIABLE);
	if (msg != null)
	{
		EndMessage();
	}

	return Plugin_Stop;
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

// ---------------------------------------------------------------------------
// Admin menu: Server Commands
// ---------------------------------------------------------------------------

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	if (topmenu == g_hTopMenu)
	{
		return;
	}

	g_hTopMenu = topmenu;

	TopMenuObject category = g_hTopMenu.FindCategory(ADMINMENU_SERVERCOMMANDS);
	if (category == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	g_hTopMenu.AddItem("lef_match_restart", AdminItem_Handler, category, "sm_restartchapter", ADMFLAG_CHANGEMAP, "restart");
	g_hTopMenu.AddItem("lef_match_lobby", AdminItem_Handler, category, "sm_returntolobby", ADMFLAG_CHANGEMAP, "lobby");
}

void AdminItem_Handler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	char info[16];
	topmenu.GetInfoString(object_id, info, sizeof(info));

	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", StrEqual(info, "restart") ? "Menu Restart" : "Menu Lobby", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		ShowConfirm(param, info);
	}
}

void ShowConfirm(int client, const char[] what)
{
	Menu menu = new Menu(Confirm_Handler);
	menu.SetTitle("%T", StrEqual(what, "restart") ? "Confirm Restart" : "Confirm Lobby", client);

	char text[64];
	FormatEx(text, sizeof(text), "%T", "Yes", client);
	menu.AddItem(what, text);
	FormatEx(text, sizeof(text), "%T", "No", client);
	menu.AddItem("", text);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Confirm_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));

		if (StrEqual(info, "restart"))
		{
			RestartChapter(param1);
		}
		else if (StrEqual(info, "lobby"))
		{
			ReturnToLobby(param1);
		}
		else if (g_hTopMenu != null)
		{
			g_hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && g_hTopMenu != null)
	{
		g_hTopMenu.Display(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}
