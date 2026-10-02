/**
 * Lefordianos Karma Sounds
 *
 * Plays one of our own sounds, picked at random, when a karma kill is announced (a survivor
 * charged, punched or pulled off a ledge to their death). Works with either karma kill plugin:
 * eyal282's l4d2-karma-kill-system or Harry Potter's l4d2_karma_kill; both send
 * KarmaKillSystem_OnKarmaEventPost.
 *
 * The sound list is configs/lef_karma_sounds.txt: one path per line, relative to sound/,
 * e.g. "lefordianos/karma/fall1.wav". Every listed file that exists on the server is added to
 * the downloads table (players get it via FastDL, see docs/FASTDL.md) and precached.
 * With an empty list the plugin does nothing.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"
#define LIST_FILE      "configs/lef_karma_sounds.txt"

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Karma Sounds",
	author      = "rats4final",
	description = "Plays our own random sound on karma kills",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar
	g_cvEnable,
	g_cvVolume,
	g_cvCooldown;

ArrayList g_aSounds;          // sounds that exist on this server
float     g_fNextSound;
float     g_fVictimPlayed[MAXPLAYERS + 1];

public void OnPluginStart()
{
	CreateConVar("lef_karma_sounds_version", PLUGIN_VERSION, "Lefordianos Karma Sounds version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvEnable   = CreateConVar("lef_karma_sounds_enable", "1", "Play our own sound on karma kills.", _, true, 0.0, true, 1.0);
	g_cvVolume   = CreateConVar("lef_karma_sounds_volume", "1.0", "Volume of the karma sound.", _, true, 0.0, true, 1.0);
	g_cvCooldown = CreateConVar("lef_karma_sounds_cooldown", "5.0", "Minimum seconds between two karma sounds.", _, true, 0.0);
	AutoExecConfig(true, "lef_karma_sounds");

	RegAdminCmd("sm_karmasounds_reload", Cmd_Reload, ADMFLAG_CONFIG, "Reload configs/lef_karma_sounds.txt (applies fully on the next map)");
	RegAdminCmd("sm_karmasounds_test", Cmd_Test, ADMFLAG_CONFIG, "Play a random karma sound to everyone");

	g_aSounds = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
}

public void OnMapStart()
{
	LoadSounds();

	g_fNextSound = 0.0;
	for (int i = 0; i <= MaxClients; i++)
	{
		g_fVictimPlayed[i] = 0.0;
	}
}

// Reads the list and registers each existing file for download and playback.
void LoadSounds()
{
	g_aSounds.Clear();

	char listPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, listPath, sizeof(listPath), LIST_FILE);

	File file = OpenFile(listPath, "r");
	if (file == null)
	{
		return;
	}

	char line[PLATFORM_MAX_PATH], full[PLATFORM_MAX_PATH];
	while (file.ReadLine(line, sizeof(line)))
	{
		TrimString(line);
		if (line[0] == '\0' || (line[0] == '/' && line[1] == '/'))
		{
			continue;
		}

		FormatEx(full, sizeof(full), "sound/%s", line);
		if (!FileExists(full, true))
		{
			LogError("%s: \"%s\" not found on the server, skipped", LIST_FILE, full);
			continue;
		}

		AddFileToDownloadsTable(full);
		PrecacheSound(line, true);
		g_aSounds.PushString(line);
	}

	delete file;
}

// Sent by the karma kill plugin, several times per event (unconfirmed, then confirmed).
public void KarmaKillSystem_OnKarmaEventPost(int victim, int attacker, const char[] KarmaName, bool bBird, bool bKillConfirmed, bool bOnlyConfirmed)
{
	if (!g_cvEnable.BoolValue || g_aSounds.Length == 0)
	{
		return;
	}

	// The karma plugin announces when the kill is confirmed, or right away if it doesn't wait.
	if (bOnlyConfirmed && !bKillConfirmed)
	{
		return;
	}

	float now = GetGameTime();

	// One sound per victim per karma event, and not too often overall.
	if (victim > 0 && victim <= MaxClients)
	{
		if (now - g_fVictimPlayed[victim] < 10.0)
		{
			return;
		}
		g_fVictimPlayed[victim] = now;
	}

	if (now < g_fNextSound)
	{
		return;
	}
	g_fNextSound = now + g_cvCooldown.FloatValue;

	PlayRandom();
}

void PlayRandom()
{
	char sound[PLATFORM_MAX_PATH];
	g_aSounds.GetString(GetRandomInt(0, g_aSounds.Length - 1), sound, sizeof(sound));
	EmitSoundToAll(sound, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, g_cvVolume.FloatValue);
}

Action Cmd_Reload(int client, int args)
{
	LoadSounds();
	ReplyToCommand(client, "[Karma Sounds] %d sound(s) loaded. New files download for players from the next map.", g_aSounds.Length);
	return Plugin_Handled;
}

Action Cmd_Test(int client, int args)
{
	if (g_aSounds.Length == 0)
	{
		ReplyToCommand(client, "[Karma Sounds] No sounds loaded (check %s).", LIST_FILE);
		return Plugin_Handled;
	}

	PlayRandom();
	return Plugin_Handled;
}
