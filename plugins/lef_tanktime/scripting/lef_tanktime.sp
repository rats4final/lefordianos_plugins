/**
 * Lefordianos Tank!Time!
 *
 * Port of Merc1less' "[L4D2] Tank!Time!" 1.2.3 (https://forums.alliedmods.net/showthread.php?t=248745),
 * which balances the "Taaannnk!!" mutation (mutation19) for versus. Same game rules and options; only
 * active while mp_gamemode is mutation19, idle in every other mode.
 *
 *  - Up to 4 infected tanks: they spawn together SPAWN seconds after the survivors leave the saferoom,
 *    and each one respawns RESPAWN seconds after dying. Bot tanks fill empty slots; a player who joins
 *    the infected takes over a bot tank, or the next free spawn.
 *  - Both halves get the same tank spawn spots; tanks spawning in known bad places (per map, from
 *    configs/lef_tanktime.cfg) are moved to good ones. A witch spawns at the same spot in both halves.
 *  - In finales the game allows a single bot tank, so human tanks get extra health instead.
 *  - Optional: info panel on the tank you aim at, tank health when it incaps you, crawling, shotgun mode
 *    (weapon spawns become shotguns and a few big guns).
 *  - Survivors can type !slayme while incapacitated; !ttcfg shows the current options.
 *
 * What changed from the original:
 *  - Left4DHooks (L4D_ReplaceTank, L4D_TakeOverZombieBot) instead of its own gamedata signatures, which
 *    broke with game updates. New syntax, colors.inc, en/es translations, lef_tanktime_* cvars, map data
 *    in configs/lef_tanktime.cfg.
 *  - Its chat listener blocked every chat message starting with "!" (so other plugins' commands) while
 *    the mode was on: !slayme and !ttcfg are now normal commands.
 *  - One info panel timer instead of a new one stacking up every round.
 *  - "FixedFirstSpawnPos" in the map data is actually read (the original parsed it and dropped it).
 *  - The mutation19 relay added by its Stripper files fires at round start (the owner's own build of the
 *    original did this instead of waiting 1 second).
 *  - Director settings are applied again after each map's configs, so cfg files can't undo them.
 * Its Stripper files (map changes that only switch on in mutation19) and finale VScripts ship with
 * this plugin in lefordianos_plugins; see the README.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "1.0.0"

#define TAG          "{green}[Tank!Time!]{default}"
#define MODE         "mutation19"
#define DATA_FILE    "configs/lef_tanktime.cfg"
#define SOUND_START  "level/countdown.wav"
#define MAX_TANKS    4

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

// lef_tanktime_options: the same flags as the original l4d2_tanktime_gameoptions.
#define OPT_BOTS             1    // bot tanks fill the empty slots
#define OPT_CRAWLING         2    // incapacitated survivors can crawl
#define OPT_HUD              4    // info panel on the tank you aim at
#define OPT_HEALTH_INFO      8    // tell an incapped survivor how much health the tank had
#define OPT_FORCE_SPAWNS     16   // tank and witch on every map
#define OPT_NO_REGULAR       32   // no "regular" tank from the director
#define OPT_SHOTGUN_MODE     64   // weapon spawns become shotguns and a few big guns
#define OPT_SGM_KEEP_TIER1   128  // shotgun mode leaves tier 1 weapons alone

// round_end "reason"
#define ROUND_END_TEAM_SWAP  0
#define ROUND_END_NORMAL     5
#define ROUND_END_ALL_LEFT   8

#define ASSIGN_TO_BOT_TIMER  0.1  // SpawnTimer_Create: give a joining player a running bot timer

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Tank!Time!",
	author      = "rats4final; original Tank!Time! by Merc1less",
	description = "Balances the Taaannnk!! mutation (mutation19) for versus",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar g_cvOptions, g_cvSpawnTime, g_cvRespawnTime, g_cvTankHealth, g_cvBigGuns, g_cvTankColor, g_cvRestartCmd;

// Read when the mode turns on; not changed during a match (as in the original).
bool  g_bActive;
int   g_iOptions;
float g_fSpawnTime, g_fRespawnTime;
int   g_iTankHealth, g_iBigGunsLimit;
int   g_iTankColor[4] = {255, 0, 0, 255};

// Game status
bool g_bInRound, g_bInFinale, g_bSpawning, g_bSpawnLimit, g_bFirstMap;

// Map data (configs/lef_tanktime.cfg)
enum struct BugArea
{
	float lo[3];
	float hi[3];
	ArrayList spawns;   // float[3] blocks
}
ArrayList g_aTankNames;    // strings
ArrayList g_aBugAreas;     // BugArea
ArrayList g_aFixedSpawns;  // float[3] blocks
bool      g_bFinaleSpawnLimit;

// Respawn timers, one per tank slot
enum struct SpawnSlot
{
	bool   used;
	int    userid;    // 0 = a bot will spawn
	int    seconds;
	Handle timer;
}
SpawnSlot g_Slots[MAX_TANKS];
int       g_iRunningSlots;

// Round state
float  g_vFirstSpawns[MAX_TANKS][3];
int    g_iFirstSpawnIndex;
int    g_iRegularTank = -1;     // userid of the "regular" (director's) tank
int    g_iTankNameIndex;
float  g_vWitchPos[3];
int    g_iCountdown;
Handle g_hCountdown;
Handle g_hHud;
int    g_iDoorTime;
bool   g_bReplacing;           // L4D_ReplaceTank fires player_death; ignore it
ArrayList g_aWeaponSpots;      // shotgun mode: {x, y, z, ax, ay, az, index} from the first half

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
	LoadTranslations("lef_tanktime.phrases");

	CreateConVar("lef_tanktime_version", PLUGIN_VERSION, "Lefordianos Tank!Time! version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvOptions     = CreateConVar("lef_tanktime_options", "55", "Options (add up): 1 bot tanks, 2 crawling, 4 info panel, 8 tank health when incapped, 16 tank and witch every map, 32 no regular tank, 64 shotgun mode, 128 shotgun mode keeps tier 1 weapons.", _, true, 0.0, true, 255.0);
	g_cvSpawnTime   = CreateConVar("lef_tanktime_spawn_time", "15", "Seconds after the survivors leave the saferoom before the tanks spawn.", _, true, 5.0, true, 30.0);
	g_cvRespawnTime = CreateConVar("lef_tanktime_respawn_time", "30", "Seconds before a dead tank spawns again.", _, true, 10.0, true, 60.0);
	g_cvTankHealth  = CreateConVar("lef_tanktime_tank_health", "0", "Health of each tank (0 = the game's z_tank_health).", _, true, 0.0);
	g_cvBigGuns     = CreateConVar("lef_tanktime_bigguns_limit", "2", "Shotgun mode: big guns (M60, grenade launcher, chainsaw) per round.", _, true, 0.0);
	g_cvTankColor   = CreateConVar("lef_tanktime_regular_tank_color", "255 0 0 255", "Color (R G B A) of the regular tank.");
	g_cvRestartCmd  = CreateConVar("lef_tanktime_restart_command", "", "Command run when a round starts during the intro (empty = restart the map).");
	AutoExecConfig(true, "lef_tanktime");

	RegConsoleCmd("sm_slayme", Cmd_SlayMe, "Kill yourself while incapacitated (Tank!Time!)");
	RegConsoleCmd("sm_ttcfg", Cmd_Config, "Show the Tank!Time! options");

	g_aTankNames   = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
	g_aBugAreas    = new ArrayList(sizeof(BugArea));
	g_aFixedSpawns = new ArrayList(3);
	g_aWeaponSpots = new ArrayList(7);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("versus_round_start", Event_VersusRoundStart, EventHookMode_PostNoCopy);
	HookEvent("finale_start", Event_FinaleStart, EventHookMode_PostNoCopy);
	HookEvent("versus_match_finished", Event_MatchFinished, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookUserMessage(GetUserMessageId("VotePass"), Message_VotePass);
	HookUserMessage(GetUserMessageId("VGUIMenu"), Message_VGUIMenu);

	FindConVar("mp_gamemode").AddChangeHook(OnGameModeChanged);

	// Late load: pick up the current map.
	if (IsServerProcessing())
	{
		UpdateActive();
		if (g_bActive)
		{
			SetupMap();
		}
	}
}

public void OnPluginEnd()
{
	if (g_bActive)
	{
		SetActive(false);
	}
}

// ---------------------------------------------------------------------------
// On only in mutation19
// ---------------------------------------------------------------------------

void OnGameModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	UpdateActive();
}

void UpdateActive()
{
	char mode[32];
	FindConVar("mp_gamemode").GetString(mode, sizeof(mode));
	bool want = StrEqual(mode, MODE, false);
	if (want != g_bActive)
	{
		SetActive(want);
	}
}

void SetActive(bool active)
{
	g_bActive = active;
	if (active)
	{
		g_iOptions      = g_cvOptions.IntValue;
		g_fSpawnTime    = g_cvSpawnTime.FloatValue;
		g_fRespawnTime  = g_cvRespawnTime.FloatValue;
		g_iTankHealth   = g_cvTankHealth.IntValue;
		g_iBigGunsLimit = g_cvBigGuns.IntValue;
		ReadTankColor();
		ApplyCvars();
		SpawnTimer_Init();
		ClearStatus();
		g_bFirstMap = true;   // the first map the mode sees, not necessarily the campaign's
		return;
	}

	SpawnTimer_Stop();
	delete g_hCountdown;
	delete g_hHud;
	ClearStatus();
	FreeMapData();
	g_aWeaponSpots.Clear();
	ResetCvars();
}

void ClearStatus()
{
	g_bInRound = g_bInFinale = g_bSpawning = g_bSpawnLimit = false;
}

void ReadTankColor()
{
	char value[32], parts[4][8];
	g_cvTankColor.GetString(value, sizeof(value));
	if (ExplodeString(value, " ", parts, sizeof(parts), sizeof(parts[])) == 4)
	{
		for (int c = 0; c < 4; c++)
		{
			g_iTankColor[c] = StringToInt(parts[c]);
		}
	}
	else
	{
		g_iTankColor = {255, 0, 0, 255};
	}
}

// Director settings the mode needs (from the original). Run again after each map's configs.
void ApplyCvars()
{
	// z_spawn_old would otherwise also spawn special infected next to the survivors.
	FindConVar("director_no_specials").SetInt(1);
	FindConVar("versus_tank_flow_team_variation").SetFloat(0.0);
	// The tank lottery could kill tanks spawned between its announcement and the regular tank.
	FindConVar("director_tank_lottery_selection_time").SetInt(0);
	FindConVar("director_tank_lottery_entry_time").SetFloat(0.0);
	FindConVar("z_frustration_lifetime").SetInt(60);

	if (g_iOptions & OPT_CRAWLING)
	{
		FindConVar("survivor_allow_crawling").SetInt(1);
		FindConVar("survivor_crawl_speed").SetInt(40);
	}

	float tankChance = 0.0;
	if (g_iOptions & OPT_FORCE_SPAWNS)
	{
		tankChance = 1.0;
		FindConVar("versus_witch_chance_intro").SetFloat(1.0);
		FindConVar("versus_witch_chance").SetFloat(1.0);
		FindConVar("versus_witch_chance_finale").SetFloat(1.0);
	}
	if (tankChance != 0.0 || g_iOptions & OPT_NO_REGULAR)
	{
		FindConVar("director_tank_force_offer").SetFloat(tankChance);
		FindConVar("versus_tank_chance_intro").SetFloat(tankChance);
		FindConVar("versus_tank_chance").SetFloat(tankChance);
		FindConVar("versus_tank_chance_finale").SetFloat(tankChance);
	}
}

void ResetCvars()
{
	static const char names[][] = {
		"z_frustration_lifetime", "director_no_specials", "director_tank_lottery_selection_time",
		"director_tank_lottery_entry_time", "versus_tank_flow_team_variation", "survivor_allow_crawling",
		"survivor_crawl_speed", "director_tank_force_offer", "versus_tank_chance_intro", "versus_tank_chance",
		"versus_tank_chance_finale", "versus_witch_chance_intro", "versus_witch_chance", "versus_witch_chance_finale"
	};
	for (int i = 0; i < sizeof(names); i++)
	{
		FindConVar(names[i]).RestoreDefault();
	}
}

public void OnConfigsExecuted()
{
	if (g_bActive)
	{
		ApplyCvars();
	}
}

public void OnMapStart()
{
	UpdateActive();
	if (g_bActive)
	{
		SetupMap();
	}
}

void SetupMap()
{
	PrecacheSound(SOUND_START);
	LoadMapData();
	if (g_iOptions & OPT_SHOTGUN_MODE)
	{
		static const char models[][] = {
			"models/w_models/weapons/w_shotgun.mdl", "models/w_models/weapons/w_pumpshotgun_a.mdl",
			"models/w_models/weapons/w_autoshot_m4super.mdl", "models/w_models/weapons/w_shotgun_spas.mdl",
			"models/w_models/weapons/w_m60.mdl", "models/w_models/weapons/w_grenade_launcher.mdl",
			"models/weapons/melee/w_chainsaw.mdl"
		};
		for (int m = 0; m < sizeof(models); m++)
		{
			if (!IsModelPrecached(models[m]))
			{
				PrecacheModel(models[m]);
			}
		}
		ChangeWeaponSpawns();
	}
}

public void OnMapEnd()
{
	if (!g_bActive)
	{
		return;
	}
	g_aWeaponSpots.Clear();
	SpawnTimer_Stop();
	delete g_hCountdown;
	delete g_hHud;
	FreeMapData();
	ClearStatus();
	g_bFirstMap = false;
}

// ---------------------------------------------------------------------------
// Map data (configs/lef_tanktime.cfg)
// ---------------------------------------------------------------------------

void FreeMapData()
{
	BugArea area;
	for (int i = 0; i < g_aBugAreas.Length; i++)
	{
		g_aBugAreas.GetArray(i, area);
		delete area.spawns;
	}
	g_aBugAreas.Clear();
	g_aFixedSpawns.Clear();
	g_aTankNames.Clear();
	g_bFinaleSpawnLimit = false;
}

void LoadMapData()
{
	FreeMapData();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), DATA_FILE);
	KeyValues kv = new KeyValues("TankTime");
	if (!kv.ImportFromFile(path))
	{
		delete kv;
		LogError("%s not found: bot tanks keep their own names and no map has spawn fixes", DATA_FILE);
		return;
	}

	char text[MAX_NAME_LENGTH];
	if (kv.JumpToKey("TankNames") && kv.GotoFirstSubKey(false))
	{
		do
		{
			kv.GetString(NULL_STRING, text, sizeof(text));
			if (text[0] != '\0')
			{
				g_aTankNames.PushString(text);
			}
		}
		while (kv.GotoNextKey(false));
	}
	kv.Rewind();

	char map[64];
	GetCurrentMap(map, sizeof(map));
	if (!kv.JumpToKey(map))
	{
		delete kv;
		return;
	}

	kv.GetString("SpawnLimit", text, sizeof(text));
	g_bFinaleSpawnLimit = StrEqual(text, "Finale", false);

	if (kv.JumpToKey("SpawnBugs"))
	{
		if (kv.GotoFirstSubKey())
		{
			char name[64];
			do
			{
				kv.GetSectionName(name, sizeof(name));
				BugArea area;
				kv.GetString("InvalidArea", text, sizeof(text));
				if (!ParseArea(text, area))
				{
					LogError("%s, %s, %s: bad InvalidArea \"%s\"", DATA_FILE, map, name, text);
					continue;
				}
				area.spawns = new ArrayList(3);
				if (kv.JumpToKey("ValidSpawnPos"))
				{
					ReadPositions(kv, area.spawns);
					kv.GoBack();
				}
				if (area.spawns.Length == 0)
				{
					LogError("%s, %s, %s: no ValidSpawnPos", DATA_FILE, map, name);
					delete area.spawns;
					continue;
				}
				g_aBugAreas.PushArray(area);
			}
			while (kv.GotoNextKey());
			kv.GoBack();
		}
		kv.GoBack();
	}

	if (kv.JumpToKey("FixedFirstSpawnPos"))
	{
		ReadPositions(kv, g_aFixedSpawns);
		kv.GoBack();
	}
	delete kv;
}

// "x1:x2;y1:y2;z1:z2"
bool ParseArea(const char[] text, BugArea area)
{
	char axes[3][32], ends[2][16];
	if (ExplodeString(text, ";", axes, sizeof(axes), sizeof(axes[])) != 3)
	{
		return false;
	}
	for (int a = 0; a < 3; a++)
	{
		if (ExplodeString(axes[a], ":", ends, sizeof(ends), sizeof(ends[])) != 2)
		{
			return false;
		}
		area.lo[a] = StringToFloat(ends[0]);
		area.hi[a] = StringToFloat(ends[1]);
		if (area.lo[a] > area.hi[a])
		{
			return false;
		}
	}
	return true;
}

// { "0" "x;y;z" "1" "x;y;z" ... }
void ReadPositions(KeyValues kv, ArrayList out)
{
	if (!kv.GotoFirstSubKey(false))
	{
		return;
	}
	char text[64], parts[3][16];
	float pos[3];
	do
	{
		kv.GetString(NULL_STRING, text, sizeof(text));
		if (ExplodeString(text, ";", parts, sizeof(parts), sizeof(parts[])) == 3)
		{
			for (int a = 0; a < 3; a++)
			{
				pos[a] = StringToFloat(parts[a]);
			}
			out.PushArray(pos);
		}
	}
	while (kv.GotoNextKey(false));
	kv.GoBack();
}

// A tank spawning inside a known bad area gets one of the area's good spots (in turn). An axis whose
// lower bound is 0.0 matches anything, and a 0.0 in a spot keeps that coordinate (as in the original).
bool FixBuggedSpawn(float pos[3])
{
	static int next;
	BugArea area;
	for (int i = 0; i < g_aBugAreas.Length; i++)
	{
		g_aBugAreas.GetArray(i, area);
		bool inside = true;
		for (int a = 0; a < 3 && inside; a++)
		{
			inside = area.lo[a] == 0.0 || (pos[a] >= area.lo[a] && pos[a] <= area.hi[a]);
		}
		if (!inside)
		{
			continue;
		}
		if (next >= area.spawns.Length)
		{
			next = 0;
		}
		float spot[3];
		area.spawns.GetArray(next++, spot);
		for (int a = 0; a < 3; a++)
		{
			if (spot[a] != 0.0)
			{
				pos[a] = spot[a];
			}
		}
		return true;
	}
	return false;
}

// ---------------------------------------------------------------------------
// Round flow
// ---------------------------------------------------------------------------

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive)
	{
		return;
	}

	g_iDoorTime = GetTime();

	// The map changes from the Stripper files wait for this relay (they stay off in other modes).
	if (FindEntityByTargetName("logic_director_query", "map_has_routing") != -1)
	{
		int relay = FindEntityByTargetName("logic_relay", "relay_tt_mutation19");
		if (relay != -1)
		{
			AcceptEntityInput(relay, "Trigger");
		}
	}

	if (g_iOptions & OPT_SHOTGUN_MODE && !IsFirstHalf())
	{
		ChangeWeaponSpawns();
	}

	g_iFirstSpawnIndex = 0;
	g_iRegularTank = -1;
	SpawnTimer_Init();
	g_bSpawnLimit = false;
	if (IsFirstHalf())
	{
		for (int t = 0; t < MAX_TANKS; t++)
		{
			g_vFirstSpawns[t][0] = g_vFirstSpawns[t][1] = g_vFirstSpawns[t][2] = 0.0;
		}
		g_vWitchPos[0] = 0.0;
	}
}

// Survivors left the saferoom (or the door timeout started the round).
void Event_VersusRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive)
	{
		return;
	}

	// The game sometimes starts a round while the intro is still running (fast loading players).
	if (IsIntroRunning())
	{
		for (int i = 0; i < 3; i++)
		{
			PrintToTeam(TEAM_SURVIVOR, "RoundStartedTooEarly");
		}
		PrintHintTextToAll("%t", "RoundStartedTooEarly");
		char command[64];
		g_cvRestartCmd.GetString(command, sizeof(command));
		if (command[0] != '\0')
		{
			ServerCommand("%s", command);
		}
		else
		{
			char map[64];
			GetCurrentMap(map, sizeof(map));
			ForceChangeLevel(map, "Tank!Time!: round started during the intro");
		}
		return;
	}

	g_bInRound = true;

	// These two finales don't fire finale_start.
	char map[64];
	GetCurrentMap(map, sizeof(map));
	if (StrContains(map, "c5m5") == 0 || StrContains(map, "c13m4") == 0)
	{
		g_bInFinale = true;
	}

	g_iCountdown = RoundToZero(g_fSpawnTime);
	delete g_hCountdown;
	g_hCountdown = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
	EmitSoundToAll(SOUND_START);

	if (GetTime() - g_iDoorTime >= FindConVar("versus_force_start_time").IntValue)
	{
		CPrintToChatAll("%s %t", TAG, "StartedByTimeout");
	}

	// Second half: the witch comes back at the first half's spot.
	if (!IsFirstHalf() && g_vWitchPos[0] != 0.0)
	{
		CheatCommand("z_spawn_old", "witch");
	}
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive)
	{
		return;
	}

	SpawnTimer_Stop();
	delete g_hHud;

	int reason = event.GetInt("reason");
	if (reason == ROUND_END_TEAM_SWAP)
	{
		// After a finale, players' views could stay stuck on the outro camera (z_spawn_old bug).
		if (g_bInFinale)
		{
			ReleaseOutroCamera();
		}
		g_bInRound = g_bSpawning = g_bInFinale = false;
	}
	else if (reason == ROUND_END_NORMAL)
	{
		if (IsVoteInProgress())
		{
			CancelVote();
		}
		g_bInRound = false;
	}
	else if (reason == ROUND_END_ALL_LEFT)
	{
		ClearStatus();
	}
}

void ReleaseOutroCamera()
{
	char name[64], output[128];
	int ent = FindEntityByClassname(-1, "info_director");
	if (ent != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
		FormatEx(output, sizeof(output), "OnUser1 %s:ReleaseSurvivorPositions::0:-1", name);
		SetVariantString(output);
		AcceptEntityInput(ent, "AddOutput");
		FormatEx(output, sizeof(output), "OnUser1 %s:FinishIntro::0:-1", name);
		SetVariantString(output);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
	if ((ent = FindEntityByClassname(-1, "point_viewcontrol_multiplayer")) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
		FormatEx(output, sizeof(output), "OnUser2 %s:StartMovement::0:-1", name);
		SetVariantString(output);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser2");
	}
}

void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive)
	{
		return;
	}
	g_bInFinale = true;
	if (g_bFinaleSpawnLimit)
	{
		g_bSpawnLimit = true;
		if (HumanInfectedCount() < MAX_TANKS)
		{
			CPrintToChatAll("%s %t", TAG, "SpawnLimitInfo_Finale");
		}
	}
}

void Event_MatchFinished(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bActive)
	{
		SpawnTimer_Stop();
		ClearStatus();
	}
}

Action Message_VotePass(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (!g_bActive)
	{
		return Plugin_Continue;
	}
	char details[64];
	msg.ReadByte();
	msg.ReadString(details, sizeof(details));
	if (StrEqual(details, "#L4D_vote_passed_versus_level_restart"))
	{
		g_bInFinale = g_bInRound = g_bSpawning = false;
	}
	return Plugin_Continue;
}

Action Timer_Countdown(Handle timer)
{
	if (!g_bInRound)
	{
		g_hCountdown = null;
		return Plugin_Stop;
	}

	if (--g_iCountdown <= 0)
	{
		g_hCountdown = null;
		SpawnTime();
		PrintHintTextToAll("%t", "TanksAreSpawningNow");
		return Plugin_Stop;
	}
	if (g_iCountdown == 10 && IsFirstHalf())
	{
		PrintToTeam(TEAM_INFECTED, "TankTimeInfo");
	}
	PrintHintTextToAll("%t", "TanksAreSpawningIn", g_iCountdown);
	return Plugin_Continue;
}

// The countdown is over: the first tanks spawn.
void SpawnTime()
{
	g_bSpawning = true;
	bool fixedSpots = g_aFixedSpawns.Length > 0;
	if (g_iOptions & OPT_BOTS)
	{
		CreateTanks(MAX_TANKS, fixedSpots);
	}
	else
	{
		int humans = GetTeamClientCount(TEAM_INFECTED);
		if (humans > 0)
		{
			CreateTanks(humans, fixedSpots);
		}
	}
	g_iFirstSpawnIndex = MAX_TANKS;   // the first spawn round is done, maybe not with 4 players

	if (g_iOptions & OPT_HUD && g_hHud == null)
	{
		g_hHud = CreateTimer(0.3, Timer_Hud, _, TIMER_REPEAT);
	}
}

// ---------------------------------------------------------------------------
// Respawn timers (one per tank slot)
// ---------------------------------------------------------------------------

void SpawnTimer_Init()
{
	for (int t = 0; t < MAX_TANKS; t++)
	{
		g_Slots[t].used = false;
		g_Slots[t].userid = 0;
		g_Slots[t].seconds = 0;
		g_Slots[t].timer = null;
	}
	g_iRunningSlots = 0;
}

void SpawnTimer_Stop()
{
	for (int t = 0; t < MAX_TANKS; t++)
	{
		delete g_Slots[t].timer;
	}
	SpawnTimer_Init();
}

int SpawnTimer_Find(int userid)
{
	if (userid == 0)
	{
		return -1;
	}
	for (int t = 0; t < MAX_TANKS; t++)
	{
		if (g_Slots[t].used && g_Slots[t].userid == userid)
		{
			return t;
		}
	}
	return -1;
}

int SpawnTimer_Seconds(int userid)
{
	int t = SpawnTimer_Find(userid);
	return t == -1 ? 0 : g_Slots[t].seconds;
}

void SpawnTimer_Unassign(int userid)
{
	int t = SpawnTimer_Find(userid);
	if (t != -1)
	{
		g_Slots[t].userid = 0;   // a bot spawns instead
	}
}

// Starts a respawn timer. With a userid, the player takes over the bot timer closest to spawning
// if there is one (that bot timer then gets a fresh one), as in the original.
bool SpawnTimer_Create(float time, int userid = 0)
{
	if (!g_bSpawning || (userid == 0 && g_iRunningSlots >= MAX_TANKS))
	{
		return false;
	}

	int lowest = RoundFloat(g_fRespawnTime);
	int botSlot = -1, freeSlot = -1;
	for (int t = MAX_TANKS - 1; t >= 0; t--)
	{
		if (!g_Slots[t].used)
		{
			freeSlot = t;
		}
		else if ((userid > 0 && g_Slots[t].userid == 0) || GetClientOfUserId(g_Slots[t].userid) == 0)
		{
			if (g_Slots[t].seconds < lowest)
			{
				botSlot = t;
				lowest = g_Slots[t].seconds;
			}
		}
	}

	if (userid > 0)
	{
		if (botSlot != -1)
		{
			g_Slots[botSlot].userid = userid;
			if (time == ASSIGN_TO_BOT_TIMER)
			{
				return true;
			}
			userid = 0;   // the bot it replaced waits the full time
		}
		if (time == ASSIGN_TO_BOT_TIMER)
		{
			time = g_fRespawnTime;
		}
	}

	// Finale spawn limit: fewer humans, shorter respawn.
	if (g_bSpawnLimit)
	{
		int humans = HumanInfectedCount();
		if (humans == 0)
		{
			humans = 1;   // the game allows one bot tank in finales
		}
		time = (g_fRespawnTime / float(MAX_TANKS)) * float(humans);
	}

	if (freeSlot == -1)
	{
		return false;
	}
	g_Slots[freeSlot].used = true;
	g_Slots[freeSlot].userid = userid;
	g_Slots[freeSlot].seconds = RoundToZero(time);
	g_Slots[freeSlot].timer = CreateTimer(1.0, Timer_Slot, freeSlot, TIMER_REPEAT);
	g_iRunningSlots++;
	return true;
}

Action Timer_Slot(Handle timer, int slot)
{
	g_Slots[slot].seconds--;

	if (!g_bSpawning || !g_bInRound || g_Slots[slot].seconds <= 0)
	{
		bool spawn = g_bSpawning && g_bInRound;
		g_Slots[slot].used = false;
		g_Slots[slot].userid = 0;
		g_Slots[slot].timer = null;
		g_iRunningSlots--;
		if (spawn)
		{
			CreateTanks();
		}
		return Plugin_Stop;
	}

	if (g_Slots[slot].userid != 0)
	{
		int client = GetClientOfUserId(g_Slots[slot].userid);
		if (client > 0 && !IsPlayerAlive(client) && GetClientTeam(client) == TEAM_INFECTED)
		{
			PrintHintText(client, "%t", "YouAreSpawningIn", g_Slots[slot].seconds);
		}
		else
		{
			g_Slots[slot].userid = 0;
		}
	}
	return Plugin_Continue;
}

// ---------------------------------------------------------------------------
// Tanks
// ---------------------------------------------------------------------------

// Spawns tank bots with the game's own z_spawn_old ("auto" finds a spot out of sight); the
// game hands them to dead infected players. Without "auto" on a second try, for small areas.
void CreateTanks(int count = 1, bool exactSpot = false)
{
	if (count == 0 || !g_bSpawning || !g_bInRound)
	{
		return;
	}
	int client = AnyHuman();
	if (client == 0)
	{
		return;
	}

	char command[16], line[32];
	strcopy(command, sizeof(command), exactSpot ? "z_spawn" : "z_spawn_old");
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);

	int toSpawn = count, last = LivingInfectedCount(), now;
	for (int pass = 0; pass < 2 && toSpawn > 0; pass++)
	{
		FormatEx(line, sizeof(line), "%s tank%s", command, (pass == 0 && !exactSpot) ? " auto" : "");
		for (int i = 0; i < count && toSpawn > 0 && g_bSpawning; i++)
		{
			FakeClientCommand(client, line);
			if ((now = LivingInfectedCount()) > last)
			{
				last = now;
				toSpawn--;
			}
		}
	}
	SetCommandFlags(command, flags);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive || !g_bInRound)
	{
		return;
	}
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (client == 0 || GetClientTeam(client) != TEAM_INFECTED)
	{
		return;
	}

	float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	if (pos[0] == 0.0 && pos[1] == 0.0)
	{
		return;   // bot/player replacement, not a real spawn
	}

	bool bot = IsFakeClient(client);
	if (!bot)
	{
		// Spawned before their own timer ran out: give this tank to a dead teammate whose turn it is.
		if (SpawnTimer_Seconds(userid) > 0)
		{
			for (int p = 1; p <= MaxClients; p++)
			{
				if (p != client && IsClientInGame(p) && !IsFakeClient(p) && !IsPlayerAlive(p)
					&& GetClientTeam(p) == TEAM_INFECTED && SpawnTimer_Seconds(GetClientUserId(p)) == 0)
				{
					g_bReplacing = true;
					L4D_ReplaceTank(client, p);
					g_bReplacing = false;
					return;
				}
			}
		}
	}
	else if (g_iRegularTank == -1
		&& (!g_bSpawning || !(g_iOptions & OPT_BOTS) || LivingInfectedCount() + g_iRunningSlots > MAX_TANKS))
	{
		// A tank the director spawned on its own: the "regular" tank.
		if (!(g_iOptions & OPT_NO_REGULAR))
		{
			SetRegularTank(userid);
			CPrintToChatAll("%s %t", TAG, "RegularTankIsSpawningNow");
		}
		else
		{
			ForcePlayerSuicide(client);
		}
		return;
	}
	else
	{
		NameBotTank(client);
	}

	// Finale spawn limit: the tank team's total health split among its humans.
	if (g_bSpawnLimit)
	{
		int humans = HumanInfectedCount();
		if (humans < MAX_TANKS)
		{
			if (humans == 0)
			{
				humans = 1;
			}
			int base = g_iTankHealth > 0 ? g_iTankHealth : FindConVar("z_tank_health").IntValue;
			int health = (base * MAX_TANKS) / humans;
			SetEntProp(client, Prop_Data, "m_iMaxHealth", health);
			SetEntProp(client, Prop_Data, "m_iHealth", health);
		}
	}
	else if (g_iTankHealth > 0)
	{
		SetEntProp(client, Prop_Data, "m_iMaxHealth", g_iTankHealth);
		SetEntProp(client, Prop_Data, "m_iHealth", g_iTankHealth);
	}

	// The first tanks of a round: both halves use the same spots.
	if (g_iFirstSpawnIndex < MAX_TANKS)
	{
		int index = g_iFirstSpawnIndex++;
		if (IsFirstHalf())
		{
			if (g_aFixedSpawns.Length > 0)
			{
				g_aFixedSpawns.GetArray(GetRandomInt(0, g_aFixedSpawns.Length - 1), g_vFirstSpawns[index]);
				TeleportTank(userid, g_vFirstSpawns[index]);
			}
			else
			{
				if (FixBuggedSpawn(pos))
				{
					TeleportTank(userid, pos);
				}
				g_vFirstSpawns[index] = pos;
			}
		}
		else if (g_vFirstSpawns[index][0] != 0.0)
		{
			TeleportTank(userid, g_vFirstSpawns[index]);
		}
	}
	else if (!bot && FixBuggedSpawn(pos))
	{
		TeleportTank(userid, pos);   // bots find their own way out
	}
}

void TeleportTank(int userid, const float pos[3])
{
	DataPack pack = new DataPack();
	pack.WriteCell(userid);
	pack.WriteFloatArray(pos, 3);
	RequestFrame(Frame_Teleport, pack);
}

void Frame_Teleport(DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	float pos[3];
	pack.ReadFloatArray(pos, 3);
	delete pack;
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive || !g_bSpawning || g_bReplacing)
	{
		return;
	}
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (client == 0 || GetClientTeam(client) != TEAM_INFECTED)
	{
		return;
	}

	if (g_iRegularTank == userid)
	{
		g_iRegularTank = -1;
	}

	if (IsFakeClient(client))
	{
		if (g_iOptions & OPT_BOTS && LivingInfectedCount() + 1 + g_iRunningSlots <= MAX_TANKS)
		{
			SpawnTimer_Create(g_fRespawnTime);
		}
	}
	else if (LivingInfectedCount() >= MAX_TANKS)
	{
		RequestFrame(Frame_TakeOverBot, userid);
	}
	else
	{
		SpawnTimer_Create(g_fRespawnTime, userid);
	}
}

// A player joined the infected: take over a living bot tank. Not inside player_team itself: that
// loops and removes the bot tanks one by one.
void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive || !g_bInRound || event.GetInt("team") != TEAM_INFECTED)
	{
		return;
	}
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		RequestFrame(Frame_TakeOverBot, userid);
	}
}

void Frame_TakeOverBot(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0 || GetClientTeam(client) != TEAM_INFECTED)
	{
		return;
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED && IsPlayerAlive(i))
		{
			int botUserid = GetClientUserId(i);
			L4D_TakeOverZombieBot(client, i);
			if (botUserid == g_iRegularTank)
			{
				SetRegularTank(userid);
			}
			return;
		}
	}
	// No living bot: take over a running bot timer.
	SpawnTimer_Create(ASSIGN_TO_BOT_TIMER, userid);
}

// A player left the infected (or disconnected): the bot gets their place.
void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive || !g_bInRound)
	{
		return;
	}
	int botUserid = event.GetInt("bot");
	int bot = GetClientOfUserId(botUserid);
	if (bot == 0 || GetClientTeam(bot) != TEAM_INFECTED)
	{
		return;
	}
	int userid = event.GetInt("player");
	SpawnTimer_Unassign(userid);
	if (userid == g_iRegularTank)
	{
		SetRegularTank(botUserid);
	}
	NameBotTank(bot);
}

// The director's own tank: painted (red by default) so survivors can tell it apart.
void SetRegularTank(int userid)
{
	g_iRegularTank = userid;
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, g_iTankColor[0], g_iTankColor[1], g_iTankColor[2], g_iTankColor[3]);
	if (IsFakeClient(client))
	{
		SetClientInfo(client, "name", "Regular Tank");
	}
}

void NameBotTank(int client)
{
	if (g_aTankNames.Length == 0)
	{
		return;
	}
	if (g_iTankNameIndex >= g_aTankNames.Length)
	{
		g_iTankNameIndex = 0;
	}
	char name[MAX_NAME_LENGTH];
	g_aTankNames.GetString(g_iTankNameIndex++, name, sizeof(name));
	SetClientInfo(client, "name", name);
}

// The witch spawns at the same spot in both halves (it matters where she sits in this mode).
void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive || !g_bInRound)
	{
		return;
	}
	int witch = event.GetInt("witchid");
	if (IsFirstHalf())
	{
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", g_vWitchPos);
	}
	else if (g_vWitchPos[0] != 0.0)
	{
		TeleportEntity(witch, g_vWitchPos, NULL_VECTOR, NULL_VECTOR);
		g_vWitchPos[0] = 0.0;
	}
	else
	{
		AcceptEntityInput(witch, "Kill");   // a later witch from the director
	}
}

// ---------------------------------------------------------------------------
// Survivors: incap messages, !slayme
// ---------------------------------------------------------------------------

void Event_PlayerIncapped(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive || !g_bInRound)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0 || GetClientTeam(client) != TEAM_SURVIVOR)
	{
		return;
	}
	SlayHint(client);

	// How much health the tank that incapped you had left.
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (g_iOptions & OPT_HEALTH_INFO && g_bSpawning && !IsFakeClient(client)
		&& attacker > 0 && IsClientInGame(attacker) && GetClientTeam(attacker) == TEAM_INFECTED)
	{
		CPrintToChatEx(client, attacker, "%s %t", TAG, "Survivor_WasIncappedBy", attacker, GetEntProp(attacker, Prop_Data, "m_iHealth"));
	}
}

// A player took over an incapacitated survivor bot.
void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bActive || !g_bInRound)
	{
		return;
	}
	int client = GetClientOfUserId(event.GetInt("player"));
	if (client > 0 && GetClientTeam(client) == TEAM_SURVIVOR)
	{
		SlayHint(client);
	}
}

void SlayHint(int client)
{
	if (IsFakeClient(client) || !IsIncapped(client))
	{
		return;
	}
	CPrintToChat(client, "%s %t", TAG, "SurvivorSlayYourself");
	if (g_iOptions & OPT_CRAWLING)
	{
		CPrintToChat(client, "%s %t", TAG, "SurvivorSlayYourself_OrCrawl");
	}
}

Action Cmd_SlayMe(int client, int args)
{
	if (!g_bActive || client == 0 || !IsPlayerAlive(client) || GetClientTeam(client) != TEAM_SURVIVOR)
	{
		return Plugin_Handled;
	}
	if (!IsIncapped(client))
	{
		CPrintToChat(client, "%s %t", TAG, "SurvivorIsNotIncapped");
		return Plugin_Handled;
	}
	ForcePlayerSuicide(client);
	CPrintToChatAllEx(client, "%s %t", TAG, "SurvivorSlayedThemself", client);
	return Plugin_Handled;
}

Action Cmd_Config(int client, int args)
{
	if (!g_bActive || client == 0)
	{
		return Plugin_Handled;
	}
	CPrintToChat(client, "%s %t (%s)", TAG, "ConfigInfo_Title", PLUGIN_VERSION);
	ConfigLine(client, "ConfigInfo_Bots", (g_iOptions & OPT_BOTS) != 0);
	ConfigLine(client, "ConfigInfo_InfoPanel", (g_iOptions & OPT_HUD) != 0);
	ConfigLine(client, "ConfigInfo_Crawling", (g_iOptions & OPT_CRAWLING) != 0);
	ConfigLine(client, "ConfigInfo_TanksHealth", (g_iOptions & OPT_HEALTH_INFO) != 0);
	ConfigLine(client, "ConfigInfo_RegularTanks", !(g_iOptions & OPT_NO_REGULAR));
	ConfigLine(client, "ConfigInfo_ShotgunMode", (g_iOptions & OPT_SHOTGUN_MODE) != 0);
	return Plugin_Handled;
}

void ConfigLine(int client, const char[] phrase, bool on)
{
	CPrintToChat(client, "- %t: %t", phrase, on ? "ConfigInfo_Enabled" : "ConfigInfo_Disabled");
}

// ---------------------------------------------------------------------------
// Info panel and spectator view
// ---------------------------------------------------------------------------

// Who the tank you aim at is (survivors: and whether it's the regular one; infected: its health).
Action Timer_Hud(Handle timer)
{
	if (!g_bActive || !g_bInRound)
	{
		g_hHud = null;
		return Plugin_Stop;
	}
	char text[128], regular[32];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (!IsClientInGame(p) || IsFakeClient(p) || GetClientMenu(p) == MenuSource_Normal)   // don't cover a menu
		{
			continue;
		}
		int target = GetClientAimTarget(p, true);
		if (target <= 0 || GetClientTeam(target) != TEAM_INFECTED || IsVoteInProgress())
		{
			continue;
		}
		int team = GetClientTeam(p);
		if (team == TEAM_SURVIVOR)
		{
			regular[0] = '\0';
			if (GetClientUserId(target) == g_iRegularTank)
			{
				FormatEx(regular, sizeof(regular), " (%T)", "IsRegular", p);
			}
			FormatEx(text, sizeof(text), "Tank%s: %N", regular, target);
		}
		else if (team == TEAM_INFECTED)
		{
			FormatEx(text, sizeof(text), "Tank: %N (HP: %d)", target, GetEntProp(target, Prop_Data, "m_iHealth"));
		}
		else
		{
			continue;
		}
		Panel panel = new Panel();
		panel.DrawText(text);
		panel.Send(p, Panel_Handler, 1);
		delete panel;
	}
	return Plugin_Continue;
}

int Panel_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

// A dead human tank sees the spectator panel ("spawning disabled"); hide it, the hint shows the timer.
Action Message_VGUIMenu(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (!g_bActive || playersNum < 1)
	{
		return Plugin_Continue;
	}
	int client = players[0];
	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}
	char panel[64];
	msg.ReadString(panel, sizeof(panel));
	if (StrEqual(panel, "specgui") && msg.ReadBool())
	{
		RequestFrame(Frame_HideSpecPanel, GetClientUserId(client));
	}
	return Plugin_Continue;
}

void Frame_HideSpecPanel(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && !IsPlayerAlive(client))
	{
		ShowVGUIPanel(client, "specgui", null, false);
	}
}

// ---------------------------------------------------------------------------
// Shotgun mode: weapon spawns become shotguns and a few big guns, the same in both halves
// ---------------------------------------------------------------------------

// Weapon spawn classnames that get replaced; "weapon_spawn" is checked by its weapon id.
static const char g_sReplaced[][] = {
	// tier 1
	"weapon_pistol_spawn", "weapon_pistol_magnum_spawn", "weapon_smg_spawn", "weapon_smg_silenced_spawn",
	"weapon_smg_mp5_spawn",
	// tier 2
	"weapon_rifle_ak47_spawn", "weapon_rifle_sg552_spawn", "weapon_sniper_awp_spawn", "weapon_sniper_scout_spawn",
	"weapon_sniper_military_spawn", "weapon_rifle_spawn", "weapon_hunting_rifle_spawn", "weapon_rifle_desert_spawn"
};
static const int g_iReplacedIds[] = {1, 32, 2, 7, 33, 26, 34, 35, 36, 10, 5, 6, 9};
#define TIER2_START 5

// Shotguns first, then the big guns.
static const int g_iNewIds[] = {3, 8, 4, 11, 37, 21, 20};
static const char g_sNewModels[][] = {
	"models/w_models/weapons/w_shotgun.mdl", "models/w_models/weapons/w_pumpshotgun_a.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl", "models/w_models/weapons/w_shotgun_spas.mdl",
	"models/w_models/weapons/w_m60.mdl", "models/w_models/weapons/w_grenade_launcher.mdl",
	"models/weapons/melee/w_chainsaw.mdl"
};
#define BIG_GUNS_START 4

void ChangeWeaponSpawns()
{
	bool firstHalf = IsFirstHalf();
	if (firstHalf)
	{
		g_aWeaponSpots.Clear();
	}
	else if (g_aWeaponSpots.Length == 0)
	{
		return;
	}

	char classname[64];
	int bigGuns = 0;
	for (int e = MaxClients + 1, count = GetMaxEntities(); e < count; e++)
	{
		if (!IsValidEntity(e) || !GetEntityClassname(e, classname, sizeof(classname)))
		{
			continue;
		}
		int index = ReplacedIndex(e, classname);
		if (index == -1)
		{
			continue;
		}
		if (g_iOptions & OPT_SGM_KEEP_TIER1 && index < TIER2_START)
		{
			continue;
		}
		if (firstHalf)
		{
			int pick;
			if (bigGuns >= g_iBigGunsLimit || g_bFirstMap || index < TIER2_START)
			{
				pick = GetRandomInt(0, BIG_GUNS_START - 1);
			}
			else
			{
				pick = GetRandomInt(0, sizeof(g_iNewIds) - 1);
				if (pick >= BIG_GUNS_START)
				{
					bigGuns++;
				}
			}
			float pos[3], ang[3], spot[7];
			GetEntPropVector(e, Prop_Send, "m_vecOrigin", pos);
			GetEntPropVector(e, Prop_Send, "m_angRotation", ang);
			spot[0] = pos[0];
			spot[1] = pos[1];
			spot[2] = pos[2];
			spot[3] = ang[0];
			spot[4] = ang[1];
			spot[5] = ang[2];
			spot[6] = float(pick);
			g_aWeaponSpots.PushArray(spot);
			SpawnWeapon(pick, spot);
		}
		RemoveEntity(e);
	}

	// Second half: the same weapons at the same spots.
	if (!firstHalf)
	{
		float spot[7];
		for (int i = 0; i < g_aWeaponSpots.Length; i++)
		{
			g_aWeaponSpots.GetArray(i, spot);
			SpawnWeapon(RoundToZero(spot[6]), spot);
		}
		g_aWeaponSpots.Clear();
	}
}

int ReplacedIndex(int entity, const char[] classname)
{
	if (StrEqual(classname, "weapon_spawn"))
	{
		int id = GetEntProp(entity, Prop_Send, "m_weaponID");
		for (int i = 0; i < sizeof(g_iReplacedIds); i++)
		{
			if (g_iReplacedIds[i] == id)
			{
				return i;
			}
		}
		return -1;
	}
	for (int i = 0; i < sizeof(g_sReplaced); i++)
	{
		if (StrEqual(classname, g_sReplaced[i]))
		{
			return i;
		}
	}
	return -1;
}

void SpawnWeapon(int pick, const float spot[7])
{
	int weapon = CreateEntityByName("weapon_spawn");
	if (weapon == -1)
	{
		return;
	}
	char count[4];
	IntToString(pick >= BIG_GUNS_START ? 1 : MAX_TANKS, count, sizeof(count));   // big guns: one per spot
	DispatchKeyValue(weapon, "count", count);
	SetEntProp(weapon, Prop_Send, "m_weaponID", g_iNewIds[pick]);
	SetEntityModel(weapon, g_sNewModels[pick]);
	float pos[3], ang[3];
	pos[0] = spot[0]; pos[1] = spot[1]; pos[2] = spot[2];
	ang[0] = spot[3]; ang[1] = spot[4]; ang[2] = spot[5];
	TeleportEntity(weapon, pos, ang, NULL_VECTOR);
	DispatchSpawn(weapon);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool IsFirstHalf()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound") == 0;
}

bool IsIncapped(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}

// During intros survivors sit at 0,0 (m_bInIntro isn't reliable, e.g. on c3m1).
bool IsIntroRunning()
{
	if (g_bInRound)
	{
		return false;
	}
	for (int s = 1; s <= MaxClients; s++)
	{
		if (IsClientInGame(s) && GetClientTeam(s) == TEAM_SURVIVOR)
		{
			float pos[3];
			GetEntPropVector(s, Prop_Send, "m_vecOrigin", pos);
			return pos[0] == 0.0 && pos[1] == 0.0;
		}
	}
	return false;
}

int LivingInfectedCount()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && IsPlayerAlive(i))
		{
			count++;
		}
	}
	return count;
}

int HumanInfectedCount()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			count++;
		}
	}
	return count;
}

void PrintToTeam(int team, const char[] phrase)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			CPrintToChat(i, "%s %T", TAG, phrase, i);
		}
	}
}

// A human to run cheat spawn commands through, taking turns (anti-flood plugins notice one player
// spamming z_spawn_old).
int AnyHuman()
{
	static int next = 1;
	for (int tries = 0; tries < MaxClients; tries++)
	{
		if (next > MaxClients)
		{
			next = 1;
		}
		int client = next++;
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			return client;
		}
	}
	return 0;
}

void CheatCommand(const char[] command, const char[] arg)
{
	int client = AnyHuman();
	if (client == 0)
	{
		return;
	}
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arg);
	SetCommandFlags(command, flags);
}

int FindEntityByTargetName(const char[] classname, const char[] targetname)
{
	char name[64];
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, classname)) != -1)
	{
		GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
		if (StrEqual(name, targetname))
		{
			return ent;
		}
	}
	return -1;
}
