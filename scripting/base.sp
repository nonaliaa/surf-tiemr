#include <clientprefs>
#include <sdktools>
#include <sourcemod>
#include <events>
#include "surftimer/saveloc.sp"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION ""

public Plugin myinfo = {
	name = "(something) timer. (name pending)", 
	author = "mnonolalia, roby", 
	description = "work in progress surftimer.", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/nonaliaa/surf-tiemr" };

// cool function to check if client is valid, or client index does not equal 0 in other words. (not a bot, gotv, or server console for example).
stock bool is_valid_client(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client) && !IsClientSourceTV(client));
}

//setting up bools for later.
bool toggle_speed[MAXPLAYERS + 1] = { true, ... };
bool toggle_bhop[MAXPLAYERS + 1] = { true, ... };
bool toggle_speedtype[MAXPLAYERS + 1] = { true, ... };
bool toggle_godmode[MAXPLAYERS + 1] = { true, ... };

float g_fVelocity[3];



// these are handles for our cookies, just think of these as the cookies themselves.
Handle g_hToggle_Bhop_preference;
Handle g_htoggle_speed_preference;
Handle g_hSpeedtype_preference;
Handle g_hGodmode_preference;

bool cookiebuffer_speedometer[MAXPLAYERS + 1];
bool cookiebuffer_bhop[MAXPLAYERS + 1];
bool cookiebuffer_speed_type[MAXPLAYERS + 1];
bool cookiebuffer_godmode[MAXPLAYERS + 1];

Menu g_menu;


