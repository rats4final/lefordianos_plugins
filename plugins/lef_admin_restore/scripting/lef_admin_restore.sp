/**
 * Lefordianos Admin Restore
 *
 * Undo griefing. An improvement on Harry Potter's admin_hp (which only heals every
 * survivor to full).
 *
 *  - !heal <player|@survivors>   full heal, like a medkit.
 *  - !restore <player>           gives back exactly what *teammates* took from a survivor:
 *                                the HP, the incaps (toward black-and-white), a revive if a
 *                                teammate downed them, a respawn next to the team if a teammate
 *                                killed them, and the items they had before the first team hit.
 *  - !teamdamage                 who has team damage that can be undone.
 *  - Admins get a heads-up when someone takes heavy team damage, an incap or a team kill.
 *  - Both actions are in the !admin menu under Player Commands.
 *
 * How it knows what to give back: for each survivor it keeps a small "ledger" of team damage.
 * On the first hit from a teammate it takes a snapshot of their health, incap count and items;
 * then it adds up the team damage, incaps and a possible team kill. The ledger is forgotten
 * after lef_restore_memory seconds without team damage, at round start, or after a restore.
 *
 * Access is set by lef_restore_access (admin flags, default root). The override name
 * "lef_admin_restore" also works in admin_overrides.cfg.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.0.0"

#define TEAM_SURVIVOR   2
#define SLOT_COUNT      5
#define SOUND_HEART     "player/heartbeatloop.wav"
#define ACCESS_OVERRIDE "lef_admin_restore"

// Harry Potter's l4d_heartbeat, if loaded, owns the revive count; set it through its native.
native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true);

public Plugin myinfo =
{
	name        = "[L4D2] Lefordianos Admin Restore",
	author      = "rats4final; inspired by admin_hp by Harry Potter",
	description = "Heal survivors and undo team damage: HP, incaps, team kills and lost items",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/rats4final/lefordianos_plugins"
};

ConVar
	g_cvAccess,
	g_cvMemory,
	g_cvNotifyDamage,
	g_cvMaxIncaps;

bool g_bHeartbeat;

TopMenu g_hTopMenu;

// --- Ledger: what teammates did to each survivor ---------------------------
int   g_iDamage[MAXPLAYERS + 1];
int   g_iIncaps[MAXPLAYERS + 1];
bool  g_bKilled[MAXPLAYERS + 1];
float g_fLastHit[MAXPLAYERS + 1];
bool  g_bNotifiedDamage[MAXPLAYERS + 1];
char  g_sLastAttacker[MAXPLAYERS + 1][MAX_NAME_LENGTH];
int   g_iLastAttacker[MAXPLAYERS + 1]; // userid

// --- Snapshot taken right before the first team hit ------------------------
bool g_bSnap[MAXPLAYERS + 1];
bool g_bSnapIncapped[MAXPLAYERS + 1];
int  g_iSnapHealth[MAXPLAYERS + 1];
int  g_iSnapTemp[MAXPLAYERS + 1];
int  g_iSnapRevives[MAXPLAYERS + 1];
bool g_bSnapDual[MAXPLAYERS + 1];
char g_sSnapItem[MAXPLAYERS + 1][SLOT_COUNT][64]; // "give" names, "" = empty slot

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	MarkNativeAsOptional("Heartbeat_SetRevives");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("lef_admin_restore.phrases");

	CreateConVar("lef_admin_restore_version", PLUGIN_VERSION, "Lefordianos Admin Restore version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvAccess       = CreateConVar("lef_restore_access", "z", "Admin flags needed for !heal, !restore and !teamdamage (z = root). Any one of the flags is enough.");
	g_cvMemory       = CreateConVar("lef_restore_memory", "300", "Seconds after the last team hit that the damage can still be undone.", _, true, 10.0);
	g_cvNotifyDamage = CreateConVar("lef_restore_notify_damage", "25", "Tell admins when a survivor has taken this much team damage from a player (incaps and team kills are always reported). 0 = never.", _, true, 0.0);
	AutoExecConfig(true, "lef_admin_restore");

	g_cvMaxIncaps = FindConVar("survivor_max_incapacitated_count");

	RegConsoleCmd("sm_heal", Cmd_Heal, "sm_heal <player|@survivors> - full heal (admin)");
	RegConsoleCmd("sm_restore", Cmd_Restore, "sm_restore <player> - undo what teammates did to a survivor (admin)");
	RegConsoleCmd("sm_teamdamage", Cmd_TeamDamage, "List team damage that can be undone (admin)");

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}

	TopMenu topmenu;
	if (LibraryExists("adminmenu") && (topmenu = GetAdminTopMenu()) != null)
	{
		OnAdminMenuReady(topmenu);
	}
}

public void OnAllPluginsLoaded()
{
	g_bHeartbeat = LibraryExists("l4d_heartbeat");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "l4d_heartbeat"))
	{
		g_bHeartbeat = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "l4d_heartbeat"))
	{
		g_bHeartbeat = false;
	}
	else if (StrEqual(name, "adminmenu"))
	{
		g_hTopMenu = null;
	}
}

public void OnClientPutInServer(int client)
{
	ClearLedger(client);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	ClearLedger(client);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		ClearLedger(i);
	}
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0)
	{
		ClearLedger(client);
	}
}

// ---------------------------------------------------------------------------
// Recording team damage
// ---------------------------------------------------------------------------

// Before the damage lands: snapshot the victim on the first team hit.
Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damage > 0.0 && IsTeamHit(victim, attacker) && !HasLedger(victim))
	{
		TakeSnapshot(victim);
	}

	return Plugin_Continue;
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim   = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage   = event.GetInt("dmg_health");

	// Damage to someone already down only drains their incap health; the revive covers that.
	if (damage <= 0 || !IsTeamHit(victim, attacker) || L4D_IsPlayerIncapacitated(victim))
	{
		return;
	}

	RecordHit(victim, attacker);
	g_iDamage[victim] += damage;

	int threshold = g_cvNotifyDamage.IntValue;
	if (threshold > 0 && !g_bNotifiedDamage[victim] && g_iDamage[victim] >= threshold && !IsFakeClient(attacker))
	{
		g_bNotifiedDamage[victim] = true;
		NotifyAdmins("Notify Damage", attacker, victim, g_iDamage[victim]);
	}
}

void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int victim   = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsTeamHit(victim, attacker))
	{
		return;
	}

	RecordHit(victim, attacker);
	g_iIncaps[victim]++;

	if (!IsFakeClient(attacker))
	{
		NotifyAdmins("Notify Incap", attacker, victim, 0);
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim   = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsTeamHit(victim, attacker))
	{
		return;
	}

	RecordHit(victim, attacker);
	g_bKilled[victim] = true;

	if (!IsFakeClient(attacker))
	{
		NotifyAdmins("Notify Kill", attacker, victim, 0);
	}
}

// A survivor hurt by a different survivor (human or bot).
bool IsTeamHit(int victim, int attacker)
{
	return victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && victim != attacker
		&& IsClientInGame(victim) && IsClientInGame(attacker)
		&& GetClientTeam(victim) == TEAM_SURVIVOR && GetClientTeam(attacker) == TEAM_SURVIVOR;
}

void RecordHit(int victim, int attacker)
{
	if (!HasLedger(victim))
	{
		// A ledger that expired gets a fresh start (and a fresh snapshot, if the victim is up).
		ClearLedger(victim);
		if (IsPlayerAlive(victim))
		{
			TakeSnapshot(victim);
		}
	}

	g_fLastHit[victim]      = GetGameTime();
	g_iLastAttacker[victim] = GetClientUserId(attacker);
	GetClientName(attacker, g_sLastAttacker[victim], sizeof(g_sLastAttacker[]));
}

void TakeSnapshot(int client)
{
	g_bSnap[client]         = true;
	g_bSnapIncapped[client] = L4D_IsPlayerIncapacitated(client);
	g_iSnapHealth[client]   = GetClientHealth(client);
	g_iSnapTemp[client]     = L4D_GetPlayerTempHealth(client);
	g_iSnapRevives[client]  = L4D_GetPlayerReviveCount(client);
	g_bSnapDual[client]     = false;
	g_fLastHit[client]      = GetGameTime();

	for (int slot = 0; slot < SLOT_COUNT; slot++)
	{
		g_sSnapItem[client][slot][0] = '\0';

		int weapon = GetPlayerWeaponSlot(client, slot);
		if (weapon == -1)
		{
			continue;
		}

		GetGiveName(weapon, g_sSnapItem[client][slot], sizeof(g_sSnapItem[][]));

		if (slot == 1 && HasEntProp(weapon, Prop_Send, "m_hasDualWeapons") && GetEntProp(weapon, Prop_Send, "m_hasDualWeapons"))
		{
			g_bSnapDual[client] = true;
		}
	}
}

// The name the "give" command understands: "rifle_ak47", "fireaxe", "pain_pills"...
void GetGiveName(int weapon, char[] buffer, int maxlength)
{
	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));

	if (StrEqual(classname, "weapon_melee") && HasEntProp(weapon, Prop_Data, "m_strMapSetScriptName"))
	{
		GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", buffer, maxlength);
		return;
	}

	strcopy(buffer, maxlength, classname[StrContains(classname, "weapon_") == 0 ? 7 : 0]);
}

bool HasLedger(int client)
{
	bool anything = g_bSnap[client] || g_iDamage[client] > 0 || g_iIncaps[client] > 0 || g_bKilled[client];
	return anything && GetGameTime() - g_fLastHit[client] <= g_cvMemory.FloatValue;
}

// Worth showing in the restore menu: an actual hit happened, not just a snapshot.
bool HasSomethingToUndo(int client)
{
	return HasLedger(client) && (g_iDamage[client] > 0 || g_iIncaps[client] > 0 || g_bKilled[client]);
}

void ClearLedger(int client)
{
	g_iDamage[client]         = 0;
	g_iIncaps[client]         = 0;
	g_bKilled[client]         = false;
	g_fLastHit[client]        = 0.0;
	g_bNotifiedDamage[client] = false;
	g_sLastAttacker[client][0] = '\0';
	g_iLastAttacker[client]   = 0;
	g_bSnap[client]           = false;
}

void NotifyAdmins(const char[] phrase, int attacker, int victim, int amount)
{
	char attackerName[MAX_NAME_LENGTH], victimName[MAX_NAME_LENGTH];
	GetClientName(attacker, attackerName, sizeof(attackerName));
	GetClientName(victim, victimName, sizeof(victimName));

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && HasAccess(i))
		{
			CPrintToChat(i, "%T", phrase, i, attackerName, victimName, amount);
		}
	}
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

Action Cmd_Heal(int client, int args)
{
	if (!RequireAccess(client))
	{
		return Plugin_Handled;
	}

	if (args < 1)
	{
		if (client == 0)
		{
			ReplyToCommand(client, "Usage: sm_heal <player|@survivors>");
		}
		else
		{
			ShowHealMenu(client);
		}
		return Plugin_Handled;
	}

	char arg[MAX_TARGET_LENGTH], targetName[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));

	int targets[MAXPLAYERS];
	bool tnIsMl;
	int count = ProcessTargetString(arg, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), tnIsMl);
	if (count <= 0)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	int healed;
	for (int i = 0; i < count; i++)
	{
		if (GetClientTeam(targets[i]) == TEAM_SURVIVOR && HealSurvivor(client, targets[i], count == 1))
		{
			healed++;
		}
	}

	if (healed > 0)
	{
		AnnounceHeal(client, count == 1 ? targets[0] : 0);
	}

	return Plugin_Handled;
}

Action Cmd_Restore(int client, int args)
{
	if (!RequireAccess(client))
	{
		return Plugin_Handled;
	}

	if (args < 1)
	{
		if (client == 0)
		{
			ReplyToCommand(client, "Usage: sm_restore <player>");
		}
		else
		{
			ShowRestoreMenu(client);
		}
		return Plugin_Handled;
	}

	char arg[MAX_NAME_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));

	// Dead players are allowed: undoing a team kill is the point.
	int target = FindTarget(client, arg, false, false);
	if (target > 0)
	{
		RestoreSurvivor(client, target);
	}

	return Plugin_Handled;
}

Action Cmd_TeamDamage(int client, int args)
{
	if (!RequireAccess(client))
	{
		return Plugin_Handled;
	}

	char line[192];
	bool any;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && HasSomethingToUndo(i))
		{
			DescribeLedger(client, i, line, sizeof(line));
			ReplyToAdmin(client, "%s", line);
			any = true;
		}
	}

	if (!any)
	{
		ReplyToAdmin(client, "%T", "Nothing To Undo Anyone", client);
	}

	return Plugin_Handled;
}

// ---------------------------------------------------------------------------
// Healing
// ---------------------------------------------------------------------------

bool HealSurvivor(int admin, int target, bool report)
{
	if (!IsPlayerAlive(target))
	{
		return false;
	}

	// Healing a pinned survivor would free them from the SI; leave that to the team.
	if (L4D_IsPlayerPinned(target))
	{
		if (report)
		{
			char name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));
			ReplyToAdmin(admin, "%T", "Pinned", admin, name);
		}
		return false;
	}

	// Same as a medkit: revives if down, full health, no more black-and-white.
	GiveItem(target, "health");
	L4D_SetPlayerTempHealth(target, 0);
	SetRevives(target, 0);

	LogAction(admin, target, "\"%L\" healed \"%L\"", admin, target);
	return true;
}

void AnnounceHeal(int admin, int target)
{
	char adminName[MAX_NAME_LENGTH], targetName[MAX_NAME_LENGTH];
	GetAdminName(admin, adminName, sizeof(adminName));

	if (target > 0)
	{
		GetClientName(target, targetName, sizeof(targetName));
		CPrintToChatAll("%t", "Healed One", adminName, targetName);
	}
	else
	{
		CPrintToChatAll("%t", "Healed All", adminName);
	}
}

// ---------------------------------------------------------------------------
// Restoring
// ---------------------------------------------------------------------------

void RestoreSurvivor(int admin, int target)
{
	char targetName[MAX_NAME_LENGTH], adminName[MAX_NAME_LENGTH], summary[192];
	GetClientName(target, targetName, sizeof(targetName));
	GetAdminName(admin, adminName, sizeof(adminName));

	if (GetClientTeam(target) != TEAM_SURVIVOR || !HasSomethingToUndo(target))
	{
		ReplyToAdmin(admin, "%T", "Nothing To Undo", admin, targetName);
		return;
	}

	bool alive = IsPlayerAlive(target);
	bool down  = alive && L4D_IsPlayerIncapacitated(target);

	if (down && L4D_IsPlayerPinned(target))
	{
		ReplyToAdmin(admin, "%T", "Pinned", admin, targetName);
		return;
	}

	FormatLedgerSummary(admin, target, summary, sizeof(summary));

	// 1. Bring them back: respawn if team-killed (or bled out after a team incap), revive if down.
	bool respawned;
	if (!alive)
	{
		if (!g_bKilled[target] && g_iIncaps[target] == 0)
		{
			ReplyToAdmin(admin, "%T", "Died Otherwise", admin, targetName);
			return;
		}

		L4D_RespawnPlayer(target);
		TeleportToTeam(target);
		respawned = true;
	}
	else if (down)
	{
		L4D_ReviveSurvivor(target);
	}

	// 2. Health and incap count.
	int maxHealth = GetEntProp(target, Prop_Data, "m_iMaxHealth");

	if (g_bSnap[target] && !g_bSnapIncapped[target] && (respawned || down))
	{
		// They lost everything since the snapshot to teammates: put them back as they were.
		SetEntityHealth(target, Clamp(g_iSnapHealth[target], 1, maxHealth));
		L4D_SetPlayerTempHealth(target, g_iSnapTemp[target]);
		SetRevives(target, g_iSnapRevives[target]);
	}
	else
	{
		// Still up: give back the HP teammates took, and the incaps they caused.
		int temp   = L4D_GetPlayerTempHealth(target);
		SetEntityHealth(target, Clamp(GetClientHealth(target) + g_iDamage[target], 1, maxHealth - temp));

		int revives = L4D_GetPlayerReviveCount(target) - g_iIncaps[target];
		if (g_bSnap[target] && revives < g_iSnapRevives[target])
		{
			revives = g_iSnapRevives[target];
		}
		SetRevives(target, revives < 0 ? 0 : revives);
	}

	// 3. Items they had before the first team hit.
	if (g_bSnap[target])
	{
		RestoreItems(target, respawned);
	}

	LogAction(admin, target, "\"%L\" restored \"%L\" (%s)", admin, target, summary);
	CPrintToChatAll("%t", "Restored", adminName, targetName, summary);

	ClearLedger(target);
}

// Gives back snapshot items for empty slots. After a respawn, the default pistol is replaced.
void RestoreItems(int client, bool replace)
{
	for (int slot = 0; slot < SLOT_COUNT; slot++)
	{
		if (g_sSnapItem[client][slot][0] == '\0')
		{
			continue;
		}

		int current = GetPlayerWeaponSlot(client, slot);
		if (current != -1)
		{
			if (!replace)
			{
				continue;
			}

			RemovePlayerItem(client, current);
			RemoveEntity(current);
		}

		GiveItem(client, g_sSnapItem[client][slot]);

		if (slot == 1 && g_bSnapDual[client])
		{
			GiveItem(client, g_sSnapItem[client][slot]);
		}
	}
}

// Puts a respawned survivor next to a teammate who's up, preferring someone who didn't do it.
void TeleportToTeam(int client)
{
	int attacker = GetClientOfUserId(g_iLastAttacker[client]);
	int fallback;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client || !IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i) || L4D_IsPlayerIncapacitated(i))
		{
			continue;
		}

		if (i != attacker)
		{
			TeleportNextTo(client, i);
			return;
		}

		fallback = i;
	}

	if (fallback != 0)
	{
		TeleportNextTo(client, fallback);
	}
}

void TeleportNextTo(int client, int teammate)
{
	float pos[3];
	GetClientAbsOrigin(teammate, pos);
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

// ---------------------------------------------------------------------------
// Admin menu (Player Commands category)
// ---------------------------------------------------------------------------

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);
	if (topmenu == g_hTopMenu)
	{
		return;
	}

	g_hTopMenu = topmenu;

	TopMenuObject category = g_hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);
	if (category == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	// Flags 0 here; DrawOption hides the items from admins without lef_restore_access.
	g_hTopMenu.AddItem("lef_heal_player", AdminItem_Handler, category, "", 0, "heal");
	g_hTopMenu.AddItem("lef_restore_player", AdminItem_Handler, category, "", 0, "restore");
}

void AdminItem_Handler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	char info[16];
	topmenu.GetInfoString(object_id, info, sizeof(info));

	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlength, "%T", StrEqual(info, "heal") ? "Menu Heal" : "Menu Restore", param);
		}
		case TopMenuAction_DrawOption:
		{
			buffer[0] = HasAccess(param) ? ITEMDRAW_DEFAULT : ITEMDRAW_IGNORE;
		}
		case TopMenuAction_SelectOption:
		{
			if (StrEqual(info, "heal"))
			{
				ShowHealMenu(param);
			}
			else
			{
				ShowRestoreMenu(param);
			}
		}
	}
}

void ShowHealMenu(int admin)
{
	Menu menu = new Menu(HealMenu_Handler);
	char title[64], display[96], info[16], name[MAX_NAME_LENGTH];

	FormatEx(title, sizeof(title), "%T", "Menu Heal", admin);
	menu.SetTitle(title);
	menu.ExitBackButton = (g_hTopMenu != null);

	FormatEx(display, sizeof(display), "%T", "Menu All Survivors", admin);
	menu.AddItem("all", display);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i))
		{
			continue;
		}

		GetClientName(i, name, sizeof(name));
		FormatEx(display, sizeof(display), "%s (%d HP%s)", name, GetClientHealth(i) + L4D_GetPlayerTempHealth(i), L4D_IsPlayerIncapacitated(i) ? ", down" : "");
		IntToString(GetClientUserId(i), info, sizeof(info));
		menu.AddItem(info, display);
	}

	menu.Display(admin, MENU_TIME_FOREVER);
}

int HealMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && g_hTopMenu != null)
	{
		g_hTopMenu.Display(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select && HasAccess(param1))
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));

		if (StrEqual(info, "all"))
		{
			int healed;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && HealSurvivor(param1, i, false))
				{
					healed++;
				}
			}
			if (healed > 0)
			{
				AnnounceHeal(param1, 0);
			}
		}
		else
		{
			int target = GetClientOfUserId(StringToInt(info));
			if (target == 0)
			{
				CPrintToChat(param1, "%T", "Player Gone", param1);
			}
			else if (HealSurvivor(param1, target, true))
			{
				AnnounceHeal(param1, target);
			}
		}

		ShowHealMenu(param1);
	}

	return 0;
}

void ShowRestoreMenu(int admin)
{
	Menu menu = new Menu(RestoreMenu_Handler);
	char title[64], display[192], info[16];

	FormatEx(title, sizeof(title), "%T", "Menu Restore", admin);
	menu.SetTitle(title);
	menu.ExitBackButton = (g_hTopMenu != null);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && HasSomethingToUndo(i))
		{
			DescribeLedger(admin, i, display, sizeof(display));
			IntToString(GetClientUserId(i), info, sizeof(info));
			menu.AddItem(info, display);
		}
	}

	if (menu.ItemCount == 0)
	{
		CPrintToChat(admin, "%T", "Nothing To Undo Anyone", admin);
		delete menu;
		if (g_hTopMenu != null)
		{
			g_hTopMenu.Display(admin, TopMenuPosition_LastCategory);
		}
		return;
	}

	menu.Display(admin, MENU_TIME_FOREVER);
}

int RestoreMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && g_hTopMenu != null)
	{
		g_hTopMenu.Display(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select && HasAccess(param1))
	{
		char info[16];
		menu.GetItem(param2, info, sizeof(info));

		int target = GetClientOfUserId(StringToInt(info));
		if (target == 0)
		{
			CPrintToChat(param1, "%T", "Player Gone", param1);
		}
		else
		{
			RestoreSurvivor(param1, target);
		}
	}

	return 0;
}

// "Nick: 45 HP, 1 incap, killed (Troll)"
void DescribeLedger(int viewer, int client, char[] buffer, int maxlength)
{
	char name[MAX_NAME_LENGTH], summary[160];
	GetClientName(client, name, sizeof(name));
	FormatLedgerSummary(viewer, client, summary, sizeof(summary));
	FormatEx(buffer, maxlength, "%s: %s (%s)", name, summary, g_sLastAttacker[client]);
}

// "45 HP, 1 incap, killed, items"
void FormatLedgerSummary(int viewer, int client, char[] buffer, int maxlength)
{
	buffer[0] = '\0';

	if (g_iDamage[client] > 0)
	{
		Format(buffer, maxlength, "%s%s%d HP", buffer, buffer[0] ? ", " : "", g_iDamage[client]);
	}
	if (g_iIncaps[client] > 0)
	{
		Format(buffer, maxlength, "%s%s%T", buffer, buffer[0] ? ", " : "", "Summary Incaps", viewer, g_iIncaps[client]);
	}
	if (g_bKilled[client])
	{
		Format(buffer, maxlength, "%s%s%T", buffer, buffer[0] ? ", " : "", "Summary Killed", viewer);
	}
	if (g_bSnap[client])
	{
		Format(buffer, maxlength, "%s%s%T", buffer, buffer[0] ? ", " : "", "Summary Items", viewer);
	}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool HasAccess(int client)
{
	if (client == 0)
	{
		return true;
	}

	char flags[32];
	g_cvAccess.GetString(flags, sizeof(flags));
	return CheckCommandAccess(client, ACCESS_OVERRIDE, ReadFlagString(flags), true);
}

bool RequireAccess(int client)
{
	if (HasAccess(client))
	{
		return true;
	}

	ReplyToCommand(client, "[SM] %t", "No Access");
	return false;
}

// Sets the incap count and the black-and-white state that goes with it.
void SetRevives(int client, int count)
{
	if (g_bHeartbeat && GetFeatureStatus(FeatureType_Native, "Heartbeat_SetRevives") == FeatureStatus_Available)
	{
		Heartbeat_SetRevives(client, count, true);
		return;
	}

	int max = g_cvMaxIncaps != null ? g_cvMaxIncaps.IntValue : 2;
	bool blackAndWhite = count >= max;

	SetEntProp(client, Prop_Send, "m_currentReviveCount", count);
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", blackAndWhite);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", count > 0);

	if (!blackAndWhite)
	{
		// The heartbeat loop doesn't stop on its own; several stops is what reliably works.
		for (int i = 0; i < 4; i++)
		{
			StopSound(client, SNDCHAN_AUTO, SOUND_HEART);
			StopSound(client, SNDCHAN_STATIC, SOUND_HEART);
		}
	}
}

void GiveItem(int client, const char[] item)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", item);
	SetCommandFlags("give", flags);
}

void GetAdminName(int admin, char[] buffer, int maxlength)
{
	if (admin > 0 && IsClientInGame(admin))
	{
		GetClientName(admin, buffer, maxlength);
	}
	else
	{
		strcopy(buffer, maxlength, "Console");
	}
}

int Clamp(int value, int min, int max)
{
	return value < min ? min : (value > max ? max : value);
}

// Reply that works from menus too (there's no command to reply to there).
void ReplyToAdmin(int client, const char[] format, any...)
{
	char buffer[254];
	SetGlobalTransTarget(client == 0 ? LANG_SERVER : client);
	VFormat(buffer, sizeof(buffer), format, 3);

	if (client == 0)
	{
		CRemoveTags(buffer, sizeof(buffer));
		PrintToServer("%s", buffer);
	}
	else if (IsClientInGame(client))
	{
		CPrintToChat(client, "%s", buffer);
	}
}
