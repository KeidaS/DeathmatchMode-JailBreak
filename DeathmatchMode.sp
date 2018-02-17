#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <devzones>


public Plugin myinfo = 
{
	name = "DeathmatchModeJailBreak", 
	author = "KeidaS", 
	description = "Enables Deathmatch with teammates", 
	version = "1.0", 
	url = "www.hermandadfenix.es"
};
bool deathmatch = false;
bool clientOnZone[MAXPLAYERS + 1] = false;
bool headshot = false;
public void OnPluginStart()
{
	RegAdminCmd("enabledm", DM_Enable, ADMFLAG_BAN);
	RegAdminCmd("disabledm", DM_Disable, ADMFLAG_BAN);
	HookEvent("round_end", Event_OnRoundEnd);
}

public void OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, DamageController);
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	SetConVarInt(FindConVar("mp_teammates_are_enemies"), 0, false, false);
	SetConVarInt(FindConVar("mp_damage_headshot_only"), 0, false, false);
}

public Action:DamageController(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if (!deathmatch) {
		return Plugin_Continue;
	} else {
		//CS_TEAM_CT = 3, CS_TEAM_T = 2;
		if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) == 3) {
			damage = 0.0;
			return Plugin_Changed;
		} else if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) == 2 && clientOnZone[attacker] == true) {
			damage = 0.0;
			return Plugin_Changed;
		} else if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2 && clientOnZone[victim] == true && clientOnZone[attacker] == false) {
			damage = 0.0;
			return Plugin_Changed;
		} else if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2 && clientOnZone[victim] == false && clientOnZone[attacker] == true) {
			damage = 0.0;
			return Plugin_Changed;
		} else if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2 && clientOnZone[victim] == false && clientOnZone[attacker] == false) {
			damage = 0.0;
			return Plugin_Changed;
		} else {
			return Plugin_Continue;
		}
	}
}
public int Zone_OnClientEntry(client, char[] zone) {
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return;
	} else {
		clientOnZone[client] = true;
		return;
	}
}

public int Zone_OnClientLeave(client, char[] zone) {
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return;
	} else {
		clientOnZone[client] = false;
		if (deathmatch == true && GetClientTeam(client) == 2) {
			if (IsClientInGame(client) && (!IsFakeClient(client)) && IsPlayerAlive(client)) {
				RemoveWeapons(client);
				GivePlayerItem(client, "weapon_knife");
			}
		}
		return;
	}
}

public Action Health(int client, int args) {
	SetEntityHealth(client, args);
}

public Action DM_Enable(int client, int args) {
	if (GetClientTeam(client)!=3) {
		PrintToChat(client, "You must be CT to use this command");
	} else if (GetClientTeam(client) == 3 && !IsPlayerAlive(client)) {
		PrintToChat(client, "You must be alive to use this command");
	} else {
		Menu menu = new Menu(MenuHandler_Mode, MenuAction_Start | MenuAction_Select | MenuAction_Cancel | MenuAction_End);
		menu.SetTitle("Select DM mode:");
		menu.AddItem("Headshot", "Headshot");
		menu.AddItem("Normal", "Normal");
		menu.Display(client, 20);
	}
	return Plugin_Handled;
}

public void ChooseWeapon(int client) {
	Menu menu = new Menu(MenuHandler_Weapon, MenuAction_Start | MenuAction_Select | MenuAction_Cancel | MenuAction_End);
	menu.SetTitle("Select weapon for the DM:");
	menu.AddItem("USP", "USP");
	menu.AddItem("Desert Eagle", "Desert Eagle");
	menu.Display(client, 20);
}

public int MenuHandler_Mode(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		char info[64];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "Headshot")) {
			headshot = true;
			ChooseWeapon(param1);
		} else if (StrEqual(info, "Normal")) {
			headshot = false;
			ChooseWeapon(param1);
		}
		
	}
	return 0;
}

/*public Action Timer_WaitForDM (Handle timer) {
	static int secondsLeft = 3;
	if (secondsLeft<=0) {
		secondsLeft = 3;
		return Plugin_Stop;
	}
	PrintHintTextToAll("DM starts in %i", secondsLeft);
	secondsLeft--;
	return Plugin_Continue;
}*/

public int MenuHandler_Weapon(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		//CreateTimer(1.0, Timer_WaitForDM, _, TIMER_REPEAT);
		char info[64];
		menu.GetItem(param2, info, sizeof(info));
		ConfigureMode();
		SetConVarInt(FindConVar("mp_teammates_are_enemies"), 1, false, false);
		deathmatch = true;
		for (int i = 0; i < MAXPLAYERS; i++) {
			if (clientOnZone[i]) {
				if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i)) {
					//enemies.ReplicateToClient(i, "1");
					//ff.ReplicateToClient(i, "0");
					RemoveWeapons(i);
					if (StrEqual(info, "USP")) {
						GivePlayerItem(i, "weapon_usp_silencer");
					} else {
						GivePlayerItem(i, "weapon_deagle");
					}
				}
			}
		}
	}
}

public void RemoveWeapons(int client) {
	if (GetPlayerWeaponSlot(client, 0) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	}
	if (GetPlayerWeaponSlot(client, 1) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	}
	if (GetPlayerWeaponSlot(client, 2) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
	}
}

public Action DM_Disable(int client, int args) {
	if (!deathmatch) {
		PrintToChat(client, "Deathmatch isn't enabled");
	} else if (GetClientTeam(client)!=3) {
		PrintToChat(client, "You must be CT to use this command");
	} else if (GetClientTeam(client) == 3 && !IsPlayerAlive(client)) {
		PrintToChat(client, "You must be alive to use this command");
	} else {
		deathmatch = false;
		for (int i = 0; i < MAXPLAYERS; i++) {
			if (clientOnZone[i] && GetClientTeam(client) == 3) {
				if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i)) {
					RemoveWeapons(i);
					GivePlayerItem(i, "weapon_knife");
					SetConVarInt(FindConVar("mp_teammates_are_enemies"), 0, false, false);
					SetConVarInt(FindConVar("mp_damage_headshot_only"), 0, false, false);
				}
			}
		}
		SetConVarInt(FindConVar("mp_teammates_are_enemies"), 0, false, false);
		SetConVarInt(FindConVar("mp_damage_headshot_only"), 0, false, false);
	}
}

public void ConfigureMode() {
	if (headshot == true) {
		SetConVarInt(FindConVar("mp_damage_headshot_only"), 1, false, false);
	}
}