public void OnPluginStart()
{
	CreateConVar("sm_pluginnamehere_version", PLUGIN_VERSION, "Standard plugin version ConVar. Please don't change me!", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	// where we declare actual server cmds. if you wanna find the code for them they're all declared after line 108.
	RegConsoleCmd("sm_speed", Command_Speed, "basic speed");
	RegConsoleCmd("sm_bhop", Command_autobhop, "toggle bhopping");
	RegConsoleCmd("sm_speedtype", Command_speedtype, "toggle speedtype");
	RegConsoleCmd("sm_god", Command_God, "toggle godmode");
	RegConsoleCmd("sm_saveloc", Command_saveloc, "a command that creates a \"saveloc\" or checkpoint the client can teleport to with sm_tele");
	RegConsoleCmd("sm_tele", Command_tele, "a command to teleport to a \"saveloc\" or checkpoint the client has made.");
	
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	// here are cookies, these store client preferences even after they leave or the server restarts.
	// we have to use a handle for cookies because sourcemod I guess.
	g_hToggle_Bhop_preference = RegClientCookie("cookie_bhopvalue", "stores preference for whether or not autobhop is enabled by default.", CookieAccess_Public);
	g_htoggle_speed_preference = RegClientCookie("cookie_speedometervalue", "stores preference for whether or not the speedometer is enabled by default,", CookieAccess_Public);
	g_hSpeedtype_preference = RegClientCookie("cookie_speedtypepref", "stores preference for whether or not client prefers xyz or xy speedtype", CookieAccess_Public);
	g_hGodmode_preference = RegClientCookie("cookie_goodmode_pref", "stores preference for whether or not client wants godmode", CookieAccess_Public);
	
	//initialize a menu cause it might be better to do it here than have it be created by every player whenever tf they use the command
	CreateSettingsMenu();
	
	
	RegConsoleCmd("sm_menu", Command_menu, "displays a settings menu");
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	for (int i = 1; i < MaxClients + 1; i++) {
		switch (toggle_godmode[i]) {
			case true:
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		}
	}
}

public void OnMapStart()
{
	// incredibly important if you like your speedometer working.
	
	CreateTimer(0.001, timer_getvel, _, TIMER_REPEAT);
	
	g_isaveloc_number = 0; // resets savelocs
	
	
}


public void OnClientCookiesCached(int client)
{
	// if you have a hard time understanding this part, I do too.
	
	//this are the buffers we use in GetClientCookie which we use to change client settings
	char tempbhopValue[8];
	char tempspeedometervalue[8];
	char tempspeedtypevalue[8];
	char tempgodmodevalue[8];
	
	//here we store client cookies into the buffers we made
	GetClientCookie(client, g_hToggle_Bhop_preference, tempbhopValue, sizeof(tempbhopValue));
	GetClientCookie(client, g_htoggle_speed_preference, tempspeedometervalue, sizeof(tempspeedometervalue));
	GetClientCookie(client, g_hSpeedtype_preference, tempspeedtypevalue, sizeof(tempspeedtypevalue));
	GetClientCookie(client, g_hGodmode_preference, tempgodmodevalue, sizeof(tempgodmodevalue));
	
	//here we put the buffers into other buffers (but bools this time!!). 
	//this may seem inefficient and I completely agree, but cookies don't store properly unless you do this
	cookiebuffer_bhop[client] = (tempbhopValue[0] != '\0' && StringToInt(tempbhopValue));
	cookiebuffer_speedometer[client] = (tempspeedometervalue[0] != '\0' && StringToInt(tempspeedometervalue));
	cookiebuffer_speed_type[client] = (tempspeedtypevalue[0] != '\0' && StringToInt(tempspeedtypevalue));
	cookiebuffer_godmode[client] = (tempgodmodevalue[0] != '\0' && StringToInt(tempgodmodevalue));
	
	//this is where we actually change the client's in game settings to what their cookies said their preference is
	toggle_bhop[client] = cookiebuffer_bhop[client];
	toggle_speed[client] = cookiebuffer_speedometer[client];
	toggle_speedtype[client] = cookiebuffer_speed_type[client];
	toggle_godmode[client] = cookiebuffer_godmode[client];
	
}


public Action OnPlayerRunCmd(int client, int &buttons, int &inpulse, float[3] vel, float[3] angles)
{
	switch (toggle_bhop[client] == true && IsPlayerAlive(client) && (buttons & IN_JUMP) && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		case true:
		buttons &= ~IN_JUMP;
	}
}


public Action Command_God(int client, int args) 
{
	toggle_godmode[client] = !toggle_godmode[client];
	PrintToChat(client, "godmode %s", toggle_godmode[client] ? "enabled":"disabled");
	
	switch (toggle_godmode[client] == true && IsPlayerAlive(client))
	{
		case true:
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		case false:
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1); // was hoping I could make it so the client is mortal immediately after they disable godmode but it didn't work.
	}
}


public Action Command_Speed(int client, int args)
{
	
	// usage will toggle on | off:  sm_speed
	
	if (is_valid_client(client) == false) //check to make sure the client is real so things where we pass client index don't break
		return Plugin_Handled;
	
	
	toggle_speed[client] = !toggle_speed[client]; // this is how we toggle our bools
	PrintToChat(client, "You have %s speed hud thingy", toggle_speed[client] ? "enabled" : "disabled");
	
	SetClientCookie(client, g_htoggle_speed_preference, toggle_speed[client] ? "1":"0");
	
	
	return Plugin_Handled;
}


public Action Command_speedtype(int client, int args)
{
	if (is_valid_client(client) == false)
		return Plugin_Handled;
	
	toggle_speedtype[client] = !toggle_speedtype[client];
	PrintToChat(client, "Your speed type is now %s", toggle_speedtype[client] ? "xyz" : "xy");
	
	SetClientCookie(client, g_hSpeedtype_preference, toggle_speedtype[client] ? "1":"0");
	
	return Plugin_Handled;
}

public Action Command_autobhop(int client, int args)
{
	if (is_valid_client(client) == false)
		return Plugin_Handled;
	
	toggle_bhop[client] = !toggle_bhop[client];
	PrintToChat(client, "you have %s auto bhop :3", toggle_bhop[client] ? "enabled" : "disabled");
	
	SetClientCookie(client, g_hToggle_Bhop_preference, toggle_bhop[client] ? "1":"0");
	
	return Plugin_Handled;
}

