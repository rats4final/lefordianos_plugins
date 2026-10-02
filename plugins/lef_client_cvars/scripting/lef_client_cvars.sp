/**
 * Lefordianos Client Cvars
 *
 * Checks players' own game settings (client cvars) and kicks anyone using values that give an
 * unfair advantage: full brightness (mat_fullbright), no fog, a brighter flashlight, wireframe, etc.
 *
 * A standalone port of confogl's ClientSettings module (Confogl Team), so it works without confogl.
 * The list of checked cvars is the competitive repo's cfg/cvar_tracking.cfg, converted to our
 * command name (cfg/lefordianos/client_cvars.cfg), so the two never clash if both are loaded.
 *
 * Every lef_clientcvars_interval seconds it asks each player for every tracked cvar. A value
 * outside the allowed range means a kick (or a log line, per entry). A cvar the player's game
 * refuses to report (protected or missing, usually a cheat) also means a kick, unless
 * lef_clientcvars_kick_missing is 0.
 *
 *   lef_trackclientcvar <cvar> <hasMin> <min> [<hasMax> <max> [<action: 0 kick, 1 log>]]
 *   lef_resetclientcvars          clear the list (the config runs it before adding entries)
 *   !clientcvars                  list what's checked
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.0.0"
#define CVAR_MAXLEN    64

enum
{
	Action_Kick = 0,
	Action_Log
};

enum struct Tracked
{
	bool  hasMin;
	float min;
	bool  hasMax;
	float max;
	int   action;
	char  cvar[CVAR_MAXLEN];
}

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Client Cvars",
	author      = "rats4final; port of confogl's ClientSettings (Confogl Team)",
	description = "Kicks players whose client cvars give an unfair advantage (fullbright, no fog...)",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar
	g_cvEnable,
	g_cvInterval,
	g_cvKickMissing;

ArrayList g_aTracked;
Handle    g_hTimer;

public void OnPluginStart()
{
	LoadTranslations("lef_client_cvars.phrases");

	CreateConVar("lef_client_cvars_version", PLUGIN_VERSION, "Lefordianos Client Cvars version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvEnable      = CreateConVar("lef_clientcvars_enable", "1", "Check players' client cvars.", _, true, 0.0, true, 1.0);
	g_cvInterval    = CreateConVar("lef_clientcvars_interval", "5.0", "Seconds between checks.", _, true, 1.0);
	g_cvKickMissing = CreateConVar("lef_clientcvars_kick_missing", "1", "Kick players whose game refuses to report a tracked cvar (protected or missing; usually a cheat).", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "lef_client_cvars");

	g_cvInterval.AddChangeHook(OnIntervalChanged);

	RegServerCmd("lef_trackclientcvar", Cmd_Track, "lef_trackclientcvar <cvar> <hasMin> <min> [<hasMax> <max> [<action: 0 kick, 1 log>]]");
	RegServerCmd("lef_resetclientcvars", Cmd_Reset, "Clear the list of tracked client cvars");
	RegConsoleCmd("sm_clientcvars", Cmd_List, "List the client cvars this server checks");

	g_aTracked = new ArrayList(sizeof(Tracked));
	StartTimer();
}

void OnIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	StartTimer();
}

void StartTimer()
{
	delete g_hTimer;
	g_hTimer = CreateTimer(g_cvInterval.FloatValue, Timer_Check, _, TIMER_REPEAT);
}

Action Timer_Check(Handle timer)
{
	if (!g_cvEnable.BoolValue || g_aTracked.Length == 0)
	{
		return Plugin_Continue;
	}

	Tracked t;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client))
		{
			continue;
		}

		for (int i = 0; i < g_aTracked.Length; i++)
		{
			g_aTracked.GetArray(i, t);
			QueryClientConVar(client, t.cvar, QueryReply, i);
		}
	}

	return Plugin_Continue;
}

void QueryReply(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, int index)
{
	if (!IsClientInGame(client) || IsClientInKickQueue(client) || index >= g_aTracked.Length)
	{
		return;
	}

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	if (result != ConVarQuery_Okay)
	{
		if (g_cvKickMissing.BoolValue)
		{
			LogMessage("Kicking %L: client cvar %s is protected or missing", client, cvarName);
			CPrintToChatAll("%t", "Kicked Missing", name, cvarName);
			KickClient(client, "%T", "Kick Reason Missing", client, cvarName);
		}
		return;
	}

	Tracked t;
	g_aTracked.GetArray(index, t);

	float value = StringToFloat(cvarValue);
	if ((t.hasMin && value < t.min) || (t.hasMax && value > t.max))
	{
		char range[64];
		FormatRange(t, range, sizeof(range));

		if (t.action == Action_Log)
		{
			LogMessage("%L has a disallowed value for %s: %s (allowed: %s)", client, cvarName, cvarValue, range);
			return;
		}

		LogMessage("Kicking %L for %s = %s (allowed: %s)", client, cvarName, cvarValue, range);
		CPrintToChatAll("%t", "Kicked Value", name, cvarName, cvarValue);
		KickClient(client, "%T", "Kick Reason Value", client, cvarName, cvarValue, range);
	}
}

void FormatRange(Tracked t, char[] buffer, int maxlength)
{
	if (t.hasMin && t.hasMax && t.min == t.max)
	{
		FormatEx(buffer, maxlength, "%g", t.min);
	}
	else if (t.hasMin && t.hasMax)
	{
		FormatEx(buffer, maxlength, "%g - %g", t.min, t.max);
	}
	else if (t.hasMin)
	{
		FormatEx(buffer, maxlength, ">= %g", t.min);
	}
	else
	{
		FormatEx(buffer, maxlength, "<= %g", t.max);
	}
}

Action Cmd_Track(int args)
{
	if (args < 3 || args == 4)
	{
		PrintToServer("Usage: lef_trackclientcvar <cvar> <hasMin> <min> [<hasMax> <max> [<action: 0 kick, 1 log>]]");
		return Plugin_Handled;
	}

	Tracked t;
	char buffer[CVAR_MAXLEN];

	GetCmdArg(1, t.cvar, sizeof(t.cvar));
	GetCmdArg(2, buffer, sizeof(buffer));
	t.hasMin = StringToInt(buffer) != 0;
	GetCmdArg(3, buffer, sizeof(buffer));
	t.min = StringToFloat(buffer);

	if (args >= 5)
	{
		GetCmdArg(4, buffer, sizeof(buffer));
		t.hasMax = StringToInt(buffer) != 0;
		GetCmdArg(5, buffer, sizeof(buffer));
		t.max = StringToFloat(buffer);
	}

	t.action = Action_Kick;
	if (args >= 6)
	{
		GetCmdArg(6, buffer, sizeof(buffer));
		t.action = StringToInt(buffer);
	}

	if (!t.hasMin && !t.hasMax)
	{
		LogError("lef_trackclientcvar %s: needs a min or a max", t.cvar);
		return Plugin_Handled;
	}
	if (t.hasMin && t.hasMax && t.max < t.min)
	{
		LogError("lef_trackclientcvar %s: max (%f) is below min (%f)", t.cvar, t.max, t.min);
		return Plugin_Handled;
	}

	// Re-adding a cvar replaces its old entry.
	Tracked existing;
	for (int i = 0; i < g_aTracked.Length; i++)
	{
		g_aTracked.GetArray(i, existing);
		if (StrEqual(existing.cvar, t.cvar, false))
		{
			g_aTracked.SetArray(i, t);
			return Plugin_Handled;
		}
	}

	g_aTracked.PushArray(t);
	return Plugin_Handled;
}

Action Cmd_Reset(int args)
{
	g_aTracked.Clear();
	return Plugin_Handled;
}

Action Cmd_List(int client, int args)
{
	ReplyToCommand(client, "[Client Cvars] %d checked:", g_aTracked.Length);

	Tracked t;
	char range[64];
	for (int i = 0; i < g_aTracked.Length; i++)
	{
		g_aTracked.GetArray(i, t);
		FormatRange(t, range, sizeof(range));
		ReplyToCommand(client, "  %s: %s%s", t.cvar, range, t.action == Action_Log ? " (log only)" : "");
	}

	return Plugin_Handled;
}
