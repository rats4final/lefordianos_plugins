/**
 * Lefordianos T1 Mode
 *
 * A switchable "only T1 weapons" mode. Which weapons get replaced, and by what, is set in
 * configs/lef_t1_mode.cfg. By default rifles, auto shotguns and the 15/30-round snipers are
 * replaced; the Scout, AWP, grenade launcher and M60 stay.
 *
 * Turn it on or off with:
 *  - the cvar lef_t1_enable,
 *  - an admin command: sm_forcet1 <on|off>,
 *  - a vote on the game's vote screen: !t1 (needs the builtinvotes extension).
 *
 * The change applies right away while the survivors are still in the starting saferoom, and from
 * the next round otherwise. When active it converts weapon spawns at round start, weapons created
 * later, and any banned weapon a survivor picks up or carries over from the previous map.
 *
 * Works with or without confogl. Weapon conversion uses l4d2util's stocks, the same ones the
 * competitive repo's l4d2_weaponrules uses, but keeps its own rule list so it never clears
 * another mode's weapon rules.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>
#undef REQUIRE_EXTENSIONS
#include <builtinvotes>

#define PLUGIN_VERSION "1.0.0"

#define CONFIG_FILE    "configs/lef_t1_mode.cfg"

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos T1 Mode",
	author      = "rats4final; weapon stocks from l4d2util (ProdigySim, Visor, A1m` and others)",
	description = "Switchable T1-only weapons mode, by cvar, admin or vote",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

// CS:S weapons that must be precached before a spawn can be turned into them.
static const int g_iCSWeapons[] = { WEPID_SMG_MP5, WEPID_RIFLE_SG552, WEPID_SNIPER_AWP, WEPID_SNIPER_SCOUT };

ConVar
	g_cvEnable,
	g_cvConvertHeld,
	g_cvVoteTime;

int  g_iRule[WEPID_SIZE];    // replacement weapon id, WEPID_NONE = remove, -1 = allowed
bool g_bActive;              // the mode as applied to the current round
Handle g_hVote;
bool g_bVoteTarget;          // what the running vote would switch to

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
	LoadTranslations("lef_t1_mode.phrases");

	CreateConVar("lef_t1_mode_version", PLUGIN_VERSION, "Lefordianos T1 Mode version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvEnable      = CreateConVar("lef_t1_enable", "0", "T1-only mode. Applies now if survivors are still in the start saferoom, otherwise from the next round.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvConvertHeld = CreateConVar("lef_t1_convert_held", "1", "Also replace banned weapons survivors pick up or carry over from the previous map.", _, true, 0.0, true, 1.0);
	g_cvVoteTime    = CreateConVar("lef_t1_vote_time", "20", "Seconds the !t1 vote stays open.", _, true, 5.0, true, 60.0);
	AutoExecConfig(true, "lef_t1_mode");

	g_cvEnable.AddChangeHook(OnEnableChanged);

	RegConsoleCmd("sm_t1", Cmd_Vote, "Vote to turn T1-only mode on or off");
	RegAdminCmd("sm_forcet1", Cmd_Force, ADMFLAG_GENERIC, "sm_forcet1 <on|off> - turn T1-only mode on or off");
	RegAdminCmd("sm_t1_reload", Cmd_Reload, ADMFLAG_CONFIG, "Reload configs/lef_t1_mode.cfg");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_LeftStartArea, EventHookMode_PostNoCopy);

	LoadRules();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnMapStart()
{
	// Same trick as l4d2_sniper_precache: precache the CS:S weapons so converting to them can't crash.
	char name[64];
	for (int i = 0; i < sizeof(g_iCSWeapons); i++)
	{
		PrecacheModel(WeaponModels[g_iCSWeapons[i]], true);
		GetWeaponName(g_iCSWeapons[i], name, sizeof(name));
		int ent = CreateEntityByName(name);
		if (ent != -1)
		{
			DispatchSpawn(ent);
			RemoveEntity(ent);
		}
	}
}

// ---------------------------------------------------------------------------
// Rules
// ---------------------------------------------------------------------------

void LoadRules()
{
	for (int i = 0; i < WEPID_SIZE; i++)
	{
		g_iRule[i] = -1;
	}

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), CONFIG_FILE);

	KeyValues kv = new KeyValues("T1Mode");
	if (!kv.ImportFromFile(path))
	{
		LogMessage("%s not found, using the built-in defaults", CONFIG_FILE);
		delete kv;
		SetDefaultRules();
		return;
	}

	char banned[64], replacement[64];
	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			kv.GetSectionName(banned, sizeof(banned));
			kv.GetString(NULL_STRING, replacement, sizeof(replacement));
			AddRule(banned, replacement);
		}
		while (kv.GotoNextKey(false));
	}

	delete kv;
}

void SetDefaultRules()
{
	AddRule("rifle", "smg");
	AddRule("rifle_ak47", "smg_silenced");
	AddRule("rifle_desert", "smg");
	AddRule("rifle_sg552", "smg_silenced");
	AddRule("autoshotgun", "pumpshotgun");
	AddRule("shotgun_spas", "shotgun_chrome");
	AddRule("hunting_rifle", "sniper_scout");
	AddRule("sniper_military", "sniper_scout");
}

// "none" or "" as the replacement removes the weapon.
void AddRule(const char[] banned, const char[] replacement)
{
	int from = NameToId(banned);
	if (from == WEPID_NONE)
	{
		LogError("%s: unknown weapon \"%s\"", CONFIG_FILE, banned);
		return;
	}

	int to = WEPID_NONE;
	if (replacement[0] != '\0' && !StrEqual(replacement, "none", false))
	{
		to = NameToId(replacement);
		if (to == WEPID_NONE)
		{
			LogError("%s: unknown replacement \"%s\" for \"%s\"", CONFIG_FILE, replacement, banned);
			return;
		}
	}

	g_iRule[from] = to;
}

// Accepts "rifle" or "weapon_rifle".
int NameToId(const char[] name)
{
	int id = WeaponNameToId(name);
	if (id == WEPID_NONE)
	{
		char full[64];
		FormatEx(full, sizeof(full), "weapon_%s", name);
		id = WeaponNameToId(full);
	}
	return id;
}

bool IsBanned(int wepid)
{
	return wepid > WEPID_NONE && wepid < WEPID_SIZE && g_iRule[wepid] != -1;
}

// ---------------------------------------------------------------------------
// Applying the mode
// ---------------------------------------------------------------------------

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bActive = g_cvEnable.BoolValue;

	// After l4d2_weaponrules (0.3s), so the two never fight over the same spawn.
	CreateTimer(0.6, Timer_ApplyRound, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ApplyRound(Handle timer)
{
	if (g_bActive)
	{
		ConvertAllSpawns();
		ConvertAllHeld();
	}
	return Plugin_Stop;
}

void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bActive)
	{
		CPrintToChatAll("%t", "Active This Round");
	}
}

void OnEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bool wanted = convar.BoolValue;
	if (wanted == g_bActive)
	{
		return;
	}

	// Still in the start saferoom: switch now. Otherwise wait for the next round.
	if (!L4D_HasAnySurvivorLeftSafeArea())
	{
		g_bActive = wanted;
		if (wanted)
		{
			ConvertAllSpawns();
			ConvertAllHeld();
		}
		CPrintToChatAll("%t", wanted ? "Now On" : "Now Off");
	}
	else
	{
		CPrintToChatAll("%t", wanted ? "Next Round On" : "Next Round Off");
	}
}

void ConvertAllSpawns()
{
	int max = GetMaxEntities();
	for (int ent = MaxClients + 1; ent < max; ent++)
	{
		ConvertIfBanned(ent);
	}
}

void ConvertIfBanned(int ent)
{
	if (!IsValidEntity(ent))
	{
		return;
	}

	int wepid = IdentifyWeapon(ent);
	if (!IsBanned(wepid))
	{
		return;
	}

	// Weapons in someone's hands are handled by the equip hook.
	if (HasEntProp(ent, Prop_Send, "m_hOwnerEntity") && GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") > 0)
	{
		return;
	}

	int to = g_iRule[wepid];
	if (to == WEPID_NONE)
	{
		RemoveEntity(ent);
		return;
	}

	// Keep how many pickups the spot had; loose single weapons stay single.
	int count = 1;
	if (HasEntProp(ent, Prop_Data, "m_itemCount"))
	{
		count = GetEntProp(ent, Prop_Data, "m_itemCount");
		if (count < 1)
		{
			count = 1;
		}
	}

	ConvertWeaponSpawn(ent, to, count);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (g_bActive && StrContains(classname, "weapon_") == 0)
	{
		RequestFrame(Frame_CheckNewWeapon, EntIndexToEntRef(entity));
	}
}

void Frame_CheckNewWeapon(int ref)
{
	int ent = EntRefToEntIndex(ref);
	if (ent != INVALID_ENT_REFERENCE && g_bActive)
	{
		ConvertIfBanned(ent);
	}
}

void ConvertAllHeld()
{
	if (!g_cvConvertHeld.BoolValue)
	{
		return;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
		{
			int weapon = GetPlayerWeaponSlot(i, 0);
			if (weapon != -1)
			{
				ReplaceHeld(i, weapon);
			}
		}
	}
}

void OnWeaponEquipPost(int client, int weapon)
{
	if (g_bActive && g_cvConvertHeld.BoolValue && weapon > 0 && GetClientTeam(client) == TEAM_SURVIVOR)
	{
		// Next frame: swapping weapons inside the equip callback confuses the game.
		DataPack pack = new DataPack();
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(EntIndexToEntRef(weapon));
		RequestFrame(Frame_ReplaceHeld, pack);
	}
}

void Frame_ReplaceHeld(DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int weapon = EntRefToEntIndex(pack.ReadCell());
	delete pack;

	if (client > 0 && weapon != INVALID_ENT_REFERENCE && IsClientInGame(client) && IsPlayerAlive(client))
	{
		ReplaceHeld(client, weapon);
	}
}

void ReplaceHeld(int client, int weapon)
{
	int wepid = IdentifyWeapon(weapon);
	if (!IsBanned(wepid) || GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity") != client)
	{
		return;
	}

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);

	int to = g_iRule[wepid];
	if (to != WEPID_NONE)
	{
		char name[64];
		GetWeaponName(to, name, sizeof(name));
		GiveItem(client, name[7]); // strip "weapon_"
	}
}

void GiveItem(int client, const char[] item)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", item);
	SetCommandFlags("give", flags);
}

// ---------------------------------------------------------------------------
// Commands and vote
// ---------------------------------------------------------------------------

Action Cmd_Force(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_forcet1 <on|off>");
		return Plugin_Handled;
	}

	char arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	bool on = StrEqual(arg, "on", false) || StrEqual(arg, "1");

	LogAction(client, -1, "\"%L\" turned T1 mode %s", client, on ? "on" : "off");
	g_cvEnable.SetBool(on);
	return Plugin_Handled;
}

Action Cmd_Reload(int client, int args)
{
	LoadRules();
	ReplyToCommand(client, "[T1] Reloaded %s", CONFIG_FILE);
	return Plugin_Handled;
}

Action Cmd_Vote(int client, int args)
{
	if (client == 0)
	{
		return Plugin_Handled;
	}

	if (GetFeatureStatus(FeatureType_Native, "CreateBuiltinVote") != FeatureStatus_Available)
	{
		CPrintToChat(client, "%T", "No Votes", client);
		return Plugin_Handled;
	}

	if (GetClientTeam(client) <= TEAM_SPECTATOR)
	{
		CPrintToChat(client, "%T", "Spectators Cannot Vote", client);
		return Plugin_Handled;
	}

	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(client, "%T", "Vote In Progress", client);
		return Plugin_Handled;
	}

	int delay = CheckBuiltinVoteDelay();
	if (delay > 0)
	{
		CPrintToChat(client, "%T", "Vote Delay", client, delay);
		return Plugin_Handled;
	}

	int[] players = new int[MaxClients];
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > TEAM_SPECTATOR)
		{
			players[count++] = i;
		}
	}

	g_bVoteTarget = !g_cvEnable.BoolValue;

	char title[96];
	FormatEx(title, sizeof(title), "%T", g_bVoteTarget ? "Vote Title On" : "Vote Title Off", LANG_SERVER);

	g_hVote = CreateBuiltinVote(VoteAction_Handler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(g_hVote, title);
	SetBuiltinVoteInitiator(g_hVote, client);
	SetBuiltinVoteResultCallback(g_hVote, VoteResult_Handler);
	DisplayBuiltinVote(g_hVote, players, count, g_cvVoteTime.IntValue);

	FakeClientCommand(client, "Vote Yes");
	return Plugin_Handled;
}

void VoteAction_Handler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			delete vote;
			g_hVote = null;
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
		}
	}
}

void VoteResult_Handler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES && item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > num_votes / 2)
		{
			char passed[64];
			FormatEx(passed, sizeof(passed), "%T", g_bVoteTarget ? "Vote Passed On" : "Vote Passed Off", LANG_SERVER);
			DisplayBuiltinVotePass(vote, passed);
			g_cvEnable.SetBool(g_bVoteTarget);
			return;
		}
	}

	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}
