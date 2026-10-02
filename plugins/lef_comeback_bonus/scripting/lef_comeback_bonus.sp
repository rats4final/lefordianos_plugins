/**
 * Lefordianos Comeback Bonus
 *
 * Gives the team that's behind a fair chance to come back in vanilla versus.
 *
 * At the start of each map we look at the campaign scores. If one team is behind by at
 * least lef_comeback_min_gap points, then during the half that team plays survivors it
 * earns an extra lef_comeback_percent % of the distance points it covers — never more
 * than the gap itself, so it can catch up but never jump ahead on the bonus alone.
 *
 * The bonus multiplies what the team actually earns: a trailing team that gets wiped
 * early still gets very little. It's announced when survivors leave the saferoom and
 * shown when the half ends.
 *
 * Points are added through l4d2_penalty_bonus (competitive repo), which turns the game's
 * defib penalty into a bonus: it shows on the normal scoreboard and counts even when the
 * team is wiped.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>
#include <l4d2_penalty_bonus>

#define PLUGIN_VERSION "1.0.0"

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Comeback Bonus",
	author      = "rats4final",
	description = "The trailing team earns a capped bonus on the distance it covers",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar
	g_cvEnable,
	g_cvPercent,
	g_cvMinGap,
	g_cvCapToGap,
	g_cvSurvivorLimit;

// This map's situation, decided when the first half starts.
bool g_bDecided;
int  g_iTrailing = -1; // campaign team (0/1) that's behind, or -1
int  g_iGap;

// Last bonus given, for the end-of-half message.
int  g_iLastBonus;
int  g_iLastBonusTeam = -1;
bool g_bLastFlipped;

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
	LoadTranslations("lef_comeback_bonus.phrases");

	CreateConVar("lef_comeback_bonus_version", PLUGIN_VERSION, "Lefordianos Comeback Bonus version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvEnable   = CreateConVar("lef_comeback_enable", "1", "Give the trailing team a comeback bonus.", _, true, 0.0, true, 1.0);
	g_cvPercent  = CreateConVar("lef_comeback_percent", "15", "Bonus as a percent of the distance points the trailing team covers.", _, true, 0.0, true, 100.0);
	g_cvMinGap   = CreateConVar("lef_comeback_min_gap", "100", "Only kick in when a team is behind by at least this many points at the start of the map.", _, true, 0.0);
	g_cvCapToGap = CreateConVar("lef_comeback_cap_to_gap", "1", "Never give more bonus than the gap, so the bonus alone can't put the trailing team ahead.", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "lef_comeback_bonus");

	g_cvSurvivorLimit = FindConVar("survivor_limit");

	RegConsoleCmd("sm_comeback", Cmd_Comeback, "Show whether a comeback bonus is active on this map");
}

public void OnMapStart()
{
	g_bDecided       = false;
	g_iTrailing      = -1;
	g_iGap           = 0;
	g_iLastBonusTeam = -1;
}

// ---------------------------------------------------------------------------
// Deciding who's behind (once per map) and announcing it
// ---------------------------------------------------------------------------

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	if (!IsVersus())
	{
		return;
	}

	DecideIfNeeded();

	if (IsActive())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				PrintStatus(i);
			}
		}
	}
}

void DecideIfNeeded()
{
	if (g_bDecided)
	{
		return;
	}

	// Scores only change between halves, so the second half sees the same numbers as the
	// first plus the first half's points. Decide on the scores from before this map.
	g_bDecided = true;

	int a = GetCampaignScore(0);
	int b = GetCampaignScore(1);

	if (InSecondHalf())
	{
		// Plugin loaded mid-map: take out the points already scored on this map.
		a -= GetChapterScore(0);
		b -= GetChapterScore(1);
	}

	g_iGap      = (a > b) ? a - b : b - a;
	g_iTrailing = (a == b) ? -1 : ((a < b) ? 0 : 1);
}

bool IsActive()
{
	return g_cvEnable.BoolValue && g_iTrailing != -1 && g_iGap >= g_cvMinGap.IntValue && g_cvPercent.FloatValue > 0.0;
}

Action Cmd_Comeback(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("[Comeback] active %d, trailing team %d, gap %d", IsActive(), g_iTrailing, g_iGap);
		return Plugin_Handled;
	}

	if (!IsVersus())
	{
		return Plugin_Handled;
	}

	DecideIfNeeded();

	if (IsActive())
	{
		PrintStatus(client);
	}
	else
	{
		CPrintToChat(client, "%T", "Not Active", client, g_cvMinGap.IntValue);
	}

	return Plugin_Handled;
}

void PrintStatus(int client)
{
	char label[64];
	TeamLabel(client, g_iTrailing, AreTeamsFlipped(), label, sizeof(label));
	CPrintToChat(client, "%T", "Active", client, label, g_cvPercent.IntValue, g_iGap);
}

// ---------------------------------------------------------------------------
// Paying the bonus
// ---------------------------------------------------------------------------

// Called by l4d2_penalty_bonus right before the half is scored.
public int PBONUS_RequestFinalUpdate(int &update)
{
	g_iLastBonus     = 0;
	g_iLastBonusTeam = -1;
	g_bLastFlipped   = AreTeamsFlipped();

	if (!IsVersus())
	{
		return update;
	}

	DecideIfNeeded();

	int survivorsTeam = g_bLastFlipped ? 1 : 0;
	if (!IsActive() || survivorsTeam != g_iTrailing)
	{
		return update;
	}

	int bonus = RoundToFloor(EstimateDistancePoints() * g_cvPercent.FloatValue / 100.0);
	if (g_cvCapToGap.BoolValue && bonus > g_iGap)
	{
		bonus = g_iGap;
	}

	if (bonus > 0)
	{
		g_iLastBonus     = bonus;
		g_iLastBonusTeam = survivorsTeam;
		update += bonus;
	}

	return update;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	if (g_iLastBonus > 0)
	{
		CreateTimer(5.5, Timer_AnnounceBonus, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_AnnounceBonus(Handle timer)
{
	char label[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			TeamLabel(i, g_iLastBonusTeam, g_bLastFlipped, label, sizeof(label));
			CPrintToChat(i, "%T", "Paid", i, g_iLastBonus, label);
		}
	}
	return Plugin_Stop;
}

/**
 * The distance points the survivors earned this half, estimated from the game's own
 * per-survivor progress (the same value it scores with): the map's value times the
 * team's average progress. Missing survivors count as 0.
 */
int EstimateDistancePoints()
{
	int total, counted;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			total += L4D2_GetVersusCompletionPlayer(i);
			counted++;
		}
	}

	int slots = g_cvSurvivorLimit.IntValue;
	if (counted > slots)
	{
		slots = counted;
	}
	if (slots <= 0)
	{
		return 0;
	}

	return RoundToFloor(float(L4D_GetVersusMaxCompletionScore()) * float(total) / (100.0 * float(slots)));
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// "Your team" / "The other team" for players; "The survivors" / "The infected" for spectators.
void TeamLabel(int client, int team, bool flipped, char[] buffer, int maxlength)
{
	int survivorsTeam = flipped ? 1 : 0;
	int clientTeam    = GetClientTeam(client);

	if (clientTeam != TEAM_SURVIVOR && clientTeam != TEAM_INFECTED)
	{
		FormatEx(buffer, maxlength, "%T", team == survivorsTeam ? "Label Survivors" : "Label Infected", client);
		return;
	}

	int mine = (clientTeam == TEAM_SURVIVOR) ? survivorsTeam : 1 - survivorsTeam;
	FormatEx(buffer, maxlength, "%T", team == mine ? "Label Yours" : "Label Theirs", client);
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
