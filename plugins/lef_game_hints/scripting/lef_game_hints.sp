/**
 * Lefordianos Game Hints
 *
 * Friendly warnings and tips during the round. Nothing here punishes anyone: it only talks.
 *
 *  1. Pace (survivors): a survivor far ahead of the team (rushing) or far behind it gets a
 *     warning, and optionally the team is told. Distances are a share of the map's length, as in
 *     Harry Potter's no-rushing (which teleports and slays; we only warn).
 *     No warnings for: the last survivor standing, while a tank is up, during finales, for a while
 *     after a panic event (alarms, gauntlets: running is the point), or once inside the end saferoom.
 *
 *  2. Holding an infected (versus): a special infected kept alive without attacking for a long
 *     time, or a ghost that could spawn but doesn't, gets a reminder (and optionally their team).
 *
 *  3. Tank tips: whoever becomes (or is passed) the tank gets a couple of tips, plus one about their team when
 *     it's still respawning. The infected team is told who the tank is.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "1.1.0"

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ZC_TANK       8
#define TANK_TIPS     8

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Game Hints",
	author      = "rats4final; pace idea from Harry Potter's no-rushing",
	description = "Warnings for rushing / falling behind / holding an infected, and tank tips",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar
	g_cvPace,
	g_cvRushDistance,
	g_cvBehindDistance,
	g_cvPaceTellTeam,
	g_cvPanicGrace,
	g_cvHold,
	g_cvHoldTime,
	g_cvGhostTime,
	g_cvHoldTellTeam,
	g_cvTankTips,
	g_cvTankTipCount,
	g_cvCooldown;

bool  g_bLive;
bool  g_bFinale;
float g_fPanicUntil;

float g_fNextWarn[MAXPLAYERS + 1];
float g_fLastAction[MAXPLAYERS + 1];   // infected: last attack/ability, or when they spawned
float g_fGhostReady[MAXPLAYERS + 1];   // infected: seconds spent as a ghost able to spawn
bool  g_bTankTipped[MAXPLAYERS + 1];   // this player already got tips for their current tank

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
	LoadTranslations("lef_game_hints.phrases");

	CreateConVar("lef_game_hints_version", PLUGIN_VERSION, "Lefordianos Game Hints version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvPace           = CreateConVar("lef_hints_pace", "1", "Warn survivors who rush ahead of or fall behind their team.", _, true, 0.0, true, 1.0);
	g_cvRushDistance   = CreateConVar("lef_hints_rush_distance", "0.12", "Rushing: this far ahead of the next teammate, as a share of the map's length (0.12 = 12%).", _, true, 0.01, true, 1.0);
	g_cvBehindDistance = CreateConVar("lef_hints_behind_distance", "0.15", "Behind: this far behind the closest teammate, as a share of the map's length.", _, true, 0.01, true, 1.0);
	g_cvPaceTellTeam   = CreateConVar("lef_hints_pace_tell_team", "1", "Also tell the other survivors who is rushing or behind.", _, true, 0.0, true, 1.0);
	g_cvPanicGrace     = CreateConVar("lef_hints_panic_grace", "90", "Seconds without pace warnings after a panic event (alarms, gauntlets).", _, true, 0.0);
	g_cvHold           = CreateConVar("lef_hints_hold", "1", "Versus: remind infected players who keep a special infected alive (or a ghost ready to spawn) a long time without attacking.", _, true, 0.0, true, 1.0);
	g_cvHoldTime       = CreateConVar("lef_hints_hold_time", "60", "Seconds alive without attacking before the reminder.", _, true, 10.0);
	g_cvGhostTime      = CreateConVar("lef_hints_ghost_time", "60", "Seconds as a ghost able to spawn before the reminder.", _, true, 10.0);
	g_cvHoldTellTeam   = CreateConVar("lef_hints_hold_tell_team", "0", "Also tell the infected team.", _, true, 0.0, true, 1.0);
	g_cvTankTips       = CreateConVar("lef_hints_tank_tips", "1", "Give tips to whoever becomes the tank.", _, true, 0.0, true, 1.0);
	g_cvTankTipCount   = CreateConVar("lef_hints_tank_tip_count", "1", "How many random tips the tank gets (after the controls and the control meter / !pass lines).", _, true, 0.0, true, float(TANK_TIPS));
	g_cvCooldown       = CreateConVar("lef_hints_cooldown", "30", "Seconds between warnings to the same player.", _, true, 5.0);
	AutoExecConfig(true, "lef_game_hints");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_LeftStartArea, EventHookMode_PostNoCopy);
	HookEvent("finale_start", Event_FinaleStart, EventHookMode_PostNoCopy);
	HookEvent("create_panic_event", Event_Panic, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("ability_use", Event_AbilityUse);
	HookEvent("player_death", Event_PlayerDeath);

	CreateTimer(1.0, Timer_Check, _, TIMER_REPEAT);
}

public void OnMapStart()
{
	g_bLive       = false;
	g_bFinale     = false;
	g_fPanicUntil = 0.0;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bLive       = false;
	g_bFinale     = false;
	g_fPanicUntil = 0.0;
	for (int i = 1; i <= MaxClients; i++)
	{
		g_fNextWarn[i] = 0.0;
		g_fGhostReady[i] = 0.0;
	}
}

void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	g_bLive = true;
	float now = GetGameTime();
	for (int i = 1; i <= MaxClients; i++)
	{
		g_fLastAction[i] = now;   // nobody could attack before this
	}
}

void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bFinale = true;
}

void Event_Panic(Event event, const char[] name, bool dontBroadcast)
{
	g_fPanicUntil = GetGameTime() + g_cvPanicGrace.FloatValue;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0)
	{
		g_fLastAction[client] = GetGameTime();
		g_fGhostReady[client] = 0.0;
		g_bTankTipped[client] = false;
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0)
	{
		g_bTankTipped[client] = false;
	}
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (attacker > 0)
	{
		g_fLastAction[attacker] = GetGameTime();
	}
}

void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0)
	{
		g_fLastAction[client] = GetGameTime();
	}
}

bool IsVersus()
{
	return L4D_GetGameModeType() == GAMEMODE_VERSUS;
}

bool IsTankUp()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == ZC_TANK)
		{
			return true;
		}
	}
	return false;
}

Action Timer_Check(Handle timer)
{
	if (!g_bLive)
	{
		return Plugin_Continue;
	}
	if (g_cvPace.BoolValue)
	{
		CheckPace();
	}
	if (g_cvHold.BoolValue && IsVersus())
	{
		CheckHolding();
	}
	if (g_cvTankTips.BoolValue && IsVersus())
	{
		CheckNewTanks();
	}
	return Plugin_Continue;
}

// ---------------------------------------------------------------------------
// 1. Pace
// ---------------------------------------------------------------------------

bool IsStanding(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client)
		&& !L4D_IsPlayerIncapacitated(client) && !L4D_IsPlayerPinned(client);
}

void CheckPace()
{
	if (g_bFinale || GetGameTime() < g_fPanicUntil || IsTankUp())
	{
		return;
	}

	float mapFlow = L4D2Direct_GetMapMaxFlowDistance();
	if (mapFlow <= 0.0)
	{
		return;
	}

	int   survivors[MAXPLAYERS];
	float flow[MAXPLAYERS];
	int   count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsStanding(i))
		{
			survivors[count] = i;
			flow[count]      = L4D2Direct_GetFlowDistance(i) / mapFlow;
			count++;
		}
	}
	if (count < 2)
	{
		return;   // the last one standing does whatever they need to
	}

	float rush = g_cvRushDistance.FloatValue, behind = g_cvBehindDistance.FloatValue;
	for (int k = 0; k < count; k++)
	{
		int client = survivors[k];
		if (IsFakeClient(client) || GetGameTime() < g_fNextWarn[client] || L4D_IsInLastCheckpoint(client))
		{
			continue;
		}

		float ahead = -1.0, closestBehind = 2.0;   // furthest other teammate, and the rearmost one
		for (int j = 0; j < count; j++)
		{
			if (j == k)
			{
				continue;
			}
			if (flow[j] > ahead)
			{
				ahead = flow[j];
			}
			if (flow[j] < closestBehind)
			{
				closestBehind = flow[j];
			}
		}

		if (flow[k] - ahead > rush)
		{
			Warn(client, "Rushing", "Rushing Team", TEAM_SURVIVOR, g_cvPaceTellTeam.BoolValue);
		}
		else if (closestBehind - flow[k] > behind)
		{
			Warn(client, "Behind", "Behind Team", TEAM_SURVIVOR, g_cvPaceTellTeam.BoolValue);
		}
	}
}

// ---------------------------------------------------------------------------
// 2. Holding an infected
// ---------------------------------------------------------------------------

void CheckHolding()
{
	float now = GetGameTime();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_INFECTED || !IsPlayerAlive(i))
		{
			continue;
		}
		if (GetEntProp(i, Prop_Send, "m_zombieClass") == ZC_TANK)
		{
			continue;
		}

		if (L4D_IsPlayerGhost(i))
		{
			// Only seconds where spawning is actually possible count (0 = nothing blocks it).
			if (GetEntProp(i, Prop_Send, "m_ghostSpawnState") == 0)
			{
				g_fGhostReady[i] += 1.0;
			}
			if (g_fGhostReady[i] >= g_cvGhostTime.FloatValue && now >= g_fNextWarn[i])
			{
				Warn(i, "Holding Ghost", "Holding Ghost Team", TEAM_INFECTED, g_cvHoldTellTeam.BoolValue);
			}
		}
		else if (now - g_fLastAction[i] >= g_cvHoldTime.FloatValue && now >= g_fNextWarn[i])
		{
			Warn(i, "Holding Alive", "Holding Alive Team", TEAM_INFECTED, g_cvHoldTellTeam.BoolValue);
		}
	}
}

// ---------------------------------------------------------------------------
// 3. Tank tips
// ---------------------------------------------------------------------------

// Checked every second rather than on tank_spawn: a tank handed over later (frustration, tank pass)
// changes hands without a new spawn event.
void CheckNewTanks()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_bTankTipped[i] && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED
			&& IsPlayerAlive(i) && !L4D_IsPlayerGhost(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == ZC_TANK)
		{
			g_bTankTipped[i] = true;
			GiveTankTips(i);
		}
	}
}

void GiveTankTips(int tank)
{
	// Their team: who is the tank.
	char name[MAX_NAME_LENGTH];
	GetClientName(tank, name, sizeof(name));
	int teammatesUp;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == tank || !IsClientInGame(i) || GetClientTeam(i) != TEAM_INFECTED)
		{
			continue;
		}
		if (IsPlayerAlive(i) && !L4D_IsPlayerGhost(i))
		{
			teammatesUp++;
		}
		if (!IsFakeClient(i))
		{
			CPrintToChat(i, "%T", "Tank Is", i, name);
		}
	}

	// The tank: the situation first, then the controls, the control meter and !pass, then random tips.
	CPrintToChat(tank, "%T", teammatesUp == 0 ? "Tank Team Respawning" : "Tank Team Up", tank);
	CPrintToChat(tank, "%T", "Tank Controls", tank);
	CPrintToChat(tank, "%T", CommandExists("sm_pass") ? "Tank Meter Pass" : "Tank Meter", tank);

	int order[TANK_TIPS];
	for (int i = 0; i < TANK_TIPS; i++)
	{
		order[i] = i + 1;
	}
	for (int i = TANK_TIPS - 1; i > 0; i--)
	{
		int j = GetRandomInt(0, i), tmp = order[i];
		order[i] = order[j];
		order[j] = tmp;
	}

	char phrase[16];
	for (int i = 0; i < g_cvTankTipCount.IntValue; i++)
	{
		FormatEx(phrase, sizeof(phrase), "Tank Tip %d", order[i]);
		CPrintToChat(tank, "%T", phrase, tank);
	}
}

// ---------------------------------------------------------------------------

void Warn(int client, const char[] selfPhrase, const char[] teamPhrase, int team, bool tellTeam)
{
	g_fNextWarn[client] = GetGameTime() + g_cvCooldown.FloatValue;
	CPrintToChat(client, "%T", selfPhrase, client);
	PrintHintText(client, "%T", selfPhrase, client);

	if (!tellTeam)
	{
		return;
	}
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			CPrintToChat(i, "%T", teamPhrase, i, name);
		}
	}
}
