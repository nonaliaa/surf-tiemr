#include <sdktools>

#pragma semicolon 1
#pragma newdecls required 

// the "libraries" are where we store all the information for savelocing.
float g_fvelocity_library[1001][3];
float g_fOrigin_library[1001][3];
float g_fEyeAngle_library[1001][3];

// the current number of savelocs on the server, this is used to teleport people to the right saveloc
int g_isaveloc_number = 0;
// the last used, or last created saveloc for a user
int g_irelevant_saveloc[MAXPLAYERS + 1];





public Action Command_saveloc(int client, int args)
{
	g_isaveloc_number++;
	switch (g_isaveloc_number)
	{
		case 998:
		{
			PrintToChat(client, "you're getting close to the saveloc limit!! the limit is 1000");
		}
		case 1001:
		{
			PrintToChat(client, "too many savelocs! savelocs have been reset.");
			g_isaveloc_number = 0;
			
			return Plugin_Handled;
		}
	}
	g_irelevant_saveloc[client] = g_isaveloc_number;
	
	float velocity[3];
	float eyeangles[3];
	float origin[3];
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, eyeangles);
	
	g_fvelocity_library[g_isaveloc_number] = velocity;
	g_fOrigin_library[g_isaveloc_number] = origin;
	g_fEyeAngle_library[g_isaveloc_number] = eyeangles;
	
	PrintToChat(client, "created saveloc #%d", g_isaveloc_number);
	
	
	return Plugin_Handled;
}


public Action Command_tele(int client, int args)
{
	if (g_isaveloc_number == 0) // if there are no savelocs made, make it so people can't teleport... you might end up in the void if you delete this!!
	{
		PrintToChat(client, "there are no savelocs to tele to. sm_saveloc to create one!");
		return Plugin_Handled;
	}
	else {
		if (args < 1)
		{
			TeleportEntity(client, g_fOrigin_library[g_irelevant_saveloc[client]], g_fEyeAngle_library[g_irelevant_saveloc[client]], g_fvelocity_library[g_irelevant_saveloc[client]]);
			return Plugin_Handled;
		}
		if (args > 0)
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			int tele_arg = StringToInt(arg1);
			
			if (tele_arg > g_isaveloc_number)
			{
				PrintToChat(client, "saveloc number %d does not exist!", tele_arg);
				return Plugin_Handled;
			}
			g_irelevant_saveloc[client] = tele_arg;
			
			TeleportEntity(client, g_fOrigin_library[tele_arg], g_fEyeAngle_library[tele_arg], g_fvelocity_library[tele_arg]);
			
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}