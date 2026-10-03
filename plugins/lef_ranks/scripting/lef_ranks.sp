/**
 * Lefordianos Ranks
 *
 * A ranking for our versus games, used to make balanced teams. Each player has points (Elo, like in
 * chess, adapted to teams): everyone starts at lef_ranks_start (1000). When a map ends, the team with
 * more points on that map wins; its players gain and the losers lose. Beating a stronger team is
 * worth more than beating a weaker one, and new players move faster (bigger K) so they find their
 * level quickly.
 *
 * Only map results count (who won), not damage or kills: that's what balanced teams are about, and it
 * can't be farmed. A map only counts with at least lef_ranks_min_players humans per side (so bot games
 * don't), and players who were on both sides during a map don't count for it.
 *
 *   !rank [player]   points, maps played and position
 *   !top             the top 10 (players with at least lef_ranks_min_games maps)
 *
 * Stored with SourceMod's database: the "lef_ranks" entry of databases.cfg if it exists, else
 * "storage-local" (the SQLite file SourceMod already has). One small write per player per map.
 * lef_teams_panel's balanced shuffle asks this plugin for points (native LefRanks_GetRating).
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "1.0.0"

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Ranks",
	author      = "rats4final",
	description = "Team Elo ranking from versus map results, for balanced teams",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

enum struct Rank
{
	float rating;
	int   games;
	int   wins;
	int   losses;
	int   draws;
	bool  loaded;
}

ConVar
	g_cvStart,
	g_cvKNew,
	g_cvKSettled,
	g_cvSettledGames,
	g_cvMinPlayers,
	g_cvMinGames,
	g_cvAnnounce;

Database  g_hDb;
StringMap g_smRanks;          // SteamID64 -> Rank (players seen since the server started)
StringMap g_smMapTeam;        // SteamID64 -> campaign team (0/1) this map, or 2 = played both sides
StringMap g_smMapName;        // SteamID64 -> name, for the database
bool      g_bRoundFlipped;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	CreateNative("LefRanks_GetRating", Native_GetRating);
	RegPluginLibrary("lef_ranks");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("lef_ranks.phrases");

	CreateConVar("lef_ranks_version", PLUGIN_VERSION, "Lefordianos Ranks version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvStart        = CreateConVar("lef_ranks_start", "1000", "Points a new player starts with.", _, true, 0.0);
	g_cvKNew         = CreateConVar("lef_ranks_k_new", "40", "How much one map moves a new player's points (Elo K).", _, true, 1.0);
	g_cvKSettled     = CreateConVar("lef_ranks_k_settled", "20", "How much one map moves an established player's points.", _, true, 1.0);
	g_cvSettledGames = CreateConVar("lef_ranks_settled_games", "20", "Maps after which a player counts as established.", _, true, 0.0);
	g_cvMinPlayers   = CreateConVar("lef_ranks_min_players", "2", "Humans needed on each side for a map to count.", _, true, 1.0);
	g_cvMinGames     = CreateConVar("lef_ranks_min_games", "5", "Maps needed to appear in !top and to be used by the balanced shuffle.", _, true, 0.0);
	g_cvAnnounce     = CreateConVar("lef_ranks_announce", "1", "Tell each player their points change after a map.", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "lef_ranks");

	RegConsoleCmd("sm_rank", Cmd_Rank, "sm_rank [player] - points, maps played and position");
	RegConsoleCmd("sm_top", Cmd_Top, "The top 10 players");

	g_smRanks   = new StringMap();
	g_smMapTeam = new StringMap();
	g_smMapName = new StringMap();

	Database.Connect(OnConnected, SQL_CheckConfig("lef_ranks") ? "lef_ranks" : "storage-local");
}

void OnConnected(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("Couldn't connect to the database: %s", error);
		return;
	}
	g_hDb = db;
	g_hDb.Query(OnQueryDone, "CREATE TABLE IF NOT EXISTS lef_ranks (steamid VARCHAR(24) PRIMARY KEY, name VARCHAR(64), rating FLOAT, games INT, wins INT, losses INT, draws INT, last_seen INT)");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientAuthorized(i))
		{
			LoadPlayer(i);
		}
	}
}

void OnQueryDone(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("Database query failed: %s", error);
	}
}

public void OnMapStart()
{
	g_smMapTeam.Clear();
	g_smMapName.Clear();
}

// ---------------------------------------------------------------------------
// Loading players
// ---------------------------------------------------------------------------

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		LoadPlayer(client);
	}
}

void LoadPlayer(int client)
{
	char id[24];
	if (g_hDb == null || !GetClientAuthId(client, AuthId_SteamID64, id, sizeof(id)))
	{
		return;
	}
	Rank r;
	if (g_smRanks.GetArray(id, r, sizeof(r)) && r.loaded)
	{
		return;
	}

	char query[160];
	g_hDb.Format(query, sizeof(query), "SELECT rating, games, wins, losses, draws FROM lef_ranks WHERE steamid = '%s'", id);
	g_hDb.Query(OnPlayerLoaded, query, GetClientUserId(client));
}

void OnPlayerLoaded(Database db, DBResultSet results, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	char id[24];
	if (results == null || client == 0 || !GetClientAuthId(client, AuthId_SteamID64, id, sizeof(id)))
	{
		if (results == null)
		{
			LogError("Couldn't load a player's rank: %s", error);
		}
		return;
	}

	Rank r;
	r.rating = g_cvStart.FloatValue;
	if (results.FetchRow())
	{
		r.rating = results.FetchFloat(0);
		r.games  = results.FetchInt(1);
		r.wins   = results.FetchInt(2);
		r.losses = results.FetchInt(3);
		r.draws  = results.FetchInt(4);
	}
	r.loaded = true;
	g_smRanks.SetArray(id, r, sizeof(r));
}

bool GetRank(const char[] id, Rank r)
{
	if (g_smRanks.GetArray(id, r, sizeof(r)) && r.loaded)
	{
		return true;
	}
	r.rating = g_cvStart.FloatValue;
	r.games = r.wins = r.losses = r.draws = 0;
	r.loaded = false;
	return false;
}

// ---------------------------------------------------------------------------
// Map results
// ---------------------------------------------------------------------------

bool IsVersus()
{
	return L4D_GetGameModeType() == GAMEMODE_VERSUS;
}

// Pre-hook: who is on which campaign team, before the game flips the sides.
public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
	if (!IsVersus())
	{
		return Plugin_Continue;
	}
	g_bRoundFlipped = GameRules_GetProp("m_bAreTeamsFlipped") != 0;
	int survivorsTeam = g_bRoundFlipped ? 1 : 0;

	char id[24], name[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || !GetClientAuthId(i, AuthId_SteamID64, id, sizeof(id)))
		{
			continue;
		}
		int side = GetClientTeam(i);
		if (side != TEAM_SURVIVOR && side != TEAM_INFECTED && L4D_GetBotOfIdlePlayer(i) != 0)
		{
			side = TEAM_SURVIVOR;   // idle players keep their survivor spot
		}
		if (side != TEAM_SURVIVOR && side != TEAM_INFECTED)
		{
			continue;
		}

		int team = side == TEAM_SURVIVOR ? survivorsTeam : 1 - survivorsTeam;
		int seen;
		if (g_smMapTeam.GetValue(id, seen) && seen != team)
		{
			team = 2;   // played both sides this map: doesn't count
		}
		g_smMapTeam.SetValue(id, team);
		GetClientName(i, name, sizeof(name));
		g_smMapName.SetString(id, name);
	}
	return Plugin_Continue;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	if (!IsVersus() || GameRules_GetProp("m_bInSecondHalfOfRound") == 0)
	{
		return;   // the map isn't over until both halves are played
	}

	int scoreA = GameRules_GetProp("m_iChapterScore", _, 0);
	int scoreB = GameRules_GetProp("m_iChapterScore", _, 1);

	// Players per campaign team, and each team's average points.
	ArrayList members[2];
	members[0] = new ArrayList(ByteCountToCells(24));
	members[1] = new ArrayList(ByteCountToCells(24));
	float sum[2];

	StringMapSnapshot snap = g_smMapTeam.Snapshot();
	char id[24];
	Rank r;
	for (int i = 0; i < snap.Length; i++)
	{
		snap.GetKey(i, id, sizeof(id));
		int team;
		g_smMapTeam.GetValue(id, team);
		if (team == 0 || team == 1)
		{
			members[team].PushString(id);
			GetRank(id, r);
			sum[team] += r.rating;
		}
	}
	delete snap;

	int need = g_cvMinPlayers.IntValue;
	if (members[0].Length >= need && members[1].Length >= need)
	{
		float avg[2];
		avg[0] = sum[0] / float(members[0].Length);
		avg[1] = sum[1] / float(members[1].Length);
		float result0 = scoreA > scoreB ? 1.0 : (scoreA < scoreB ? 0.0 : 0.5);

		for (int t = 0; t < 2; t++)
		{
			float expected = 1.0 / (1.0 + Pow(10.0, (avg[1 - t] - avg[t]) / 400.0));
			float result   = t == 0 ? result0 : 1.0 - result0;
			for (int k = 0; k < members[t].Length; k++)
			{
				members[t].GetString(k, id, sizeof(id));
				UpdatePlayer(id, result, expected);
			}
		}
		LogMessage("Map ranked: %d vs %d (teams of %d and %d)", scoreA, scoreB, members[0].Length, members[1].Length);
	}

	delete members[0];
	delete members[1];
	g_smMapTeam.Clear();
}

void UpdatePlayer(const char[] id, float result, float expected)
{
	Rank r;
	GetRank(id, r);
	float k = r.games < g_cvSettledGames.IntValue ? g_cvKNew.FloatValue : g_cvKSettled.FloatValue;
	float change = k * (result - expected);

	r.rating += change;
	r.games++;
	if (result > 0.75)      r.wins++;
	else if (result < 0.25) r.losses++;
	else                    r.draws++;
	r.loaded = true;
	g_smRanks.SetArray(id, r, sizeof(r));

	char name[64], safeName[130];
	if (!g_smMapName.GetString(id, name, sizeof(name)))
	{
		strcopy(name, sizeof(name), id);
	}
	if (g_hDb != null)
	{
		g_hDb.Escape(name, safeName, sizeof(safeName));
		char query[512];
		g_hDb.Format(query, sizeof(query),
			"REPLACE INTO lef_ranks (steamid, name, rating, games, wins, losses, draws, last_seen) VALUES ('%s', '%s', %.2f, %d, %d, %d, %d, %d)",
			id, safeName, r.rating, r.games, r.wins, r.losses, r.draws, GetTime());
		g_hDb.Query(OnQueryDone, query);
	}

	if (g_cvAnnounce.BoolValue)
	{
		int client = FindClientBySteamId(id);
		if (client > 0)
		{
			int delta = RoundToNearest(change);
			CPrintToChat(client, "%T", delta >= 0 ? "Points Up" : "Points Down", client, delta >= 0 ? delta : -delta, RoundToNearest(r.rating));
		}
	}
}

int FindClientBySteamId(const char[] id)
{
	char other[24];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientAuthId(i, AuthId_SteamID64, other, sizeof(other)) && StrEqual(id, other))
		{
			return i;
		}
	}
	return 0;
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

Action Cmd_Rank(int client, int args)
{
	int target = client;
	if (args > 0)
	{
		char arg[64];
		GetCmdArg(1, arg, sizeof(arg));
		target = FindTarget(client, arg, true, false);
		if (target == -1)
		{
			return Plugin_Handled;
		}
	}
	if (target == 0)
	{
		ReplyToCommand(client, "[Ranks] Use it in game, or give a player name.");
		return Plugin_Handled;
	}

	char id[24];
	Rank r;
	if (!GetClientAuthId(target, AuthId_SteamID64, id, sizeof(id)) || !GetRank(id, r) || r.games == 0)
	{
		CReplyToCommand(client, "%T", "No Games", client == 0 ? LANG_SERVER : client, target);
		return Plugin_Handled;
	}
	if (g_hDb == null)
	{
		CReplyToCommand(client, "%T", "Rank Line", client == 0 ? LANG_SERVER : client, target, RoundToNearest(r.rating), r.games, r.wins, r.losses, 0);
		return Plugin_Handled;
	}

	// Position among players with enough maps.
	DataPack pack = new DataPack();
	pack.WriteCell(client == 0 ? 0 : GetClientUserId(client));
	pack.WriteCell(GetClientUserId(target));
	char query[200];
	g_hDb.Format(query, sizeof(query), "SELECT COUNT(*) FROM lef_ranks WHERE games >= %d AND rating > %.2f", g_cvMinGames.IntValue, r.rating);
	g_hDb.Query(OnRankPosition, query, pack);
	return Plugin_Handled;
}

void OnRankPosition(Database db, DBResultSet results, const char[] error, DataPack pack)
{
	pack.Reset();
	int userid = pack.ReadCell();
	int client = userid == 0 ? 0 : GetClientOfUserId(userid);
	int target = GetClientOfUserId(pack.ReadCell());
	delete pack;
	if ((userid != 0 && client == 0) || target == 0)
	{
		return;
	}

	char id[24];
	Rank r;
	GetClientAuthId(target, AuthId_SteamID64, id, sizeof(id));
	GetRank(id, r);
	int position = (results != null && results.FetchRow()) ? results.FetchInt(0) + 1 : 0;
	if (r.games < g_cvMinGames.IntValue)
	{
		position = 0;   // not on the board yet
	}
	CPrintToChatOrServer(client, "%T", "Rank Line", client == 0 ? LANG_SERVER : client, target, RoundToNearest(r.rating), r.games, r.wins, r.losses, position);
}

Action Cmd_Top(int client, int args)
{
	if (g_hDb == null)
	{
		ReplyToCommand(client, "[Ranks] Database not ready.");
		return Plugin_Handled;
	}
	char query[200];
	g_hDb.Format(query, sizeof(query), "SELECT name, rating, games, wins FROM lef_ranks WHERE games >= %d ORDER BY rating DESC LIMIT 10", g_cvMinGames.IntValue);
	g_hDb.Query(OnTop, query, client == 0 ? 0 : GetClientUserId(client));
	return Plugin_Handled;
}

void OnTop(Database db, DBResultSet results, const char[] error, int userid)
{
	int client = userid == 0 ? 0 : GetClientOfUserId(userid);
	if (userid != 0 && client == 0)
	{
		return;
	}
	if (results == null)
	{
		LogError("!top query failed: %s", error);
		return;
	}

	int lang = client == 0 ? LANG_SERVER : client;
	CPrintToChatOrServer(client, "%T", "Top Title", lang, g_cvMinGames.IntValue);
	char name[64];
	int position;
	while (results.FetchRow())
	{
		results.FetchString(0, name, sizeof(name));
		CPrintToChatOrServer(client, "%T", "Top Line", lang, ++position, name, RoundToNearest(results.FetchFloat(1)), results.FetchInt(2), results.FetchInt(3));
	}
	if (position == 0)
	{
		CPrintToChatOrServer(client, "%T", "Top Empty", lang, g_cvMinGames.IntValue);
	}
}

void CPrintToChatOrServer(int client, const char[] format, any ...)
{
	char buffer[256];
	VFormat(buffer, sizeof(buffer), format, 3);
	if (client == 0)
	{
		CRemoveTags(buffer, sizeof(buffer));
		PrintToServer("%s", buffer);
	}
	else
	{
		CPrintToChat(client, "%s", buffer);
	}
}

// ---------------------------------------------------------------------------
// Native for lef_teams_panel: int LefRanks_GetRating(int client, int &games)
// ---------------------------------------------------------------------------

any Native_GetRating(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char id[24];
	Rank r;
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client)
		|| !GetClientAuthId(client, AuthId_SteamID64, id, sizeof(id)) || !GetRank(id, r))
	{
		SetNativeCellRef(2, 0);
		return RoundToNearest(g_cvStart.FloatValue);
	}
	SetNativeCellRef(2, r.games);
	return RoundToNearest(r.rating);
}
