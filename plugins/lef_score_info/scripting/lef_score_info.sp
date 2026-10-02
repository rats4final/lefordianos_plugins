/**
 * Lefordianos Score Info
 *
 * Vanilla versus scoring, explained to the players. Changes no points.
 *
 *  - When survivors leave the saferoom: what this map is worth and how big the gap is
 *    compared with it ("Gap: 300, that's 60% of this map").
 *  - After the first half: what the second team needs to win this map and to take the lead.
 *  - After the map: who won the map, the map wins count ("Maps: 2 - 1") and the totals.
 *  - !score: all of the above, any time.
 *
 * Messages say "your team" / "the other team" per player, since "Team A/B" means
 * nothing in game. Spectators see "the survivors" / "the infected".
 *
 * Inspired by MoYu's l4d2_score_difference (Forgetest, vikingo12). Unlike it, this
 * doesn't need Info Editor: instead of predicting the next map's value, it announces
 * each map's value when that map starts.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "1.0.0"

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR  2
#define TEAM_INFECTED  3

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Score Info",
	author      = "rats4final; idea from l4d2_score_difference by Forgetest, vikingo12",
	description = "Explains versus scores: map value, gap, what's needed to come back, map wins",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar g_cvDelay;

// Maps won this campaign, by campaign team (0 = A, 1 = B; independent of side).
int  g_iMapWins[2];
int  g_iMapDraws;
bool g_bFlippedAtEnd;

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
	LoadTranslations("lef_score_info.phrases");

	CreateConVar("lef_score_info_version", PLUGIN_VERSION, "Lefordianos Score Info version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvDelay = CreateConVar("lef_score_info_delay", "5.0", "Seconds after a half ends before printing the scores (lets the scoreboard settle).", _, true, 0.0, true, 20.0);
	AutoExecConfig(true, "lef_score_info");

	RegConsoleCmd("sm_score", Cmd_Score, "Show scores, the gap, map wins and what this map is worth");
	RegConsoleCmd("sm_scores", Cmd_Score, "Show scores, the gap, map wins and what this map is worth");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

// ---------------------------------------------------------------------------
// Keeping the map wins count
// ---------------------------------------------------------------------------

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// A new campaign: first half of a first map with nobody having scored.
	if (IsVersus() && !InSecondHalf() && GetCampaignScore(0) == 0 && GetCampaignScore(1) == 0)
	{
		g_iMapWins[0] = g_iMapWins[1] = 0;
		g_iMapDraws = 0;
	}
}

// Pre-hook: remember which side each campaign team is on before the game flips them.
public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
	g_bFlippedAtEnd = AreTeamsFlipped();
	return Plugin_Continue;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	if (!IsVersus())
	{
		return;
	}

	bool secondHalf = InSecondHalf();

	if (secondHalf)
	{
		int a = GetChapterScore(0);
		int b = GetChapterScore(1);

		if (a > b)
		{
			g_iMapWins[0]++;
		}
		else if (b > a)
		{
			g_iMapWins[1]++;
		}
		else
		{
			g_iMapDraws++;
		}
	}

	CreateTimer(g_cvDelay.FloatValue, secondHalf ? Timer_MapSummary : Timer_HalftimeSummary, _, TIMER_FLAG_NO_MAPCHANGE);
}

// ---------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------

// After the first half: the team that just played survivors has set a target.
Action Timer_HalftimeSummary(Handle timer)
{
	int setter = SurvivorIndex(g_bFlippedAtEnd); // campaign team that just played survivors
	int chaser = 1 - setter;

	int target    = GetChapterScore(setter);
	int mapValue  = L4D_GetVersusMaxCompletionScore();
	int toLead    = GetCampaignScore(setter) - GetCampaignScore(chaser);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}

		int mine = ClientCampaignTeam(i, g_bFlippedAtEnd);
		char setterName[64], chaserName[64];
		TeamLabel(i, mine, setter, g_bFlippedAtEnd, setterName, sizeof(setterName));
		TeamLabel(i, mine, chaser, g_bFlippedAtEnd, chaserName, sizeof(chaserName));

		CPrintToChat(i, "%T", "Halftime Target", i, setterName, target, mapValue);

		if (target < mapValue)
		{
			CPrintToChat(i, "%T", "Halftime To Win Map", i, chaserName, target + 1, Percent(target + 1, mapValue));
		}

		if (toLead >= 0)
		{
			// Points needed on this map to pass the leader overall.
			int need = toLead + 1;
			if (need <= mapValue)
			{
				CPrintToChat(i, "%T", "Halftime To Lead", i, chaserName, need, Percent(need, mapValue));
			}
			else
			{
				CPrintToChat(i, "%T", "Halftime Lead Out Of Reach", i, chaserName, need, mapValue);
			}
		}
	}

	return Plugin_Stop;
}

// After the second half: who won the map, maps count, totals.
Action Timer_MapSummary(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			PrintMapResult(i, g_bFlippedAtEnd);
			PrintStandings(i, g_bFlippedAtEnd);
		}
	}

	return Plugin_Stop;
}

void PrintMapResult(int client, bool flipped)
{
	int mine = ClientCampaignTeam(client, flipped);
	int a = GetChapterScore(0);
	int b = GetChapterScore(1);

	if (a == b)
	{
		CPrintToChat(client, "%T", "Map Draw", client, a);
		return;
	}

	int winner = (a > b) ? 0 : 1;
	char winnerName[64];
	TeamLabel(client, mine, winner, flipped, winnerName, sizeof(winnerName));
	CPrintToChat(client, "%T", "Map Won", client, winnerName, GetChapterScore(winner), GetChapterScore(1 - winner));
}

void PrintStandings(int client, bool flipped)
{
	int mine = ClientCampaignTeam(client, flipped);

	// Survivors' team first for spectators; "your team" first for players.
	int first  = (mine == -1) ? SurvivorIndex(flipped) : mine;
	int second = 1 - first;

	char firstName[64], secondName[64];
	TeamLabel(client, mine, first, flipped, firstName, sizeof(firstName));
	TeamLabel(client, mine, second, flipped, secondName, sizeof(secondName));

	CPrintToChat(client, "%T", "Standings", client,
		firstName, GetCampaignScore(first), g_iMapWins[first],
		secondName, GetCampaignScore(second), g_iMapWins[second]);
}

// When survivors leave the saferoom: what this map is worth and how the gap compares.
public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	if (IsVersus())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				PrintMapValue(i);
			}
		}
	}
}

void PrintMapValue(int client)
{
	int mapValue = L4D_GetVersusMaxCompletionScore();
	int gap      = GetCampaignScore(0) - GetCampaignScore(1);
	if (gap < 0)
	{
		gap = -gap;
	}

	if (gap == 0)
	{
		CPrintToChat(client, "%T", "Map Value Even", client, mapValue);
	}
	else
	{
		CPrintToChat(client, "%T", "Map Value Gap", client, mapValue, gap, Percent(gap, mapValue));
	}
}

Action Cmd_Score(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("[Score] A: %d (maps %d) | B: %d (maps %d) | draws %d | map value %d",
			GetCampaignScore(0), g_iMapWins[0], GetCampaignScore(1), g_iMapWins[1], g_iMapDraws, L4D_GetVersusMaxCompletionScore());
		return Plugin_Handled;
	}

	if (!IsVersus())
	{
		CPrintToChat(client, "%T", "Not Versus", client);
		return Plugin_Handled;
	}

	bool flipped = AreTeamsFlipped();
	PrintStandings(client, flipped);
	PrintMapValue(client);
	return Plugin_Handled;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Campaign team (0/1) playing survivors, given the flip state.
int SurvivorIndex(bool flipped)
{
	return flipped ? 1 : 0;
}

// Campaign team of a player, or -1 for spectators.
int ClientCampaignTeam(int client, bool flipped)
{
	switch (GetClientTeam(client))
	{
		case TEAM_SURVIVOR: return SurvivorIndex(flipped);
		case TEAM_INFECTED: return 1 - SurvivorIndex(flipped);
	}
	return -1;
}

// "Your team" / "The other team" for players; "The survivors" / "The infected" for spectators.
void TeamLabel(int client, int mine, int team, bool flipped, char[] buffer, int maxlength)
{
	if (mine == -1)
	{
		FormatEx(buffer, maxlength, "%T", team == SurvivorIndex(flipped) ? "Label Survivors" : "Label Infected", client);
	}
	else
	{
		FormatEx(buffer, maxlength, "%T", team == mine ? "Label Yours" : "Label Theirs", client);
	}
}

int Percent(int part, int whole)
{
	return whole > 0 ? RoundToCeil(float(part) * 100.0 / float(whole)) : 0;
}

int GetChapterScore(int team)
{
	return GameRules_GetProp("m_iChapterScore", _, team);
}

int GetCampaignScore(int team)
{
	return GameRules_GetProp("m_iCampaignScore", _, team);
}

bool AreTeamsFlipped()
{
	return GameRules_GetProp("m_bAreTeamsFlipped") != 0;
}

bool InSecondHalf()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound") != 0;
}

bool IsVersus()
{
	return L4D_GetGameModeType() == GAMEMODE_VERSUS;
}
