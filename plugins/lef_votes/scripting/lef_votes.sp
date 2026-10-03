/**
 * Lefordianos Votes
 *
 * !votes: players decide things together on the game's own vote screen (F1 yes / F2 no).
 * Everything that can be voted is listed in configs/lef_votes.cfg, grouped (Maps, Teams, Players,
 * Rules, Game). Most entries just run a server command when the vote passes, so adding a vote
 * means adding an entry, no code. A few entry types need a menu first:
 *
 *   command  run "command" on the server if the vote passes (e.g. sm_forcet1 on)
 *   client   open another plugin's command for the player, no vote here (e.g. sm_votemode)
 *   map      pick a campaign and map (from the mission manager), then vote
 *   nextcampaign  pick a campaign, then vote; it's played after this one (needs lef_campaigns)
 *   mode     pick a game mode from Vote_Mode's list (data/l4d_votemode.cfg), then vote on the F1/F2
 *            screen; if it passes, Vote_Mode applies it (sm_forcemode). Hidden without Vote_Mode.
 *   restart  restart the current map, like the game's own vote
 *   kick     pick a player; kick plus a short ban (lef_votes_kick_ban_minutes, like vanilla's vote kick)
 *   spec     pick a player; move them to spectators (AFK)
 *   mute     pick a player; mute their voice and chat for the rest of the map
 *   pause    pause the game (pause.smx); while lef_votes_pause_by_vote is 1, players can't
 *            !pause directly: typing !pause starts this vote instead
 *
 * Admins (generic flag) get a "Lefordianos" category in !admin: run any entry instantly, force
 * pause / unpause, and pass or cancel the current vote. Admins can always !pause directly.
 *
 * Who voted: after every vote on the vote screen (the game's own, ours, or another plugin's), chat
 * lists who voted Yes and who voted No. Players send "Vote Yes" / "Vote No" for all of them, and the
 * VoteStart / VotePass / VoteFail messages mark the start and the end.
 *
 * Votes that change a setting (tank/witch chance, horde monitor, all talk) are remembered for the
 * session: every map change re-runs the server configs, which would undo them, so they are applied
 * again once the configs have run. Entries that replace each other share a "persist" key in the
 * config, so the latest one wins. Everything goes back to the configs once the server is empty.
 *
 * Next campaign: "nextcampaign" entries pick a campaign and vote it on the F1/F2 screen; if it passes,
 * lef_campaigns plays it after the current campaign (sm_setnextcampaign).
 *
 * Inspired by Harry Potter's archived l4d_votes_5 and the README of his private l4d2_vote_change
 * (custom votes defined in a config file).
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#include <builtinvotes>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <basecomm>
#include <l4d2_mission_manager>

#define PLUGIN_VERSION "1.3.0"
#define CONFIG_FILE    "configs/lef_votes.cfg"

#define TEAM_SPECTATOR 1
#define VOTE_NONE      0
#define VOTE_YES       1
#define VOTE_NO        2
#define TEAM_INFECTED  3
#define ZC_TANK        8

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Votes",
	author      = "rats4final; ideas from Harry Potter's l4d_votes_5 / l4d2_vote_change",
	description = "Config-driven votes on the game's vote screen, plus an admin category",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

enum struct VoteGroup
{
	char key[32];
	char titleEn[64];
	char titleEs[64];
}

enum struct VoteItem
{
	int  group;
	char key[32];
	char titleEn[96];
	char titleEs[96];
	char type[16];
	char command[256];
	bool adminOnly;
	char persist[32];   // remember this command for the session under this key ("" = don't)
	bool finaleOnly;    // only shown on a campaign's last map (e.g. ACS's next-campaign vote)
}

ArrayList g_aGroups;
ArrayList g_aItems;

ConVar
	g_cvPassPercent,
	g_cvMinPlayers,
	g_cvVoteTime,
	g_cvSpecCall,
	g_cvSpecJoin,
	g_cvKickBanMinutes,
	g_cvImmuneFlags,
	g_cvPauseByVote,
	g_cvShowVoters;

// Settings changed by vote or admin, re-applied after each map's configs: persist key -> command.
StringMap g_smSession;

// Who voted what on the vote screen right now (any vote, not only ours).
bool  g_bTrackingVote;
float g_fTrackingSince;
int   g_iVoteChoice[MAXPLAYERS + 1];

// The vote on screen right now (ours).
Handle g_hVote;
int    g_iVoteItem = -1;
int    g_iVoteInitiator;     // userid
int    g_iVoteTarget;        // userid, for player votes
char   g_sVoteMap[64];       // for map votes
char   g_sVoteTitle[192];
bool   g_bAdminPassed;       // an admin passed it: show "passed" instead of "failed" when it closes

// Menu flow, per client.
bool g_bAdminMode[MAXPLAYERS + 1];   // true = run instantly (admin menu), false = start a vote
int  g_iMenuItem[MAXPLAYERS + 1];
int  g_iMenuMission[MAXPLAYERS + 1];
char g_sMenuModeGroup[MAXPLAYERS + 1][64];
bool g_bPauseAllowed[MAXPLAYERS + 1];

TopMenu       g_hTopMenu;
TopMenuObject g_tmoCategory = INVALID_TOPMENUOBJECT;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	MarkNativeAsOptional("BaseComm_SetClientMute");
	MarkNativeAsOptional("BaseComm_SetClientGag");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("lef_votes.phrases");

	CreateConVar("lef_votes_version", PLUGIN_VERSION, "Lefordianos Votes version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvPassPercent    = CreateConVar("lef_votes_pass_percent", "50", "A vote passes when more than this percent of the votes cast are Yes.", _, true, 0.0, true, 100.0);
	g_cvMinPlayers     = CreateConVar("lef_votes_min_players", "1", "Players needed on the server to start a vote.", _, true, 1.0);
	g_cvVoteTime       = CreateConVar("lef_votes_time", "20", "Seconds a vote stays on screen.", _, true, 5.0, true, 60.0);
	g_cvSpecCall       = CreateConVar("lef_votes_spectators_call", "0", "Spectators can start votes.", _, true, 0.0, true, 1.0);
	g_cvSpecJoin       = CreateConVar("lef_votes_spectators_vote", "1", "Spectators can vote Yes/No.", _, true, 0.0, true, 1.0);
	g_cvKickBanMinutes = CreateConVar("lef_votes_kick_ban_minutes", "5", "A vote kick also bans for this many minutes, like vanilla's vote kick. 0 = kick only.", _, true, 0.0);
	g_cvImmuneFlags    = CreateConVar("lef_votes_immune_flags", "b", "Admins with any of these flags can't be vote-kicked, moved or muted.");
	g_cvPauseByVote    = CreateConVar("lef_votes_pause_by_vote", "1", "Players (not admins) can only pause through a vote; typing !pause starts it.", _, true, 0.0, true, 1.0);
	g_cvShowVoters     = CreateConVar("lef_votes_show_voters", "1", "After every vote on the vote screen, list who voted Yes and No. 0 = off, 1 = at the end, 2 = also each vote as it comes in.", _, true, 0.0, true, 2.0);
	AutoExecConfig(true, "lef_votes");

	RegConsoleCmd("sm_votes", Cmd_Votes, "Open the vote menu");
	RegAdminCmd("sm_votes_reload", Cmd_Reload, ADMFLAG_CONFIG, "Reload configs/lef_votes.cfg");
	RegAdminCmd("sm_vp", Cmd_PassVote, ADMFLAG_GENERIC, "Pass the current !votes vote");
	RegAdminCmd("sm_vc", Cmd_CancelVote, ADMFLAG_GENERIC, "Cancel the current vote");

	AddCommandListener(Listener_Pause, "sm_pause");
	AddCommandListener(Listener_Vote, "Vote");
	HookUserMessage(GetUserMessageId("VoteStart"), Message_VoteStart);
	HookUserMessage(GetUserMessageId("VotePass"), Message_VoteEnd);
	HookUserMessage(GetUserMessageId("VoteFail"), Message_VoteEnd);

	g_aGroups = new ArrayList(sizeof(VoteGroup));
	g_aItems  = new ArrayList(sizeof(VoteItem));
	g_smSession = new StringMap();
	LoadConfig();

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
	g_bPauseAllowed[client] = false;
	g_iVoteChoice[client]   = VOTE_NONE;
}

public void OnMapStart()
{
	g_bTrackingVote     = false;
}

// ---------------------------------------------------------------------------
// Session settings: re-apply voted settings after each map's configs
// ---------------------------------------------------------------------------

public void OnConfigsExecuted()
{
	StringMapSnapshot snap = g_smSession.Snapshot();
	char key[32], command[256];
	for (int i = 0; i < snap.Length; i++)
	{
		snap.GetKey(i, key, sizeof(key));
		if (g_smSession.GetString(key, command, sizeof(command)))
		{
			ServerCommand("%s", command);
		}
	}
	delete snap;
}

public void OnClientDisconnect_Post(int client)
{
	// Map changes disconnect everyone for a moment too, so wait before deciding the server is empty.
	if (!AnyHumanConnected())
	{
		CreateTimer(60.0, Timer_CheckEmpty);
	}
}

Action Timer_CheckEmpty(Handle timer)
{
	if (!AnyHumanConnected() && g_smSession.Size > 0)
	{
		g_smSession.Clear();
		LogMessage("Server empty: voted settings forgotten, back to the configs from the next map");
	}
	return Plugin_Stop;
}

bool AnyHumanConnected()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			return true;
		}
	}
	return false;
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

void LoadConfig()
{
	g_aGroups.Clear();
	g_aItems.Clear();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), CONFIG_FILE);

	KeyValues kv = new KeyValues("Votes");
	if (!kv.ImportFromFile(path))
	{
		LogError("Couldn't read %s; no votes available", CONFIG_FILE);
		delete kv;
		return;
	}

	if (kv.GotoFirstSubKey())
	{
		do
		{
			VoteGroup group;
			kv.GetSectionName(group.key, sizeof(group.key));
			ReadTitle(kv, group.titleEn, sizeof(group.titleEn), group.titleEs, sizeof(group.titleEs), group.key);
			int groupIndex = g_aGroups.PushArray(group);

			if (kv.GotoFirstSubKey())
			{
				do
				{
					char key[32];
					kv.GetSectionName(key, sizeof(key));
					if (StrEqual(key, "title") || kv.GetNum("enabled", 1) == 0)
					{
						continue;
					}

					VoteItem item;
					item.group = groupIndex;
					strcopy(item.key, sizeof(item.key), key);
					ReadTitle(kv, item.titleEn, sizeof(item.titleEn), item.titleEs, sizeof(item.titleEs), key);
					kv.GetString("type", item.type, sizeof(item.type), "command");
					kv.GetString("command", item.command, sizeof(item.command));
					item.adminOnly = kv.GetNum("admin_only", 0) != 0;
					kv.GetString("persist", item.persist, sizeof(item.persist));
					item.finaleOnly = kv.GetNum("finale_only", 0) != 0;
					g_aItems.PushArray(item);
				}
				while (kv.GotoNextKey());
				kv.GoBack();
			}
		}
		while (kv.GotoNextKey());
	}

	delete kv;
}

// Reads a "title" { "en" "..." "es" "..." } subsection of the current key.
void ReadTitle(KeyValues kv, char[] en, int enLen, char[] es, int esLen, const char[] fallback)
{
	strcopy(en, enLen, fallback);
	strcopy(es, esLen, "");
	if (kv.JumpToKey("title"))
	{
		kv.GetString("en", en, enLen, fallback);
		kv.GetString("es", es, esLen, "");
		kv.GoBack();
	}
	if (es[0] == '\0')
	{
		strcopy(es, esLen, en);
	}
}

bool UsesSpanish(int client)
{
	char code[8], name[32];
	int lang = (client > 0 && IsClientInGame(client)) ? GetClientLanguage(client) : GetServerLanguage();
	GetLanguageInfo(lang, code, sizeof(code), name, sizeof(name));
	return StrEqual(code, "es") || StrEqual(code, "las");   // Spain or Latin America
}

void GroupTitle(int index, int client, char[] buffer, int maxlength)
{
	VoteGroup group;
	g_aGroups.GetArray(index, group);
	strcopy(buffer, maxlength, UsesSpanish(client) ? group.titleEs : group.titleEn);
}

void ItemTitle(int index, int client, char[] buffer, int maxlength)
{
	VoteItem item;
	g_aItems.GetArray(index, item);
	strcopy(buffer, maxlength, UsesSpanish(client) ? item.titleEs : item.titleEn);
}

Action Cmd_Reload(int client, int args)
{
	LoadConfig();
	ReplyToCommand(client, "[Votes] %d vote(s) in %d group(s) loaded.", g_aItems.Length, g_aGroups.Length);
	return Plugin_Handled;
}

// ---------------------------------------------------------------------------
// Menus (shared by players and admins; admins run things instantly)
// ---------------------------------------------------------------------------

Action Cmd_Votes(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[Votes] This command is for players.");
		return Plugin_Handled;
	}

	g_bAdminMode[client] = false;
	ShowGroups(client);
	return Plugin_Handled;
}

void ShowGroups(int client)
{
	Menu menu = new Menu(Groups_Handler);
	char title[64], text[64], info[8];

	FormatEx(title, sizeof(title), "%T", g_bAdminMode[client] ? "Menu Title Admin" : "Menu Title", client);
	menu.SetTitle(title);
	menu.ExitBackButton = g_bAdminMode[client] && g_hTopMenu != null;

	for (int g = 0; g < g_aGroups.Length; g++)
	{
		if (CountVisibleItems(g, client) == 0)
		{
			continue;
		}
		GroupTitle(g, client, text, sizeof(text));
		IntToString(g, info, sizeof(info));
		menu.AddItem(info, text);
	}

	if (menu.ItemCount == 0)
	{
		CPrintToChat(client, "%T", "No Votes", client);
		delete menu;
		return;
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

int CountVisibleItems(int group, int client)
{
	int count;
	VoteItem item;
	for (int i = 0; i < g_aItems.Length; i++)
	{
		g_aItems.GetArray(i, item);
		if (item.group == group && IsItemVisible(item, client))
		{
			count++;
		}
	}
	return count;
}

bool IsItemVisible(VoteItem item, int client)
{
	if (item.adminOnly && !g_bAdminMode[client])
	{
		return false;
	}
	if (item.finaleOnly && !L4D_IsMissionFinalMap())
	{
		return false;
	}
	// "client" entries open another plugin's command; hide them if that plugin isn't loaded.
	if (StrEqual(item.type, "client") && !CommandExists(item.command))
	{
		return false;
	}
	// Next campaign votes need lef_campaigns.
	if (StrEqual(item.type, "nextcampaign") && !CommandExists("sm_setnextcampaign"))
	{
		return false;
	}
	// Game mode votes need Vote_Mode (its list and its sm_forcemode).
	if (StrEqual(item.type, "mode") && !CommandExists("sm_forcemode"))
	{
		return false;
	}
	// In the admin menu, the pause entry is replaced by force pause/unpause. Hidden without pause.smx.
	if (StrEqual(item.type, "pause") && (g_bAdminMode[client] || !CommandExists("sm_pause")))
	{
		return false;
	}
	return true;
}

int Groups_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ReturnToAdminCategory(client);
	}
	else if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));
		ShowItems(client, StringToInt(info));
	}
	return 0;
}

void ShowItems(int client, int group)
{
	Menu menu = new Menu(Items_Handler);
	char title[64], text[96], info[8];

	GroupTitle(group, client, title, sizeof(title));
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	VoteItem item;
	for (int i = 0; i < g_aItems.Length; i++)
	{
		g_aItems.GetArray(i, item);
		if (item.group != group || !IsItemVisible(item, client))
		{
			continue;
		}
		ItemTitle(i, client, text, sizeof(text));
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, text);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

int Items_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowGroups(client);
	}
	else if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));
		ChooseItem(client, StringToInt(info));
	}
	return 0;
}

void ChooseItem(int client, int index)
{
	VoteItem item;
	g_aItems.GetArray(index, item);
	g_iMenuItem[client] = index;

	if (StrEqual(item.type, "client"))
	{
		FakeClientCommand(client, item.command);
	}
	else if (StrEqual(item.type, "map") || StrEqual(item.type, "nextcampaign"))
	{
		ShowMissions(client);
	}
	else if (StrEqual(item.type, "mode"))
	{
		ShowModeGroups(client);
	}
	else if (StrEqual(item.type, "kick") || StrEqual(item.type, "spec") || StrEqual(item.type, "mute"))
	{
		ShowPlayers(client);
	}
	else
	{
		Proceed(client, index, 0, "", "");
	}
}

// --- Player picker ---

void ShowPlayers(int client)
{
	Menu menu = new Menu(Players_Handler);
	char title[96], name[MAX_NAME_LENGTH], info[16];

	ItemTitle(g_iMenuItem[client], client, title, sizeof(title));
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		GetClientName(i, name, sizeof(name));
		IntToString(GetClientUserId(i), info, sizeof(info));
		menu.AddItem(info, name, IsImmune(i) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}

	if (menu.ItemCount == 0)
	{
		CPrintToChat(client, "%T", "No Players", client);
		delete menu;
		return;
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

int Players_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		VoteItem item;
		g_aItems.GetArray(g_iMenuItem[client], item);
		ShowItems(client, item.group);
	}
	else if (action == MenuAction_Select)
	{
		char info[16];
		menu.GetItem(param, info, sizeof(info));
		int target = GetClientOfUserId(StringToInt(info));
		if (target == 0)
		{
			CPrintToChat(client, "%T", "Player Gone", client);
			return 0;
		}

		char name[MAX_NAME_LENGTH];
		GetClientName(target, name, sizeof(name));
		Proceed(client, g_iMenuItem[client], GetClientUserId(target), "", name);
	}
	return 0;
}

bool IsImmune(int client)
{
	char flags[32];
	g_cvImmuneFlags.GetString(flags, sizeof(flags));
	int bits = ReadFlagString(flags);
	return bits != 0 && (GetUserFlagBits(client) & (bits | ADMFLAG_ROOT)) != 0;
}

// --- Game mode picker (Vote_Mode's list) ---

KeyValues LoadModeList()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/l4d_votemode.cfg");
	KeyValues kv = new KeyValues("gamemodes");
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		return null;
	}
	return kv;
}

void ShowModeGroups(int client)
{
	KeyValues kv = LoadModeList();
	if (kv == null)
	{
		CPrintToChat(client, "%T", "No Mode List", client);
		return;
	}

	Menu menu = new Menu(ModeGroups_Handler);
	char title[96], group[64];
	ItemTitle(g_iMenuItem[client], client, title, sizeof(title));
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	if (kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetSectionName(group, sizeof(group));
			menu.AddItem(group, group);
		}
		while (kv.GotoNextKey());
	}
	delete kv;
	menu.Display(client, MENU_TIME_FOREVER);
}

int ModeGroups_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		VoteItem item;
		g_aItems.GetArray(g_iMenuItem[client], item);
		ShowItems(client, item.group);
	}
	else if (action == MenuAction_Select)
	{
		menu.GetItem(param, g_sMenuModeGroup[client], sizeof(g_sMenuModeGroup[]));
		ShowModes(client);
	}
	return 0;
}

void ShowModes(int client)
{
	KeyValues kv = LoadModeList();
	if (kv == null || !kv.JumpToKey(g_sMenuModeGroup[client]))
	{
		delete kv;
		return;
	}

	Menu menu = new Menu(Modes_Handler);
	menu.SetTitle(g_sMenuModeGroup[client]);
	menu.ExitBackButton = true;

	char display[64], code[64], current[64];
	FindConVar("mp_gamemode").GetString(current, sizeof(current));
	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			kv.GetSectionName(display, sizeof(display));
			kv.GetString(NULL_STRING, code, sizeof(code));
			// The current mode can't be picked.
			menu.AddItem(code, display, StrEqual(code, current, false) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
		while (kv.GotoNextKey(false));
	}
	delete kv;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Modes_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowModeGroups(client);
	}
	else if (action == MenuAction_Select)
	{
		char code[64], display[64];
		menu.GetItem(param, code, sizeof(code), _, display, sizeof(display));
		Proceed(client, g_iMenuItem[client], 0, code, display);
	}
	return 0;
}

// --- Map picker (mission manager) ---

bool MissionManagerReady()
{
	return GetFeatureStatus(FeatureType_Native, "LMM_GetNumberOfMissions") == FeatureStatus_Available;
}

LMM_GAMEMODE CurrentMode()
{
	LMM_GAMEMODE mode = LMM_GetCurrentGameMode();
	return mode == LMM_GAMEMODE_UNKNOWN ? LMM_GAMEMODE_COOP : mode;
}

void ShowMissions(int client)
{
	if (!MissionManagerReady())
	{
		CPrintToChat(client, "%T", "No Mission Manager", client);
		return;
	}

	Menu menu = new Menu(Missions_Handler);
	char title[96], text[128], info[8];
	ItemTitle(g_iMenuItem[client], client, title, sizeof(title));
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	LMM_GAMEMODE mode = CurrentMode();
	int count = LMM_GetNumberOfMissions(mode);
	for (int m = 0; m < count; m++)
	{
		LMM_GetMissionLocalizedDisplayTitle(mode, m, text, sizeof(text), client);
		IntToString(m, info, sizeof(info));
		menu.AddItem(info, text);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

int Missions_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		VoteItem item;
		g_aItems.GetArray(g_iMenuItem[client], item);
		ShowItems(client, item.group);
	}
	else if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));
		g_iMenuMission[client] = StringToInt(info);

		VoteItem item;
		g_aItems.GetArray(g_iMenuItem[client], item);
		if (StrEqual(item.type, "nextcampaign"))
		{
			// The whole campaign: its first map, named by its title.
			char map[64], title[128];
			LMM_GAMEMODE mode = CurrentMode();
			LMM_GetMapName(mode, g_iMenuMission[client], 0, map, sizeof(map));
			LMM_GetMissionLocalizedDisplayTitle(mode, g_iMenuMission[client], title, sizeof(title), LANG_SERVER);
			Proceed(client, g_iMenuItem[client], 0, map, title);
		}
		else
		{
			ShowMaps(client);
		}
	}
	return 0;
}

void ShowMaps(int client)
{
	Menu menu = new Menu(Maps_Handler);
	char title[128], text[128], map[64];
	LMM_GAMEMODE mode = CurrentMode();
	int mission = g_iMenuMission[client];

	LMM_GetMissionLocalizedDisplayTitle(mode, mission, title, sizeof(title), client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	int count = LMM_GetNumberOfMaps(mode, mission);
	for (int i = 0; i < count; i++)
	{
		LMM_GetMapName(mode, mission, i, map, sizeof(map));
		LMM_GetMapLocalizedDisplayName(mode, mission, i, text, sizeof(text), client);
		Format(text, sizeof(text), "%d. %s", i + 1, text);
		menu.AddItem(map, text);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

int Maps_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowMissions(client);
	}
	else if (action == MenuAction_Select)
	{
		char map[64], display[128];
		menu.GetItem(param, map, sizeof(map), _, display, sizeof(display));
		if (!IsMapValid(map))
		{
			CPrintToChat(client, "%T", "Map Invalid", client, map);
			return 0;
		}
		Proceed(client, g_iMenuItem[client], 0, map, display);
	}
	return 0;
}

// ---------------------------------------------------------------------------
// Starting a vote, or running it right away for admins
// ---------------------------------------------------------------------------

// detail = player name or map display name, shown after the title.
void Proceed(int client, int index, int targetUserId, const char[] map, const char[] detail)
{
	if (g_bAdminMode[client])
	{
		char title[192];
		ItemTitle(index, LANG_SERVER, title, sizeof(title));
		LogAction(client, -1, "\"%L\" ran \"%s %s\" from the admin menu", client, title, detail);
		Execute(index, client, targetUserId, map);
		ReturnToAdminCategory(client);
		return;
	}

	StartVote(client, index, targetUserId, map, detail);
}

bool StartVote(int client, int index, int targetUserId, const char[] map, const char[] detail)
{
	if (GetClientTeam(client) <= TEAM_SPECTATOR && !g_cvSpecCall.BoolValue)
	{
		CPrintToChat(client, "%T", "Spectators Cannot Call", client);
		return false;
	}
	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(client, "%T", "Busy", client);
		return false;
	}
	int delay = CheckBuiltinVoteDelay();
	if (delay > 0)
	{
		CPrintToChat(client, "%T", "Vote Delay", client, delay);
		return false;
	}

	int[] voters = new int[MaxClients];
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) > TEAM_SPECTATOR || g_cvSpecJoin.BoolValue))
		{
			voters[count++] = i;
		}
	}
	if (count < g_cvMinPlayers.IntValue)
	{
		CPrintToChat(client, "%T", "Not Enough Players", client, g_cvMinPlayers.IntValue);
		return false;
	}

	// The vote screen shows one text for everyone, in the server's language.
	ItemTitle(index, LANG_SERVER, g_sVoteTitle, sizeof(g_sVoteTitle));
	if (detail[0] != '\0')
	{
		Format(g_sVoteTitle, sizeof(g_sVoteTitle), "%s: %s", g_sVoteTitle, detail);
	}
	StrCat(g_sVoteTitle, sizeof(g_sVoteTitle), "?");

	g_iVoteItem      = index;
	g_iVoteInitiator = GetClientUserId(client);
	g_iVoteTarget    = targetUserId;
	strcopy(g_sVoteMap, sizeof(g_sVoteMap), map);

	g_hVote = CreateBuiltinVote(VoteAction_Handler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(g_hVote, g_sVoteTitle);
	SetBuiltinVoteInitiator(g_hVote, client);
	SetBuiltinVoteResultCallback(g_hVote, VoteResult_Handler);
	DisplayBuiltinVote(g_hVote, voters, count, g_cvVoteTime.IntValue);
	FakeClientCommand(client, "Vote Yes");

	LogAction(client, -1, "\"%L\" started a vote: %s", client, g_sVoteTitle);
	return true;
}

void VoteAction_Handler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			delete vote;
			g_hVote = null;
			g_iVoteItem = -1;
		}
		case BuiltinVoteAction_Cancel:
		{
			if (g_bAdminPassed)
			{
				char passed[64];
				FormatEx(passed, sizeof(passed), "%T", "Vote Passed Screen", LANG_SERVER);
				DisplayBuiltinVotePass(vote, passed);
			}
			else
			{
				DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
			}
			g_bAdminPassed = false;
		}
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

	if (num_votes > 0 && float(yes) > float(num_votes) * g_cvPassPercent.FloatValue / 100.0)
	{
		char passed[64];
		FormatEx(passed, sizeof(passed), "%T", "Vote Passed Screen", LANG_SERVER);
		DisplayBuiltinVotePass(vote, passed);
		CPrintToChatAll("%t", "Vote Passed", g_sVoteTitle);
		Execute(g_iVoteItem, GetClientOfUserId(g_iVoteInitiator), g_iVoteTarget, g_sVoteMap);
	}
	else
	{
		DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
		CPrintToChatAll("%t", "Vote Failed", g_sVoteTitle);
	}
}

// ---------------------------------------------------------------------------
// What each entry does
// ---------------------------------------------------------------------------

void Execute(int index, int initiator, int targetUserId, const char[] map)
{
	VoteItem item;
	g_aItems.GetArray(index, item);
	int target = targetUserId != 0 ? GetClientOfUserId(targetUserId) : 0;

	if (StrEqual(item.type, "command"))
	{
		ServerCommand("%s", item.command);
		if (item.persist[0] != '\0')
		{
			g_smSession.SetString(item.persist, item.command);
		}
	}
	else if (StrEqual(item.type, "restart"))
	{
		char current[64];
		GetCurrentMap(current, sizeof(current));
		L4D_RestartScenarioFromVote(current);
	}
	else if (StrEqual(item.type, "map"))
	{
		L4D_RestartScenarioFromVote(map);
	}
	else if (StrEqual(item.type, "mode"))
	{
		ServerCommand("sm_forcemode %s", map);   // Vote_Mode changes the mode and restarts the map
	}
	else if (StrEqual(item.type, "nextcampaign"))
	{
		ServerCommand("sm_setnextcampaign %s", map);   // lef_campaigns plays it after this campaign
	}
	else if (StrEqual(item.type, "kick"))
	{
		if (target == 0)
		{
			return;
		}
		int minutes = g_cvKickBanMinutes.IntValue;
		char name[MAX_NAME_LENGTH];
		GetClientName(target, name, sizeof(name));
		LogAction(initiator, target, "\"%L\" was vote-kicked (ban: %d min)", target, minutes);
		if (minutes > 0)
		{
			char reason[128];
			FormatEx(reason, sizeof(reason), "%T", "Kick Reason Ban", target, minutes);
			CPrintToChatAll("%t", "Kicked Ban", name, minutes);
			BanClient(target, minutes, BANFLAG_AUTO, "Vote kick (lef_votes)", reason, "sm_votes", initiator);
		}
		else
		{
			CPrintToChatAll("%t", "Kicked", name);
			KickClient(target, "%T", "Kick Reason", target);
		}
	}
	else if (StrEqual(item.type, "spec"))
	{
		if (target != 0 && GetClientTeam(target) > TEAM_SPECTATOR)
		{
			// A living Special Infected dies instead of going to the AI; a Tank is left to the game.
			if (GetClientTeam(target) == TEAM_INFECTED && IsPlayerAlive(target) && GetEntProp(target, Prop_Send, "m_zombieClass") != ZC_TANK)
			{
				ForcePlayerSuicide(target);
			}
			ChangeClientTeam(target, TEAM_SPECTATOR);
		}
	}
	else if (StrEqual(item.type, "mute"))
	{
		if (target != 0 && GetFeatureStatus(FeatureType_Native, "BaseComm_SetClientMute") == FeatureStatus_Available)
		{
			BaseComm_SetClientMute(target, true);
			BaseComm_SetClientGag(target, true);
		}
	}
	else if (StrEqual(item.type, "pause"))
	{
		DoPause(initiator);
	}
}

// ---------------------------------------------------------------------------
// Pause only by vote
// ---------------------------------------------------------------------------

Action Listener_Pause(int client, const char[] command, int argc)
{
	if (client == 0 || !g_cvPauseByVote.BoolValue || CheckCommandAccess(client, "lef_votes_pause_direct", ADMFLAG_GENERIC))
	{
		return Plugin_Continue;
	}

	if (g_bPauseAllowed[client])
	{
		g_bPauseAllowed[client] = false;
		return Plugin_Continue;
	}

	// Typing !pause starts the pause vote instead.
	int index = FindItemByType("pause");
	if (index == -1)
	{
		CPrintToChat(client, "%T", "Pause Disabled", client);
	}
	else
	{
		CPrintToChat(client, "%T", "Pause Needs Vote", client);
		StartVote(client, index, 0, "", "");
	}
	return Plugin_Handled;
}

void DoPause(int initiator)
{
	// Pause as a player on a team (pause.smx's normal pause: both teams ready up to unpause).
	int who = (initiator > 0 && IsClientInGame(initiator) && GetClientTeam(initiator) > TEAM_SPECTATOR) ? initiator : 0;
	for (int i = 1; who == 0 && i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > TEAM_SPECTATOR)
		{
			who = i;
		}
	}
	if (who == 0)
	{
		return;
	}
	g_bPauseAllowed[who] = true;
	FakeClientCommand(who, "sm_pause");
}

int FindItemByType(const char[] type)
{
	VoteItem item;
	for (int i = 0; i < g_aItems.Length; i++)
	{
		g_aItems.GetArray(i, item);
		if (StrEqual(item.type, type))
		{
			return i;
		}
	}
	return -1;
}

// ---------------------------------------------------------------------------
// Who voted what
// ---------------------------------------------------------------------------

// VoteStart: team (byte), initiator (byte), issue, param, initiator name. The game counts the
// initiator as Yes without them sending "Vote Yes", so we do the same.
Action Message_VoteStart(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	// A vote being redrawn for one player (late joiner) sends VoteStart again: keep the tally.
	if (g_bTrackingVote && GetGameTime() - g_fTrackingSince < 120.0)
	{
		return Plugin_Continue;
	}

	msg.ReadByte();
	int initiator = msg.ReadByte();

	g_bTrackingVote  = true;
	g_fTrackingSince = GetGameTime();
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iVoteChoice[i] = VOTE_NONE;
	}
	if (initiator > 0 && initiator <= MaxClients)
	{
		g_iVoteChoice[initiator] = VOTE_YES;
	}
	return Plugin_Continue;
}

Action Listener_Vote(int client, const char[] command, int argc)
{
	if (!g_bTrackingVote || client <= 0 || client > MaxClients || g_iVoteChoice[client] != VOTE_NONE || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}

	char arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	if (StrEqual(arg, "Yes", false))
	{
		g_iVoteChoice[client] = VOTE_YES;
	}
	else if (StrEqual(arg, "No", false))
	{
		g_iVoteChoice[client] = VOTE_NO;
	}
	else
	{
		return Plugin_Continue;
	}

	if (g_cvShowVoters.IntValue == 2 && !IsFakeClient(client))
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		CPrintToChatAll("%t", g_iVoteChoice[client] == VOTE_YES ? "Voted Yes" : "Voted No", name);
	}
	return Plugin_Continue;
}

Action Message_VoteEnd(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (g_bTrackingVote)
	{
		g_bTrackingVote = false;
		// Can't print from inside a message hook; do it next frame.
		RequestFrame(Frame_PrintVoters);
	}
	return Plugin_Continue;
}

void Frame_PrintVoters()
{
	if (g_cvShowVoters.IntValue == 0)
	{
		return;
	}

	char yes[256], no[256], name[MAX_NAME_LENGTH];
	int yesCount, noCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_iVoteChoice[i] == VOTE_NONE || !IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		GetClientName(i, name, sizeof(name));
		if (g_iVoteChoice[i] == VOTE_YES)
		{
			Format(yes, sizeof(yes), "%s%s%s", yes, yesCount++ > 0 ? ", " : "", name);
		}
		else
		{
			Format(no, sizeof(no), "%s%s%s", no, noCount++ > 0 ? ", " : "", name);
		}
	}

	if (yesCount + noCount == 0)
	{
		return;
	}
	if (yes[0] == '\0')
	{
		strcopy(yes, sizeof(yes), "-");
	}
	if (no[0] == '\0')
	{
		strcopy(no, sizeof(no), "-");
	}
	CPrintToChatAll("%t", "Voters", yesCount, yes, noCount, no);
}

// ---------------------------------------------------------------------------
// Admin: pass / cancel, and the "Lefordianos" category in !admin
// ---------------------------------------------------------------------------

Action Cmd_PassVote(int client, int args)
{
	if (g_hVote == null || g_iVoteItem == -1)
	{
		ReplyToCommand(client, "[Votes] %T", "No Own Vote", client == 0 ? LANG_SERVER : client);
		return Plugin_Handled;
	}

	int index = g_iVoteItem, initiator = GetClientOfUserId(g_iVoteInitiator), target = g_iVoteTarget;
	char map[64];
	strcopy(map, sizeof(map), g_sVoteMap);

	LogAction(client, -1, "\"%L\" passed the vote: %s", client, g_sVoteTitle);
	CPrintToChatAll("%t", "Vote Passed Admin", g_sVoteTitle);
	g_bAdminPassed = true;
	CancelBuiltinVote();
	Execute(index, initiator, target, map);
	return Plugin_Handled;
}

Action Cmd_CancelVote(int client, int args)
{
	if (!IsBuiltinVoteInProgress())
	{
		ReplyToCommand(client, "[Votes] %T", "No Vote", client == 0 ? LANG_SERVER : client);
		return Plugin_Handled;
	}

	LogAction(client, -1, "\"%L\" cancelled the current vote", client);
	CPrintToChatAll("%t", "Vote Cancelled Admin");
	CancelBuiltinVote();
	return Plugin_Handled;
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	if (topmenu == g_hTopMenu)
	{
		return;
	}

	g_hTopMenu    = topmenu;
	g_tmoCategory = g_hTopMenu.AddCategory("lefordianos", AdminCategory_Handler, "lef_votes_admin", ADMFLAG_GENERIC);
	if (g_tmoCategory == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	g_hTopMenu.AddItem("lef_votes_run", AdminItem_Handler, g_tmoCategory, "lef_votes_admin", ADMFLAG_GENERIC, "run");
	g_hTopMenu.AddItem("lef_votes_forcepause", AdminItem_Handler, g_tmoCategory, "sm_forcepause", ADMFLAG_BAN, "forcepause");
	g_hTopMenu.AddItem("lef_votes_forceunpause", AdminItem_Handler, g_tmoCategory, "sm_forceunpause", ADMFLAG_BAN, "forceunpause");
	g_hTopMenu.AddItem("lef_votes_pass", AdminItem_Handler, g_tmoCategory, "sm_vp", ADMFLAG_GENERIC, "pass");
	g_hTopMenu.AddItem("lef_votes_cancel", AdminItem_Handler, g_tmoCategory, "sm_vc", ADMFLAG_GENERIC, "cancel");
}

void AdminCategory_Handler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle || action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "Admin Category", param);
	}
}

void AdminItem_Handler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	char info[16], phrase[32];
	topmenu.GetInfoString(object_id, info, sizeof(info));

	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(phrase, sizeof(phrase), "Admin %s", info);
		FormatEx(buffer, maxlength, "%T", phrase, param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (StrEqual(info, "run"))
		{
			g_bAdminMode[param] = true;
			ShowGroups(param);
			return;
		}

		if (StrEqual(info, "forcepause"))
		{
			FakeClientCommand(param, "sm_forcepause");
		}
		else if (StrEqual(info, "forceunpause"))
		{
			FakeClientCommand(param, "sm_forceunpause");
		}
		else if (StrEqual(info, "pass"))
		{
			Cmd_PassVote(param, 0);
		}
		else if (StrEqual(info, "cancel"))
		{
			Cmd_CancelVote(param, 0);
		}
		ReturnToAdminCategory(param);
	}
}

void ReturnToAdminCategory(int client)
{
	if (g_hTopMenu != null && g_tmoCategory != INVALID_TOPMENUOBJECT && IsClientInGame(client))
	{
		g_hTopMenu.DisplayCategory(g_tmoCategory, client);
	}
}