// this is the thing that works ur speedometer
public Action timer_getvel(Handle timer)
{
	// loop all clients from server! this is for when we can't pass client as an argument in our functions
	for (int i = 1; i < MaxClients + 1; i++)
	{
		// if client is NOT valid OR if they don't have hud activated, skip them
		if (is_valid_client(i) == false || !toggle_speed[i])
			continue;
		
		switch (toggle_speedtype[i])
		{
			case true:
			{
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", g_fVelocity);
				float fSpeed = GetVectorLength(g_fVelocity, false); // this shows speed on the x, y and z axis
				PrintCenterText(i, "%.0f u/s", fSpeed);
			}
			case false:
			{
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", g_fVelocity);
				float aSpeed = SquareRoot(Pow(g_fVelocity[0], 2.0) + Pow(g_fVelocity[1], 2.0)); // this shows speed on the x and y axis
				PrintCenterText(i, "%.0f u/s", aSpeed);
			}
		}
	}
}


public Action Command_menu(int client, int args) 
{
	g_menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

// handler for menu "g_menu", this is where the code for it items is stored.
public int Command_menu_handler(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action) {
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					toggle_godmode[param1] = !toggle_godmode[param1];
					
					SetClientCookie(param1, g_hGodmode_preference, toggle_godmode[param1] ? "1":"0");
					menu.DisplayAt(param1, menu.Selection, MENU_TIME_FOREVER);
				}
				
				
				case 1:
				{
					toggle_bhop[param1] = !toggle_bhop[param1];
					
					SetClientCookie(param1, g_hToggle_Bhop_preference, toggle_bhop[param1] ? "1":"0");
					menu.DisplayAt(param1, menu.Selection, MENU_TIME_FOREVER);
					
					
				}
				case 2:
				{
					toggle_speed[param1] = !toggle_speed[param1];
					
					SetClientCookie(param1, g_htoggle_speed_preference, toggle_speed[param1] ? "1":"0");
					menu.DisplayAt(param1, menu.Selection, MENU_TIME_FOREVER);
					
					
					
				}
				case 3:
				{
					toggle_speedtype[param1] = !toggle_speedtype[param1];
					
					SetClientCookie(param1, g_hSpeedtype_preference, toggle_speedtype[param1] ? "1":"0");
					menu.DisplayAt(param1, menu.Selection, MENU_TIME_FOREVER);
				}
			}
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32], display[32];
			menu.GetItem(param2, info, sizeof(info), _, display, sizeof(display));
			
			switch (param2)
			{
				case 0:
				{
					StrCat(display, sizeof(display), toggle_godmode[param1] ? " [enabled]" : " [disabled]");
					return RedrawMenuItem(display);
				}
				case 1:
				{
					StrCat(display, sizeof(display), toggle_bhop[param1] ? " [enabled]" : " [disabled]");
					return RedrawMenuItem(display);
				}
				case 2:
				{
					StrCat(display, sizeof(display), toggle_speed[param1] ? " [enabled]" : " [disabled]");
					return RedrawMenuItem(display);
				}
				case 3:
				{
					StrCat(display, sizeof(display), toggle_speedtype[param1] ? " [xyz]" : " [xy]");
					return RedrawMenuItem(display);
				}
			}
			return RedrawMenuItem(display);
		}
	}
	return 0;
}

// used to create the menu "g_menu".
int CreateSettingsMenu()
{
	g_menu = new Menu(Command_menu_handler, MenuAction_DisplayItem);
	g_menu.SetTitle("settings menu!");
	g_menu.AddItem("", "god mode");
	g_menu.AddItem("", "autobhop");
	g_menu.AddItem("", "speedometer");
	g_menu.AddItem("", "speed type");
}
