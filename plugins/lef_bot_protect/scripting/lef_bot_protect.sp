/**
 * Lefordianos Bot Protect
 *
 * When there aren't enough players, survivor bots fill the empty spots, and infected players tend
 * to focus them because bots are easy targets. This takes a small share off the damage infected
 * players deal to survivor bots (default 15%), so a bot isn't a free kill, without changing how the
 * game plays for humans.
 *
 * Only damage from infected *players* (specials, tank, spit) is reduced; common infected, falls,
 * fire and teammates are untouched. Versus and scavenge only by default.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0.0"

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Bot Protect",
	author      = "rats4final",
	description = "Survivor bots take a little less damage from infected players",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar g_cvReduction, g_cvVersusOnly;

// Health is whole points, so small hits (spit ticks) could round down to nothing. The fraction
// left over is carried to the bot's next hit, so the total is exactly the configured share.
float g_fCarry[MAXPLAYERS + 1];

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
	CreateConVar("lef_bot_protect_version", PLUGIN_VERSION, "Lefordianos Bot Protect version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvReduction  = CreateConVar("lef_bot_damage_reduction", "15", "Percent less damage survivor bots take from infected players. 0 = off (vanilla).", _, true, 0.0, true, 90.0);
	g_cvVersusOnly = CreateConVar("lef_bot_protect_versus_only", "1", "Only in modes where players control the infected (versus, scavenge).", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "lef_bot_protect");

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
	g_fCarry[client] = 0.0;
	if (IsFakeClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	float reduction = g_cvReduction.FloatValue;
	if (reduction <= 0.0 || attacker < 1 || attacker > MaxClients || !IsClientInGame(attacker))
	{
		return Plugin_Continue;
	}
	if (GetClientTeam(victim) != TEAM_SURVIVOR || GetClientTeam(attacker) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}
	if (g_cvVersusOnly.BoolValue && !L4D_HasPlayerControlledZombies())
	{
		return Plugin_Continue;
	}

	float total = damage * (1.0 - reduction / 100.0) + g_fCarry[victim];
	damage = float(RoundToFloor(total));
	g_fCarry[victim] = total - damage;
	return Plugin_Changed;
}
