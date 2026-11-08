/**
 * Lefordianos Mode Plugins
 *
 * Turns plugins off while a game mode is on and back on when the server leaves it, from
 * configs/lef_mode_plugins.cfg. Made for mutation19 (Taaannnk!!, run by lef_tanktime), where the
 * versus plugins that pick the tank, the infected class or the boss spawns would fight with it.
 *
 * Checked when mp_gamemode changes and after every map's configs. Plugins are unloaded in reverse
 * list order and loaded back in list order, so list the ones others depend on first.
 *   sm_modeplugins     what is off for the current mode
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"
#define CONFIG "configs/lef_mode_plugins.cfg"

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Mode Plugins",
	author      = "rats4final",
	description = "Turns plugins off while a game mode is on",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

StringMap g_smModes;    // mode -> ArrayList of plugin files
ArrayList g_aAll;       // every listed file, in list order
StringMap g_smOffByUs;  // files we unloaded

public void OnPluginStart()
{
	CreateConVar("lef_mode_plugins_version", PLUGIN_VERSION, "Lefordianos Mode Plugins version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	RegAdminCmd("sm_modeplugins", Cmd_Status, ADMFLAG_GENERIC, "Which plugins are off for the current game mode");

	g_smModes = new StringMap();
	g_aAll = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	g_smOffByUs = new StringMap();
	LoadConfig();

	FindConVar("mp_gamemode").AddChangeHook(OnGameModeChanged);
}

public void OnPluginEnd()
{
	// Don't leave plugins off behind us.
	char file[PLATFORM_MAX_PATH];
	for (int i = 0; i < g_aAll.Length; i++)
	{
		g_aAll.GetString(i, file, sizeof(file));
		bool dummy;
		if (g_smOffByUs.GetValue(file, dummy))
		{
			ServerCommand("sm plugins load %s", file);
		}
	}
}

void LoadConfig()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), CONFIG);
	KeyValues kv = new KeyValues("ModePlugins");
	if (!kv.ImportFromFile(path))
	{
		LogError("%s not found: no plugin is turned off by game mode", CONFIG);
		delete kv;
		return;
	}
	char mode[64], key[16], file[PLATFORM_MAX_PATH];
	if (kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetSectionName(mode, sizeof(mode));
			ArrayList list = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetSectionName(key, sizeof(key));
					kv.GetString(NULL_STRING, file, sizeof(file));
					if (StrEqual(key, "off", false) && file[0] != '\0')
					{
						list.PushString(file);
						if (g_aAll.FindString(file) == -1)
						{
							g_aAll.PushString(file);
						}
					}
				}
				while (kv.GotoNextKey(false));
				kv.GoBack();
			}
			StringToLower(mode);
			g_smModes.SetValue(mode, list);
		}
		while (kv.GotoNextKey());
	}
	delete kv;
}

void StringToLower(char[] text)
{
	for (int i = 0; text[i] != '\0'; i++)
	{
		text[i] = CharToLower(text[i]);
	}
}

void OnGameModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Apply();
}

public void OnConfigsExecuted()
{
	Apply();
}

void Apply()
{
	char mode[64], file[PLATFORM_MAX_PATH];
	FindConVar("mp_gamemode").GetString(mode, sizeof(mode));
	StringToLower(mode);
	ArrayList want;
	g_smModes.GetValue(mode, want);

	// Back on: what we turned off that this mode doesn't want off (in list order).
	bool dummy;
	for (int i = 0; i < g_aAll.Length; i++)
	{
		g_aAll.GetString(i, file, sizeof(file));
		if (g_smOffByUs.GetValue(file, dummy) && (want == null || want.FindString(file) == -1))
		{
			g_smOffByUs.Remove(file);
			ServerCommand("sm plugins load %s", file);
			LogMessage("Game mode %s: turning %s back on", mode, file);
		}
	}

	if (want == null)
	{
		return;
	}
	// Off (in reverse list order: plugins that depend on others go first).
	for (int i = want.Length - 1; i >= 0; i--)
	{
		want.GetString(i, file, sizeof(file));
		char loaded[PLATFORM_MAX_PATH];
		if (FindLoaded(file, loaded, sizeof(loaded)))
		{
			g_smOffByUs.SetValue(file, true);
			ServerCommand("sm plugins unload \"%s\"", loaded);
			LogMessage("Game mode %s: turning %s off", mode, file);
		}
	}
}

// The loaded plugin for a listed file, as SourceMod names it (Windows uses "\" in plugin paths).
bool FindLoaded(const char[] file, char[] loaded, int maxlen)
{
	char want[PLATFORM_MAX_PATH], name[PLATFORM_MAX_PATH];
	strcopy(want, sizeof(want), file);
	ReplaceString(want, sizeof(want), "\\", "/");
	Handle iter = GetPluginIterator();
	bool found = false;
	while (MorePlugins(iter))
	{
		Handle plugin = ReadPlugin(iter);
		GetPluginFilename(plugin, name, sizeof(name));
		strcopy(loaded, maxlen, name);
		ReplaceString(name, sizeof(name), "\\", "/");
		if (StrEqual(name, want, false))
		{
			found = true;
			break;
		}
	}
	delete iter;
	return found;
}

Action Cmd_Status(int client, int args)
{
	char mode[64], file[PLATFORM_MAX_PATH];
	FindConVar("mp_gamemode").GetString(mode, sizeof(mode));
	StringToLower(mode);
	ArrayList want;
	if (!g_smModes.GetValue(mode, want) || want.Length == 0)
	{
		ReplyToCommand(client, "[ModePlugins] Nothing is turned off in game mode %s.", mode);
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[ModePlugins] Turned off in game mode %s:", mode);
	for (int i = 0; i < want.Length; i++)
	{
		want.GetString(i, file, sizeof(file));
		ReplyToCommand(client, "  %s (%s)", file, FindLoaded(file, mode, sizeof(mode)) ? "still loaded" : "off");
	}
	return Plugin_Handled;
}
