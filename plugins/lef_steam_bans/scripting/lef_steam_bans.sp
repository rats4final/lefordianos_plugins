/**
 * Lefordianos Steam Bans
 *
 * When a player joins, asks Steam whether their account has VAC bans, game bans (bans from a
 * game's own anti-cheat) or a Steam Community ban, and tells the admins (or everyone). It only
 * looks at bans: no hours, no profile, no friends, nothing else about the player.
 *
 * Needs the REST in Pawn extension (ripext) and a Steam Web API key
 * (https://steamcommunity.com/dev/apikey) in lef_bans_apikey. Keep the key private: put it in
 * cfg/sourcemod/lef_steam_bans.cfg on the server, never in a shared or public config.
 *
 * Each account is checked once per server start (map changes don't ask again).
 * Everything found is also written to logs/lef_steam_bans.log.
 * Inspired by StevoTVR's VAC Status Checker (also forked by Harry Potter as vacbans), which uses the
 * Socket extension instead.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>
#include <ripext>

#define PLUGIN_VERSION "1.0.0"
#define API_URL        "https://api.steampowered.com/ISteamUser/GetPlayerBans/v1/"

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Steam Bans",
	author      = "rats4final; idea from StevoTVR's VAC Status Checker",
	description = "Tells admins when a joining player has VAC, game or community bans",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar
	g_cvApiKey,
	g_cvAnnounce,
	g_cvGameBans,
	g_cvCommunity,
	g_cvKickVacDays;

StringMap g_smChecked;   // SteamID64 -> true, so each account is asked about once
char      g_sLogFile[PLATFORM_MAX_PATH];
bool      g_bWarnedNoKey;

public void OnPluginStart()
{
	LoadTranslations("lef_steam_bans.phrases");

	CreateConVar("lef_steam_bans_version", PLUGIN_VERSION, "Lefordianos Steam Bans version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvApiKey      = CreateConVar("lef_bans_apikey", "", "Steam Web API key (https://steamcommunity.com/dev/apikey). Keep it private.", FCVAR_PROTECTED);
	g_cvAnnounce    = CreateConVar("lef_bans_announce", "0", "Who is told about a player's bans: 0 = admins only, 1 = everyone.", _, true, 0.0, true, 1.0);
	g_cvGameBans    = CreateConVar("lef_bans_game_bans", "1", "Also report game bans (bans by a game's own anti-cheat).", _, true, 0.0, true, 1.0);
	g_cvCommunity   = CreateConVar("lef_bans_community", "0", "Also report Steam Community bans.", _, true, 0.0, true, 1.0);
	g_cvKickVacDays = CreateConVar("lef_bans_kick_vac_days", "0", "Kick players whose last VAC ban is newer than this many days. 0 = never kick, only report.", _, true, 0.0);
	AutoExecConfig(true, "lef_steam_bans");

	RegAdminCmd("sm_checkbans", Cmd_CheckBans, ADMFLAG_GENERIC, "sm_checkbans <player> - ask Steam about a player's bans again");

	g_smChecked = new StringMap();
	BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/lef_steam_bans.log");
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}

	char id64[24];
	if (!GetClientAuthId(client, AuthId_SteamID64, id64, sizeof(id64)) || g_smChecked.ContainsKey(id64))
	{
		return;
	}
	g_smChecked.SetValue(id64, true);
	Query(client, 0);
}

Action Cmd_CheckBans(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_checkbans <player>");
		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	int target = FindTarget(client, arg, true, false);
	if (target != -1)
	{
		Query(target, client == 0 ? 0 : GetClientUserId(client));
	}
	return Plugin_Handled;
}

// asker = userid of the admin who asked with sm_checkbans (also told when there's nothing), or 0.
void Query(int client, int asker)
{
	char key[64], id64[24];
	g_cvApiKey.GetString(key, sizeof(key));
	if (key[0] == '\0')
	{
		if (!g_bWarnedNoKey)
		{
			g_bWarnedNoKey = true;
			LogError("lef_bans_apikey is empty: can't ask Steam about bans. Get a key at https://steamcommunity.com/dev/apikey");
		}
		return;
	}
	if (!GetClientAuthId(client, AuthId_SteamID64, id64, sizeof(id64)))
	{
		return;
	}

	HTTPRequest request = new HTTPRequest(API_URL);
	request.AppendQueryParam("key", "%s", key);
	request.AppendQueryParam("steamids", "%s", id64);
	request.Timeout = 15;

	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(asker);
	request.Get(OnBansResponse, pack);
}

void OnBansResponse(HTTPResponse response, DataPack pack, const char[] error)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int asker  = GetClientOfUserId(pack.ReadCell());
	delete pack;

	if (response.Status != HTTPStatus_OK || response.Data == null)
	{
		LogError("Steam ban check failed (HTTP %d): %s", response.Status, error);
		return;
	}
	if (client == 0)
	{
		return;   // left before Steam answered
	}

	JSONObject root    = view_as<JSONObject>(response.Data);
	JSONArray  players = view_as<JSONArray>(root.Get("players"));
	if (players == null || players.Length == 0)
	{
		delete players;
		return;
	}
	JSONObject info = view_as<JSONObject>(players.Get(0));

	int  vacBans   = info.GetInt("NumberOfVACBans");
	int  gameBans  = g_cvGameBans.BoolValue ? info.GetInt("NumberOfGameBans") : 0;
	bool community = g_cvCommunity.BoolValue && info.GetBool("CommunityBanned");
	int  days      = info.GetInt("DaysSinceLastBan");
	delete info;
	delete players;

	if (vacBans == 0 && gameBans == 0 && !community)
	{
		if (asker > 0)
		{
			CPrintToChat(asker, "%T", "No Bans", asker, client);
		}
		return;
	}

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	LogToFileEx(g_sLogFile, "%L: %d VAC ban(s), %d game ban(s), community ban: %s, last ban %d day(s) ago",
		client, vacBans, gameBans, community ? "yes" : "no", days);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		if (i != asker && !g_cvAnnounce.BoolValue && !CheckCommandAccess(i, "lef_bans_notify", ADMFLAG_GENERIC, true))
		{
			continue;
		}
		CPrintToChat(i, "%T", "Has Bans", i, name, vacBans, gameBans, days);
		if (community)
		{
			CPrintToChat(i, "%T", "Community Banned", i, name);
		}
	}

	int kickDays = g_cvKickVacDays.IntValue;
	if (kickDays > 0 && vacBans > 0 && days < kickDays)
	{
		LogToFileEx(g_sLogFile, "Kicked %L: VAC ban %d day(s) ago (limit %d)", client, days, kickDays);
		KickClient(client, "%T", "Kick Reason", client, kickDays);
	}
}
