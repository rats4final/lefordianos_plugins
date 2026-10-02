/**
 * Lefordianos Menu
 *
 * !menu (or !lef): one front door for players. It lists the player commands the server has
 * (teams, joining a team, votes, scores, bosses...) so nobody has to remember them.
 *
 * The entries are in configs/lef_menu.cfg, grouped. Picking one runs that command for the player,
 * as if they had typed it. Entries whose command doesn't exist on the server (plugin not
 * installed) are hidden, so the same config works with any plugin set.
 * Admin tools stay in !admin.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.0.0"
#define CONFIG_FILE    "configs/lef_menu.cfg"

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Menu",
	author      = "rats4final",
	description = "!menu: every player command on the server in one menu",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

enum struct MenuGroup
{
	char titleEn[64];
	char titleEs[64];
}

enum struct MenuEntry
{
	int  group;
	char titleEn[96];
	char titleEs[96];
	char command[128];
}

ArrayList g_aGroups;
ArrayList g_aEntries;
int       g_iGroup[MAXPLAYERS + 1];

public void OnPluginStart()
{
	LoadTranslations("lef_menu.phrases");

	CreateConVar("lef_menu_version", PLUGIN_VERSION, "Lefordianos Menu version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	RegConsoleCmd("sm_menu", Cmd_Menu, "Open the Lefordianos menu");
	RegConsoleCmd("sm_lef", Cmd_Menu, "Open the Lefordianos menu");
	RegAdminCmd("sm_menu_reload", Cmd_Reload, ADMFLAG_CONFIG, "Reload configs/lef_menu.cfg");

	g_aGroups  = new ArrayList(sizeof(MenuGroup));
	g_aEntries = new ArrayList(sizeof(MenuEntry));
	LoadConfig();
}

void LoadConfig()
{
	g_aGroups.Clear();
	g_aEntries.Clear();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), CONFIG_FILE);

	KeyValues kv = new KeyValues("Menu");
	if (!kv.ImportFromFile(path))
	{
		LogError("Couldn't read %s; the menu is empty", CONFIG_FILE);
		delete kv;
		return;
	}

	if (kv.GotoFirstSubKey())
	{
		do
		{
			char key[32];
			kv.GetSectionName(key, sizeof(key));

			MenuGroup group;
			ReadTitle(kv, group.titleEn, sizeof(group.titleEn), group.titleEs, sizeof(group.titleEs), key);
			int groupIndex = g_aGroups.PushArray(group);

			if (kv.GotoFirstSubKey())
			{
				do
				{
					kv.GetSectionName(key, sizeof(key));
					if (StrEqual(key, "title") || kv.GetNum("enabled", 1) == 0)
					{
						continue;
					}

					MenuEntry entry;
					entry.group = groupIndex;
					ReadTitle(kv, entry.titleEn, sizeof(entry.titleEn), entry.titleEs, sizeof(entry.titleEs), key);
					kv.GetString("command", entry.command, sizeof(entry.command));
					if (entry.command[0] != '\0')
					{
						g_aEntries.PushArray(entry);
					}
				}
				while (kv.GotoNextKey());
				kv.GoBack();
			}
		}
		while (kv.GotoNextKey());
	}

	delete kv;
}

// Reads a "title" { "en" "..." "es" "..." } subsection of the current key.
void ReadTitle(KeyValues kv, char[] en, int enLen, char[] es, int esLen, const char[] fallback)
{
	strcopy(en, enLen, fallback);
	strcopy(es, esLen, "");
	if (kv.JumpToKey("title"))
	{
		kv.GetString("en", en, enLen, fallback);
		kv.GetString("es", es, esLen, "");
		kv.GoBack();
	}
	if (es[0] == '\0')
	{
		strcopy(es, esLen, en);
	}
}

bool UsesSpanish(int client)
{
	char code[8], name[32];
	GetLanguageInfo(GetClientLanguage(client), code, sizeof(code), name, sizeof(name));
	return StrEqual(code, "es") || StrEqual(code, "las");   // Spain or Latin America
}

// The first word of the entry's command must exist (its plugin is loaded).
bool IsAvailable(MenuEntry entry)
{
	char name[64];
	int len = BreakString(entry.command, name, sizeof(name));
	return len != 0 && CommandExists(name);
}

int CountAvailable(int group)
{
	int count;
	MenuEntry entry;
	for (int i = 0; i < g_aEntries.Length; i++)
	{
		g_aEntries.GetArray(i, entry);
		if (entry.group == group && IsAvailable(entry))
		{
			count++;
		}
	}
	return count;
}

Action Cmd_Reload(int client, int args)
{
	LoadConfig();
	ReplyToCommand(client, "[Menu] %d entries in %d groups loaded.", g_aEntries.Length, g_aGroups.Length);
	return Plugin_Handled;
}

Action Cmd_Menu(int client, int args)
{
	if (client == 0 || !IsClientInGame(client))
	{
		ReplyToCommand(client, "[Menu] This command is for players.");
		return Plugin_Handled;
	}

	ShowGroups(client);
	return Plugin_Handled;
}

void ShowGroups(int client)
{
	Menu menu = new Menu(Groups_Handler);
	char text[64], info[8];

	FormatEx(text, sizeof(text), "%T", "Menu Title", client);
	menu.SetTitle(text);

	bool es = UsesSpanish(client);
	MenuGroup group;
	for (int g = 0; g < g_aGroups.Length; g++)
	{
		if (CountAvailable(g) == 0)
		{
			continue;
		}
		g_aGroups.GetArray(g, group);
		IntToString(g, info, sizeof(info));
		menu.AddItem(info, es ? group.titleEs : group.titleEn);
	}

	if (menu.ItemCount == 0)
	{
		CPrintToChat(client, "%T", "Empty", client);
		delete menu;
		return;
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

int Groups_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));
		ShowEntries(client, StringToInt(info));
	}
	return 0;
}

void ShowEntries(int client, int groupIndex)
{
	g_iGroup[client] = groupIndex;

	Menu menu = new Menu(Entries_Handler);
	bool es = UsesSpanish(client);

	MenuGroup group;
	g_aGroups.GetArray(groupIndex, group);
	menu.SetTitle(es ? group.titleEs : group.titleEn);
	menu.ExitBackButton = true;

	char info[8];
	MenuEntry entry;
	for (int i = 0; i < g_aEntries.Length; i++)
	{
		g_aEntries.GetArray(i, entry);
		if (entry.group != groupIndex || !IsAvailable(entry))
		{
			continue;
		}
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, es ? entry.titleEs : entry.titleEn);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

int Entries_Handler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param == MenuCancel_ExitBack)
	{
		ShowGroups(client);
	}
	else if (action == MenuAction_Select)
	{
		char info[8];
		menu.GetItem(param, info, sizeof(info));

		MenuEntry entry;
		g_aEntries.GetArray(StringToInt(info), entry);
		FakeClientCommand(client, "%s", entry.command);
	}
	return 0;
}
