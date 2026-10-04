/**
 * Lefordianos Saferoom Doors
 *
 * Tells everyone who uses the saferoom doors:
 *  - Start saferoom: who opened the door (once per round), or that it opened by itself.
 *  - End saferoom: who closed the door while teammates were still outside (default), or every
 *    open/close (lef_doors_end 2). Handy for catching someone shutting the team out.
 *
 * Both are also written to the server log, so admins can check afterwards.
 *
 * Who used a door comes from the game's door_open/door_close events: the door's own OnOpen/OnClose
 * outputs pass the door itself as the activator, so they can't tell who it was.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "1.0.1"

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
	HookEvent("door_open", Event_DoorOpen);
	HookEvent("door_close", Event_DoorClose);
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

// Only used to notice the start door opening with no player behind it (map logic, another plugin).
// The door_open event for a player may come after this output, so give it a moment first.
void Output_DoorOpen(const char[] output, int caller, int activator, float delay)
{
	if (caller == L4D_GetCheckpointFirst() && g_cvStart.BoolValue && !g_bStartAnnounced)
	{
		CreateTimer(0.2, Timer_StartDoorOpened, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_StartDoorOpened(Handle timer)
{
	if (!g_bStartAnnounced)
	{
		g_bStartAnnounced = true;
		CPrintToChatAll("%t", "Start Opened Itself");
	}
	return Plugin_Stop;
}

void Event_DoorOpen(Event event, const char[] eventName, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!event.GetBool("checkpoint") || !IsSurvivor(client))
	{
		return;
	}

	int door = UsedCheckpointDoor(client);
	if (door == -1)
	{
		return;
	}

	if (door == L4D_GetCheckpointFirst())
	{
		AnnounceStartDoor(client);
	}
	else if (g_cvEnd.IntValue == 2 && !IsOnCooldown(client))
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		CPrintToChatAll("%t", "End Opened", name);
	}
}

void Event_DoorClose(Event event, const char[] eventName, bool dontBroadcast)
{
	int mode = g_cvEnd.IntValue;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (mode == 0 || !event.GetBool("checkpoint") || !IsSurvivor(client))
	{
		return;
	}

	int door = UsedCheckpointDoor(client);
	if (door == -1 || door != L4D_GetCheckpointLast())
	{
		return;
	}

	int outside = CountTeammatesOutside(client);
	if (mode == 1 && outside == 0)
	{
		return;
	}

	if (IsOnCooldown(client))
	{
		return;
	}

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	if (outside > 0)
	{
		CPrintToChatAll("%t", "End Closed Outside", name, outside);
		LogMessage("\"%L\" closed the end saferoom door with %d teammate(s) outside", client, outside);
	}
	else
	{
		CPrintToChatAll("%t", "End Closed", name);
	}
}

void AnnounceStartDoor(int client)
{
	if (!g_cvStart.BoolValue || g_bStartAnnounced)
	{
		return;
	}

	g_bStartAnnounced = true;

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	CPrintToChatAll("%t", "Start Opened", name);
	LogMessage("\"%L\" opened the start saferoom door", client);
}

// The door events don't say which door, so take the saferoom door closest to the player who used it.
int UsedCheckpointDoor(int client)
{
	int first = L4D_GetCheckpointFirst();
	int last = L4D_GetCheckpointLast();
	if (first == -1 || last == -1)
	{
		return (first == -1) ? last : first;
	}

	float pos[3];
	GetClientAbsOrigin(client, pos);
	return (DistanceTo(first, pos) <= DistanceTo(last, pos)) ? first : last;
}

float DistanceTo(int entity, const float pos[3])
{
	float origin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
	return GetVectorDistance(origin, pos, true);
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
