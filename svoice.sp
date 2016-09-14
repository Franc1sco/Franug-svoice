#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <voiceannounce_ex>

Handle timers[MAXPLAYERS + 1];
bool speaking[MAXPLAYERS + 1];
int pun[MAXPLAYERS + 1];
char reason2[MAXPLAYERS + 1][128];
int selected[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "SM svoice",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart() 
{
	RegAdminCmd("sm_svoice", DID, ADMFLAG_GENERIC);
	
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
	timers[client] = CreateTimer(5.0, end, client);
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
		AddMenuItem(menu, "Mic spam", "Mic spam");
		AddMenuItem(menu, "Racism", "Racism");
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
		AddMenuItem(menu, "10", "10 min");
		AddMenuItem(menu, "30", "30 min");
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