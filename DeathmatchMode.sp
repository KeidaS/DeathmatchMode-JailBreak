#pragma semicolon 1


#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <devzones>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "DeathmatchModeJailBreak",
	author = "KeidaS",
	description = "Enables Deathmatch with teammates",
	version = "1.0",
	url = "www.hermandadfenix.es"
};

bool headshot = false;
public void OnPluginStart()
{
	RegConsoleCmd("enabledm", DM_Enable);
	RegConsoleCmd("disabledm", DM_Disable);
}

public Action DM_Enable (int client, int args) {
	Menu menu = new Menu(MenuHandler_Mode, MenuAction_Start | MenuAction_Select | MenuAction_Cancel | MenuAction_End);
	menu.SetTitle("Select DM mode:");
	menu.AddItem("Headshot", "Headshot");
	menu.AddItem("Normal", "Normal");
	menu.Display(client, 20);
	
	return Plugin_Handled;
}

public void ChooseWeapon (int client) {
	Menu menu = new Menu(MenuHandler_Weapon, MenuAction_Start | MenuAction_Select | MenuAction_Cancel | MenuAction_End);
	menu.SetTitle("Select weapon for the DM:");
	menu.AddItem("USP", "USP");
	menu.AddItem("Desert Eagle", "Desert Eagle");
	menu.Display(client, 20);
}

public int MenuHandler_Mode (Menu menu, MenuAction action, int param1, int param2) {
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
public int MenuHandler_Weapon (Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		char info[64];
		menu.GetItem(param2, info, sizeof(info));
		ConfigureMode();
		SetConVarInt(FindConVar("mp_teammates_are_enemies"), 1, false, true);
		int i;
		for (i = 0; i < MAXPLAYERS; i++) {
			PrintToChatAll("%i", MAXPLAYERS);
			PrintToChatAll("%i", i);
			if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i)) {
				if (StrEqual(info, "USP")) {
					GivePlayerItem(i, "weapon_usp_silencer");
					PrintToChatAll("USP");
				} else {
					GivePlayerItem(i, "weapon_deagle");
					PrintToChatAll("Desert");
				}
			}
		}
	}
}

public Action DM_Disable (int client, int args) {
	PrintToChatAll("DM Disabled");
	SetConVarInt(FindConVar("mp_teammates_are_enemies"), 0, false, true);
	SetConVarInt(FindConVar("mp_damage_headshot_only"), 0, true, true);
}

public void ConfigureMode () {
	if (headshot == true) {
		SetConVarInt(FindConVar("mp_damage_headshot_only"), 1, true, true);
	}
}

public Zone_OnClientEntry(client, String:zone[]) {
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return;
 	} else {
 		PrintToChatAll("You entered the zone haptagu");
	}
}