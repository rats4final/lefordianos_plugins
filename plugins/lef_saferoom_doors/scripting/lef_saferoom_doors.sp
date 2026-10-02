/**
 * Lefordianos Saferoom Doors
 *
 * Tells everyone who uses the saferoom doors:
 *  - Start saferoom: who opened the door (once per round), or that it opened by itself.
 *  - End saferoom: who closed the door while teammates were still outside (default), or every
 *    open/close (lef_doors_end 2). Handy for catching someone shutting the team out.
 *
 * Both are also written to the server log, so admins can check afterwards.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "1.0.0"

#define TEAM_SURVIVOR 2

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Saferoom Doors",
	author      = "rats4final",
	description = "Announces who opens the start saferoom door and who closes the end one",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar
	g_cvStart,
	g_cvEnd,
	g_cvCooldown;

bool  g_bStartAnnounced;
float g_fNextMessage[MAXPLAYERS + 1];

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
	LoadTranslations("lef_saferoom_doors.phrases");

	CreateConVar("lef_saferoom_doors_version", PLUGIN_VERSION, "Lefordianos Saferoom Doors version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvStart    = CreateConVar("lef_doors_start", "1", "Announce who opens the start saferoom door (once per round). 0 = off.", _, true, 0.0, true, 1.0);
	g_cvEnd      = CreateConVar("lef_doors_end", "1", "End saferoom door: 0 = off, 1 = only when someone closes it with teammates still outside, 2 = every open and close.", _, true, 0.0, true, 2.0);
	g_cvCooldown = CreateConVar("lef_doors_cooldown", "3.0", "Seconds between door messages caused by the same player (stops door-spam flooding the chat).", _, true, 0.0);
	AutoExecConfig(true, "lef_saferoom_doors");

	HookEntityOutput("prop_door_rotating_checkpoint", "OnOpen", Output_DoorOpen);
	HookEntityOutput("prop_door_rotating_checkpoint", "OnClose", Output_DoorClose);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnClientDisconnect(int client)
{
	g_fNextMessage[client] = 0.0;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bStartAnnounced = false;
}

void Output_DoorOpen(const char[] output, int caller, int activator, float delay)
{
	if (caller == L4D_GetCheckpointFirst())
	{
		AnnounceStartDoor(activator);
	}
	else if (caller == L4D_GetCheckpointLast() && g_cvEnd.IntValue == 2 && IsSurvivor(activator) && !IsOnCooldown(activator))
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(activator, name, sizeof(name));
		CPrintToChatAll("%t", "End Opened", name);
	}
}

void Output_DoorClose(const char[] output, int caller, int activator, float delay)
{
	int mode = g_cvEnd.IntValue;
	if (mode == 0 || caller != L4D_GetCheckpointLast() || !IsSurvivor(activator))
	{
		return;
	}

	int outside = CountTeammatesOutside(activator);
	if (mode == 1 && outside == 0)
	{
		return;
	}

	if (IsOnCooldown(activator))
	{
		return;
	}

	char name[MAX_NAME_LENGTH];
	GetClientName(activator, name, sizeof(name));

	if (outside > 0)
	{
		CPrintToChatAll("%t", "End Closed Outside", name, outside);
		LogMessage("\"%L\" closed the end saferoom door with %d teammate(s) outside", activator, outside);
	}
	else
	{
		CPrintToChatAll("%t", "End Closed", name);
	}
}

void AnnounceStartDoor(int activator)
{
	if (!g_cvStart.BoolValue || g_bStartAnnounced)
	{
		return;
	}

	g_bStartAnnounced = true;

	if (IsSurvivor(activator))
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(activator, name, sizeof(name));
		CPrintToChatAll("%t", "Start Opened", name);
		LogMessage("\"%L\" opened the start saferoom door", activator);
	}
	else
	{
		CPrintToChatAll("%t", "Start Opened Itself");
	}
}

// Living survivors (up or down) who are not inside the end saferoom.
int CountTeammatesOutside(int closer)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != closer && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i) && !L4D_IsInLastCheckpoint(i))
		{
			count++;
		}
	}
	return count;
}

bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

bool IsOnCooldown(int client)
{
	float now = GetGameTime();
	if (now < g_fNextMessage[client])
	{
		return true;
	}

	g_fNextMessage[client] = now + g_cvCooldown.FloatValue;
	return false;
}
