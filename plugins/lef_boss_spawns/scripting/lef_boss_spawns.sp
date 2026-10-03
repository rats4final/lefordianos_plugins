/**
 * Lefordianos Boss Spawns
 *
 * Makes versus tank and witch spawns fair and predictable for both teams:
 *
 *  1. Chance per map: rolls once at the start of the first half whether this map
 *     gets a tank and/or a witch (e.g. 80% / 60%). The second half gets the same answer.
 *  2. Same spot for both teams: whatever spot the tank/witch spawned on in the first
 *     half, it spawns there again in the second half. Vanilla can put the tank before a
 *     drop for one team and after it for the other.
 *  3. Announced: everyone is told when survivors leave the saferoom, e.g.
 *     "Tank: 63% | Witch: none this map", so the first team isn't surprised by a tank
 *     the second team knows is coming. While a tank is still to come, a chat reminder repeats every
 *     lef_boss_remind_interval seconds ("Tank at 63%, you're at 41%"), and a warning shows when the
 *     survivors get within lef_boss_warn_distance percent of it. Progress is measured like !current
 *     (furthest survivor + versus_boss_buffer), which is what triggers the tank.
 *
 * Works with or without these (they make it better):
 *  - witch_and_tankifier (+ l4d2lib): picks good flows, avoiding bad spots per map.
 *  - l4d_boss_percent: if loaded, it does the announcing (and !boss/!tank/!witch);
 *    we just tell it which boss is off this map.
 *
 * Point 2 is a standalone port of confogl's BossSpawning module
 * ("confogl_lock_boss_spawns"). If confogl is loaded with that turned on, we leave
 * spawn locking to it.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <l4d2_boss_percents>

#define PLUGIN_VERSION "1.1.0"

#define MAX_TRACKED 5

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Boss Spawns",
	author      = "rats4final; spawn locking ported from confogl's BossSpawning",
	description = "Per-map tank/witch chance, same spawn spots for both teams, announced flows",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar
	g_cvTankChance,
	g_cvWitchChance,
	g_cvSkipFinales,
	g_cvLockSpawns,
	g_cvAnnounce,
	g_cvRemindInterval,
	g_cvWarnDistance;

ConVar g_cvBossBuffer;

// Tank reminders, per round.
bool  g_bLeftStart;
bool  g_bTankSpawned;
bool  g_bWarnedClose;
float g_fNextRemind;

bool g_bBossPercent;

// This map's roll, decided in the first half and reused in the second.
bool g_bRolled;
bool g_bTankThisMap;
bool g_bWitchThisMap;

// Spawn locking, per half: [0] = first half, [1] = second half.
bool  g_bFinaleStarted;
bool  g_bDeleteRoundStartWitches;
int   g_iTankCount[2];
int   g_iWitchCount[2];
float g_fTankPos[MAX_TRACKED][3];
float g_fWitchPos[MAX_TRACKED][3];
float g_fWitchAng[MAX_TRACKED][3];
char  g_sMap[64];

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
	LoadTranslations("lef_boss_spawns.phrases");

	CreateConVar("lef_boss_spawns_version", PLUGIN_VERSION, "Lefordianos Boss Spawns version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvTankChance  = CreateConVar("lef_boss_tank_chance", "100", "Percent chance that a map has a flow tank (same for both teams). 100 = every map.", _, true, 0.0, true, 100.0);
	g_cvWitchChance = CreateConVar("lef_boss_witch_chance", "100", "Percent chance that a map has a flow witch (same for both teams). 100 = every map.", _, true, 0.0, true, 100.0);
	g_cvSkipFinales = CreateConVar("lef_boss_skip_finales", "1", "Leave finale maps alone (their tanks are scripted by the finale).", _, true, 0.0, true, 1.0);
	g_cvLockSpawns  = CreateConVar("lef_boss_lock_spawns", "1", "Second-half tanks and witches spawn on the same spot as in the first half.", _, true, 0.0, true, 1.0);
	g_cvAnnounce    = CreateConVar("lef_boss_announce", "1", "Announce tank/witch flows when survivors leave the saferoom (skipped if l4d_boss_percent is loaded, which announces instead).", _, true, 0.0, true, 1.0);
	g_cvRemindInterval = CreateConVar("lef_boss_remind_interval", "120", "Seconds between chat reminders of the tank's spot while it's still to come. 0 = off.", _, true, 0.0);
	g_cvWarnDistance   = CreateConVar("lef_boss_warn_distance", "5", "Warn when survivors are within this many percent of the tank's spot. 0 = off.", _, true, 0.0, true, 50.0);
	AutoExecConfig(true, "lef_boss_spawns");

	g_cvBossBuffer = FindConVar("versus_boss_buffer");
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_PostNoCopy);
	CreateTimer(2.0, Timer_TankReminder, _, TIMER_REPEAT);

	RegConsoleCmd("sm_bosses", Cmd_Bosses, "Show this map's tank and witch flow");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("finale_start", Event_FinaleStart, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_LeftStartArea, EventHookMode_PostNoCopy);
	HookEvent("witch_spawn", Event_WitchSpawn);
}

public void OnAllPluginsLoaded()
{
	g_bBossPercent = LibraryExists("l4d_boss_percent");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "l4d_boss_percent"))
	{
		g_bBossPercent = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "l4d_boss_percent"))
	{
		g_bBossPercent = false;
	}
}

public void OnMapStart()
{
	GetCurrentMap(g_sMap, sizeof(g_sMap));

	g_bRolled                  = false;
	g_bFinaleStarted           = false;
	g_bDeleteRoundStartWitches = false;
	g_iTankCount[0]  = g_iTankCount[1]  = 0;
	g_iWitchCount[0] = g_iWitchCount[1] = 0;
}

// ---------------------------------------------------------------------------
// 1. Chance per map
// ---------------------------------------------------------------------------

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bFinaleStarted = false;
	g_bLeftStart     = false;
	g_bTankSpawned   = false;
	g_bWarnedClose   = false;

	// witch_and_tankifier picks flows at 0.5s and l4d_boss_percent reads them at 5s,
	// so 1s lands in between.
	CreateTimer(1.0, Timer_ApplyRoll, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ApplyRoll(Handle timer)
{
	if (!IsVersus() || (g_cvSkipFinales.BoolValue && L4D_IsMissionFinalMap()))
	{
		return Plugin_Stop;
	}

	if (!g_bRolled)
	{
		g_bRolled       = true;
		g_bTankThisMap  = GetRandomFloat(0.0, 100.0) < g_cvTankChance.FloatValue;
		g_bWitchThisMap = GetRandomFloat(0.0, 100.0) < g_cvWitchChance.FloatValue;
	}

	// Applied every half: both halves' flags are set together, but re-applying keeps
	// the second half right even if something else touched them in between.
	if (!g_bTankThisMap)
	{
		for (int half = 0; half < 2; half++)
		{
			L4D2Direct_SetVSTankToSpawnThisRound(half, false);
			L4D2Direct_SetVSTankFlowPercent(half, 0.0);
		}
	}

	if (!g_bWitchThisMap)
	{
		for (int half = 0; half < 2; half++)
		{
			L4D2Direct_SetVSWitchToSpawnThisRound(half, false);
			L4D2Direct_SetVSWitchFlowPercent(half, 0.0);
		}
	}

	if (g_bBossPercent)
	{
		// Without these it would say "Tank: 0%"; with them it says "None".
		if (!g_bTankThisMap)
		{
			SetTankDisabled(true);
		}
		if (!g_bWitchThisMap)
		{
			SetWitchDisabled(true);
		}
		UpdateBossPercents();
	}

	return Plugin_Stop;
}

// ---------------------------------------------------------------------------
// 3. Announcing
// ---------------------------------------------------------------------------

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	g_bTankSpawned = true;
}

// Reminders and the "getting close" warning while this round's flow tank is still to come.
Action Timer_TankReminder(Handle timer)
{
	if (!g_bLeftStart || g_bTankSpawned || g_bFinaleStarted || !IsVersus())
	{
		return Plugin_Continue;
	}

	int half = InSecondHalf() ? 1 : 0;
	if (!L4D2Direct_GetVSTankToSpawnThisRound(half))
	{
		return Plugin_Continue;
	}

	float maxFlow = L4D2Direct_GetMapMaxFlowDistance();
	if (maxFlow <= 0.0)
	{
		return Plugin_Continue;
	}

	float tank     = L4D2Direct_GetVSTankFlowPercent(half);
	float progress = (L4D2_GetFurthestSurvivorFlow() + (g_cvBossBuffer != null ? g_cvBossBuffer.FloatValue : 0.0)) / maxFlow;
	if (progress >= tank)
	{
		return Plugin_Continue;   // about to spawn
	}

	int tankPct = RoundToNearest(tank * 100.0), nowPct = RoundToFloor(progress * 100.0);
	float warn = g_cvWarnDistance.FloatValue / 100.0;
	if (!g_bWarnedClose && warn > 0.0 && tank - progress <= warn)
	{
		g_bWarnedClose = true;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				CPrintToChat(i, "%T", "Tank Close", i, tankPct, nowPct);
				PrintHintText(i, "%T", "Tank Close Hint", i, tankPct);
			}
		}
		return Plugin_Continue;
	}

	float interval = g_cvRemindInterval.FloatValue;
	if (interval > 0.0 && GetGameTime() >= g_fNextRemind)
	{
		g_fNextRemind = GetGameTime() + interval;
		CPrintToChatAll("%t", "Tank Reminder", tankPct, nowPct);
	}
	return Plugin_Continue;
}

void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	g_bLeftStart = true;
	// The first reminder comes one interval after the announcement.
	g_fNextRemind = GetGameTime() + g_cvRemindInterval.FloatValue;
	if (g_cvAnnounce.BoolValue && !g_bBossPercent && IsVersus())
	{
		AnnounceBosses(0);
	}
}

Action Cmd_Bosses(int client, int args)
{
	AnnounceBosses(client);
	return Plugin_Handled;
}

void AnnounceBosses(int client)
{
	int half = InSecondHalf() ? 1 : 0;
	char tank[64], witch[64];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (client != 0 && i != client)
		{
			continue;
		}
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}

		DescribeBoss(i, L4D2Direct_GetVSTankToSpawnThisRound(half), L4D2Direct_GetVSTankFlowPercent(half), tank, sizeof(tank));
		DescribeBoss(i, L4D2Direct_GetVSWitchToSpawnThisRound(half), L4D2Direct_GetVSWitchFlowPercent(half), witch, sizeof(witch));
		CPrintToChat(i, "%T", "Announce", i, tank, witch);
	}

	if (client == 0)
	{
		PrintToServer("[Bosses] tank %.0f%% (%d), witch %.0f%% (%d)",
			L4D2Direct_GetVSTankFlowPercent(half) * 100.0, L4D2Direct_GetVSTankToSpawnThisRound(half),
			L4D2Direct_GetVSWitchFlowPercent(half) * 100.0, L4D2Direct_GetVSWitchToSpawnThisRound(half));
	}
}

void DescribeBoss(int client, bool spawns, float flow, char[] buffer, int maxlength)
{
	if (spawns && flow > 0.0)
	{
		FormatEx(buffer, maxlength, "{red}%d%%{default}", RoundFloat(flow * 100.0));
	}
	else
	{
		FormatEx(buffer, maxlength, "{olive}%T{default}", "No Boss", client);
	}
}

// ---------------------------------------------------------------------------
// 2. Same spot for both teams (port of confogl's BossSpawning)
// ---------------------------------------------------------------------------

bool ShouldLockSpawns()
{
	if (!g_cvLockSpawns.BoolValue || !IsVersus())
	{
		return false;
	}

	// confogl does the same thing; don't teleport twice.
	ConVar confoglLock = FindConVar("confogl_lock_boss_spawns");
	if (confoglLock != null && confoglLock.BoolValue && LibraryExists("confogl"))
	{
		return false;
	}

	return true;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bFinaleStarted = false;

	// The second half spawns some witches at round start instead of by flow; delete those
	// for a few seconds. c6m1 keeps them (the wedding witches belong to the map).
	if (!StrEqual(g_sMap, "c6m1_riverbank", false))
	{
		g_bDeleteRoundStartWitches = true;
		CreateTimer(5.0, Timer_StopDeletingWitches);
	}
}

Action Timer_StopDeletingWitches(Handle timer)
{
	g_bDeleteRoundStartWitches = false;
	return Plugin_Stop;
}

void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bFinaleStarted = true;
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	// Finale tanks are the finale's business, and c5m5's tank can end up behind the other team.
	if (client <= 0 || !ShouldLockSpawns() || g_bFinaleStarted || StrEqual(g_sMap, "c5m5_bridge", false))
	{
		return;
	}

	int half = InSecondHalf() ? 1 : 0;
	if (g_iTankCount[half] >= MAX_TRACKED)
	{
		return;
	}

	if (half == 0)
	{
		GetClientAbsOrigin(client, g_fTankPos[g_iTankCount[0]]);
		g_iTankCount[0]++;
	}
	else if (g_iTankCount[0] > g_iTankCount[1])
	{
		TeleportEntity(client, g_fTankPos[g_iTankCount[1]], NULL_VECTOR, NULL_VECTOR);
		g_iTankCount[1]++;
	}
}

void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!ShouldLockSpawns())
	{
		return;
	}

	int witch = event.GetInt("witchid");
	if (!IsValidEntity(witch))
	{
		return;
	}

	if (g_bDeleteRoundStartWitches)
	{
		RemoveEntity(witch);
		return;
	}

	int half = InSecondHalf() ? 1 : 0;
	if (g_iWitchCount[half] >= MAX_TRACKED)
	{
		return;
	}

	if (half == 0)
	{
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", g_fWitchPos[g_iWitchCount[0]]);
		GetEntPropVector(witch, Prop_Send, "m_angRotation", g_fWitchAng[g_iWitchCount[0]]);
		g_iWitchCount[0]++;
	}
	else if (g_iWitchCount[0] > g_iWitchCount[1])
	{
		TeleportEntity(witch, g_fWitchPos[g_iWitchCount[1]], g_fWitchAng[g_iWitchCount[1]], NULL_VECTOR);
		g_iWitchCount[1]++;
	}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool IsVersus()
{
	return L4D_GetGameModeType() == GAMEMODE_VERSUS;
}

bool InSecondHalf()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound") != 0;
}
