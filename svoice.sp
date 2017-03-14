/*  SM svoice
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <voiceannounce_ex>

Handle timers[MAXPLAYERS + 1];
bool speaking[MAXPLAYERS + 1];
int pun[MAXPLAYERS + 1];
char reason2[MAXPLAYERS + 1][128];
int selected[MAXPLAYERS + 1];
Handle cvar_time;
float g_time;


#define PLUGIN_VERSION	 "1.3"

public Plugin:myinfo =
{
	name = "SM svoice",
	author = "Franc1sco franug",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart() 
{
	CreateConVar("sm_svoice_version", PLUGIN_VERSION, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_svoice", DID, ADMFLAG_GENERIC);
	
	cvar_time = CreateConVar("sm_svoice_time", "5.0", "the last X seconds talking for appear in the menu");
	g_time = GetConVarFloat(cvar_time);
	
	HookConVarChange(cvar_time, CVarChange);
	
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	g_time = StringToFloat(newValue);
}

public OnClientDisconnect(client)
{
	if (timers[client] != INVALID_HANDLE)
	{
		KillTimer(timers[client]);
		timers[client] = INVALID_HANDLE;
	}
	speaking[client] = false;
}

public OnClientSpeakingEx(client)
{
	speaking[client] = true;
	if (timers[client] != INVALID_HANDLE)
	{
		KillTimer(timers[client]);
		timers[client] = INVALID_HANDLE;
	}
}

public OnClientSpeakingEnd(client)
{
	if (timers[client] != INVALID_HANDLE)
	{
		KillTimer(timers[client]);
		timers[client] = INVALID_HANDLE;
	}
	timers[client] = CreateTimer(g_time, end, client);
}

public Action end(Handle timer, any client)
{
	timers[client] = INVALID_HANDLE;
	speaking[client] = false;
}

public Action:DID(clientId, args) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "Select a client");
	decl String:sName[MAX_NAME_LENGTH], String:sUserId[10];
	for(new i=1;i<=MaxClients;i++)
	{
    	if(IsClientInGame(i) && speaking[i] && GetUserAdmin(i) == INVALID_ADMIN_ID)
    	{
        	GetClientName(i, sName, sizeof(sName));
        	IntToString(GetClientUserId(i), sUserId, sizeof(sUserId));
        	AddMenuItem(menu, sUserId, sName);
    	}
	} 
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 0);
	
	return Plugin_Handled;
}

public DIDMenuHandler(Handle:menu2, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];
		
		GetMenuItem(menu2, itemNum, info, sizeof(info));

		selected[client] = StringToInt(info);
		
		int clientt = GetClientOfUserId(selected[client]);
		if(clientt == 0)
		{
			PrintToChat(client, "client not ingame");
			return;
		}
		
		new Handle:menu = CreateMenu(DIDMenuHandler2);
		SetMenuTitle(menu, "Select a punishment for %N", clientt);
		AddMenuItem(menu, "1", "Mute");
		AddMenuItem(menu, "2", "Silence");
		if(GetUserFlagBits(client) & ADMFLAG_BAN) AddMenuItem(menu, "3", "Ban");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 0);
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
}

public DIDMenuHandler2(Handle:menu2, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		
		new String:info[32];
		
		GetMenuItem(menu2, itemNum, info, sizeof(info));

		pun[client] = StringToInt(info);
		
		int clientt = GetClientOfUserId(selected[client]);
		if(clientt == 0)
		{
			PrintToChat(client, "client not ingame");
			return;
		}
		new Handle:menu = CreateMenu(DIDMenuHandler3);
		SetMenuTitle(menu, "Select a reason for %N", clientt);
		// basebans reasons
		AddMenuItem(menu, "Abusive",			"Abusive");
		AddMenuItem(menu, "Racism",			"Racism");
		AddMenuItem(menu, "General cheating/exploits",	"General cheating/exploits");
		AddMenuItem(menu, "Wallhack",			"Wallhack");
		AddMenuItem(menu, "Aimbot",			"Aimbot");
		AddMenuItem(menu, "Speedhacking",			"Speedhacking");
		AddMenuItem(menu, "Mic spamming",			"Mic spamming");
		AddMenuItem(menu, "Admin disrespect",		"Admin disrespect");
		AddMenuItem(menu, "Camping",			"Camping");
		AddMenuItem(menu, "Team killing",			"Team killing");
		AddMenuItem(menu, "Unacceptable Spray",		"Unacceptable Spray");
		AddMenuItem(menu, "Breaking Server Rules",		"Breaking Server Rules");
		AddMenuItem(menu, "Other",				"Other");
		//
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 0);
		
		
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
}

public DIDMenuHandler3(Handle:menu2, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		
		new String:info[32];
		
		GetMenuItem(menu2, itemNum, info, sizeof(info));

		strcopy(reason2[client], 128, info);
		
		int clientt = GetClientOfUserId(selected[client]);
		if(clientt == 0)
		{
			PrintToChat(client, "client not ingame");
			return;
		}
		new Handle:menu = CreateMenu(DIDMenuHandler4);
		SetMenuTitle(menu, "Select time for %N", clientt);
		// basebans time
		AddMenuItem(menu, "0", "Permanent");
		AddMenuItem(menu, "10", "10 Minutes");
		AddMenuItem(menu, "30", "30 Minutes");
		AddMenuItem(menu, "60", "1 Hour");
		AddMenuItem(menu, "240", "4 Hours");
		AddMenuItem(menu, "1440", "1 Day");
		AddMenuItem(menu, "10080", "1 Week");
		//
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 0);
		
		
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
}

public DIDMenuHandler4(Handle:menu2, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		
		new String:info[32];
		
		GetMenuItem(menu2, itemNum, info, sizeof(info));

		int time = StringToInt(info);
		
		int clientt = GetClientOfUserId(selected[client]);
		if(clientt == 0)
		{
			PrintToChat(client, "client not ingame");
			return;
		}
		
		if(pun[client] == 3) FakeClientCommand(client, "sm_ban #%i %i %s", selected[client], time, reason2[client]);
		else if (pun[client] == 2)FakeClientCommand(client, "sm_silence #%i %i %s", selected[client], time, reason2[client]);
		else if(pun[client] == 1)FakeClientCommand(client, "sm_mute #%i %i %s", selected[client], time, reason2[client]);
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu2);
	}
}