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
bool knife = false;

char startDM[64];

int secondsLeft = 3;
public void OnPluginStart()
{
	RegConsoleCmd("enabledm", DM_Enable);
	RegConsoleCmd("disabledm", DM_Disable);
	RegConsoleCmd("ayudadm", DM_Help);
	HookEvent("round_end", Event_OnRoundEnd);
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/deathmatch/blip.mp3");
	PrecacheSound("*/deathmatch/blip.mp3");
}

public void OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, DamageController);
	SDKHook(client, SDKHook_TraceAttack, HeadshotController);
}
public void OnEntityCreated(entity, const String:Classname[]) {
	if ((StrEqual(Classname, "hegrenade_projectile") || StrEqual(Classname, "decoy_projectile")) && deathmatch && (StrEqual(startDM, "HE Grenade") || StrEqual(startDM, "Dodgeball"))) {
        SDKHook(entity, SDKHook_SpawnPost, OnThrowGrenade);
	}
}

public void OnThrowGrenade(entity) {
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsPlayerAlive(client) && clientOnZone[client] == true && deathmatch && GetClientTeam(client) == 2) {
		CreateTimer(1.0, GiveGrenade, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:GiveGrenade(Handle timer, int entity) {
	int entity1 = EntRefToEntIndex(entity);
	int client = GetEntPropEnt(entity1, Prop_Data, "m_hOwnerEntity");
	if (client == -1 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	if (clientOnZone[client] == true && deathmatch && GetClientTeam(client) == 2 && StrEqual(startDM, "HE Grenade")) {
		GivePlayerItem(client, "weapon_hegrenade");
	} else if (clientOnZone[client] == true && deathmatch && GetClientTeam(client) == 2 && StrEqual(startDM, "Dodgeball")) {
		SetEntProp(entity1, Prop_Data, "m_nNextThinkTick", -1);
		GivePlayerItem(client, "weapon_decoy");
		CreateTimer(5.0, RemoveDecoy, EntIndexToEntRef(entity1), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:RemoveDecoy(Handle timer, int entity) {
	int entity1 = EntRefToEntIndex(entity);
	AcceptEntityInput(entity1, "Kill");
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	SetConVarInt(FindConVar("mp_teammates_are_enemies"), 0, false, false);
	for (int i; i < MAXPLAYERS; i++) {
		clientOnZone[i] = false;
	}
	deathmatch = false;
	headshot = false;
}

public Action:HeadshotController(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup) {
	if (deathmatch && headshot && clientOnZone[victim] == true && clientOnZone[attacker] == true && GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2) {
		if (hitgroup != 1) {
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if (!deathmatch) {
		return Plugin_Continue;
	} else {
		if ((GetClientHealth(victim) - damage) <= 0 && clientOnZone[victim]) {
			if (GetPlayerWeaponSlot(victim, 0) != -1) {
				RemovePlayerItem(victim, GetPlayerWeaponSlot(victim, 0));
			}
			if (GetPlayerWeaponSlot(victim, 1) != -1) {
				RemovePlayerItem(victim, GetPlayerWeaponSlot(victim, 1));
			}
		}
		return Plugin_Continue;
	}
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
			if (IsClientInGame(client) && (!IsFakeClient(client)) && IsPlayerAlive(client) && GetClientTeam(client)==2) {
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

public Action DM_Help(int client, int args) {
	if ((CheckCommandAccess(client, "sm_asd", ADMFLAG_CUSTOM1) && CheckCommandAccess(client, "sm_asd", ADMFLAG_CUSTOM5)) || CheckCommandAccess(client, "sm_asd", ADMFLAG_CHANGEMAP)) {
		PrintToChat(client, "!zones -> Permite crear/borrar una zona");
		PrintToChat(client, "!enabledm -> Permite seleccionar el modo de juego y el arma. Activa el DM");
		PrintToChat(client, "!disabledm-> Desactiva el DM y retira las armas a los terroristas");
	} else {
		PrintToChat(client, "You must be Supporter to use this command");
	}
}

public Action DM_Enable(int client, int args) {
	if ((CheckCommandAccess(client, "sm_asd", ADMFLAG_CUSTOM1) && CheckCommandAccess(client, "sm_asd", ADMFLAG_CUSTOM5)) || CheckCommandAccess(client, "sm_asd", ADMFLAG_CHANGEMAP)) {
		if (GetClientTeam(client)!=3) {
			PrintToChat(client, "You must be CT to use this command");
		} else if (GetClientTeam(client) == 3 && !IsPlayerAlive(client)) {
			PrintToChat(client, "You must be alive to use this command");
		} else {
			Menu menu = new Menu(MenuHandler_Mode, MenuAction_Start | MenuAction_Select | MenuAction_Cancel | MenuAction_End);
			menu.SetTitle("Select DM mode:");
			menu.AddItem("Headshot", "Headshot");
			menu.AddItem("Normal", "Normal");
			menu.AddItem("HE Grenade", "HE Grenade");
			menu.AddItem("Dodgeball", "Dodgeball");
			menu.Display(client, 20);
		}
	} else {
		PrintToChat(client, "You must be Supporter to use this command");
	} 
	return Plugin_Handled;
}

public void ChooseWeapon(int client) {
	Menu menu = new Menu(MenuHandler_Weapon, MenuAction_Start | MenuAction_Select | MenuAction_Cancel | MenuAction_End);
	menu.SetTitle("Select weapon for the DM:");
	menu.AddItem("Scout", "Scout");
	menu.AddItem("AWP", "AWP");
	menu.AddItem("USP", "USP");
	menu.AddItem("Desert Eagle", "Desert Eagle");
	menu.AddItem("Knife", "Knife");
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
		} else if (StrEqual(info, "HE Grenade")) {
			menu.GetItem(param2, startDM, sizeof(startDM));
			CreateTimer(1.0, Timer_WaitForDM, _, TIMER_REPEAT);
		} else if (StrEqual(info, "Dodgeball")) {
			menu.GetItem(param2, startDM, sizeof(startDM));
			CreateTimer(1.0, Timer_WaitForDM, _, TIMER_REPEAT);
		}
	}
	return 0;
}

public Action Timer_WaitForDM (Handle timer) {
	if (secondsLeft <= 0) {
		secondsLeft = 3;
		SetConVarInt(FindConVar("mp_teammates_are_enemies"), 1, false, false);
		deathmatch = true;
		for (int i = 0; i < MAXPLAYERS; i++) {
			if (clientOnZone[i] && GetClientTeam(i)==2) {
				if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i)) {
					if (StrEqual(startDM, "Knife")) {
						if (GetPlayerWeaponSlot(i, 0) != -1) {
							RemovePlayerItem(i, GetPlayerWeaponSlot(i, 0));
						}
						if (GetPlayerWeaponSlot(i, 1) != -1) {
							RemovePlayerItem(i, GetPlayerWeaponSlot(i, 1));
						}
						if (GetPlayerWeaponSlot(i, 4) != -1) {
							RemovePlayerItem(i, GetPlayerWeaponSlot(i, 4));
						}
						knife = true;
						GivePlayerItem(i, "weapon_knife");	
					} else if (StrEqual(startDM, "HE Grenade")) {
						RemoveWeapons(i);
						GivePlayerItem(i, "weapon_hegrenade");
					} else if (StrEqual(startDM, "Dodgeball")) {
						RemoveWeapons(i);
						SetEntityHealth(i, 1);
						GivePlayerItem(i, "weapon_decoy");
					} else {
						knife = false;
						RemoveWeapons(i);
						if (StrEqual(startDM, "USP")) {
							GivePlayerItem(i, "weapon_usp_silencer");
						} else if (StrEqual(startDM, "Desert Eagle")){
							GivePlayerItem(i, "weapon_deagle");
						} else if(StrEqual(startDM, "AWP")) {
							GivePlayerItem(i, "weapon_awp");
						} else if(StrEqual(startDM, "Scout")) {
							GivePlayerItem(i, "weapon_ssg08");
						}
					}	
				}
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		return Plugin_Stop;
	}
	PrintHintTextToAll("DM starts in %i", secondsLeft);
	EmitSoundToAll("*/deathmatch/blip.mp3");
	secondsLeft = secondsLeft - 1;
	return Plugin_Continue;
}

public int MenuHandler_Weapon(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		menu.GetItem(param2, startDM, sizeof(startDM));
		CreateTimer(1.0, Timer_WaitForDM, _, TIMER_REPEAT);
	}
}

public void RemoveWeapons(int client) {
	if (GetPlayerWeaponSlot(client, 0) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
	}
	if (GetPlayerWeaponSlot(client, 1) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	}
	if (GetPlayerWeaponSlot(client, 2) != -1 && knife == false) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 2));
	}
	if (GetPlayerWeaponSlot(client, 3) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
	}
	if (GetPlayerWeaponSlot(client, 4) != -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 4));
	}
}

public Action DM_Disable(int client, int args) {
	if ((CheckCommandAccess(client, "sm_asd", ADMFLAG_CUSTOM1) && CheckCommandAccess(client, "sm_asd", ADMFLAG_CUSTOM5)) || CheckCommandAccess(client, "sm_asd", ADMFLAG_CHANGEMAP)) {
		if (!deathmatch) {
			PrintToChat(client, "Deathmatch isn't enabled");
		} else if (GetClientTeam(client)!=3) {
			PrintToChat(client, "You must be CT to use this command");
		} else {
			SetConVarInt(FindConVar("mp_teammates_are_enemies"), 0, false, false);
			deathmatch = false;
			headshot = false;
			for (int i = 0; i < MAXPLAYERS; i++) {
				if (clientOnZone[i] && GetClientTeam(i) == 2) {
					if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i)) {
						RemoveWeapons(i);
						GivePlayerItem(i, "weapon_knife");
					}
				}
			}
			knife = false;
		}
	} else {
		PrintToChat(client, "You must be Supporter to use this command");
	}
}