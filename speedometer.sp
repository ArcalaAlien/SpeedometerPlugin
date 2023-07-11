#include<sourcemod>

bool g_bIsEnabled[MAXPLAYERS+1] = { true, ... };
bool g_bIsPlayerAlive[MAXPLAYERS+1];
Handle g_hSpeedometerTimer[MAXPLAYERS+1];
Handle g_hMessageHandles[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Speedometer",
	author = "Arcala the Gyiyg",
	description = "Plugin that shows a player's speed.",
	version = "1.0.0",
	url = "N/A"
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("sm_speedometer.phrases");
    RegConsoleCmd("sm_speedometer", ToggleSpeedometer, "Toggles the Speedometer On or Off");
    HookEvent("player_death", Event_OnPlayerDeath);
    HookEvent("player_spawn", Event_OnPlayerSpawn);
    HookEvent("player_team", Event_OnPlayerTeam);
}

public Action ToggleSpeedometer(int client, int args)
{
    if (args > 0) {
        ReplyToCommand(client, "[SM] Usage: sm_speedometer")
        return Plugin_Handled;
    }
    
    g_bIsEnabled[client] = !g_bIsEnabled[client];
    if (g_bIsEnabled[client] && IsPlayerAlive(client)) 
    {
        ReplyToCommand(client, "[SM]: The speedometer has been enabled");
        g_hSpeedometerTimer[client] = CreateTimer(0.1, Speedometer_Timer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
    else if (!g_bIsEnabled[client]) 
    {
        delete g_hSpeedometerTimer[client];
        ReplyToCommand(client, "[SM]: The speedometer has been disabled");
    }
    return Plugin_Handled;
}

/**
 * @brief Event_OnPlayerDeath
 * 
 * @param event Event identifier for the event
 * @param name Name of event
 * @param dontBroadcast 
 */
public Action Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_bIsPlayerAlive[client] = false;
    if (g_bIsEnabled[client])
    {
        delete g_hSpeedometerTimer[client];
    }
    return Plugin_Continue;
}


/**
 * @brief Event_OnPlayerSpawn
 * 
 * @param event Event identifier for the event
 * @param name N???
 * @param dontBroadcast
 * 
 */
public Action Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (g_bIsEnabled[client] && IsPlayerAlive(client))
    {
        g_hSpeedometerTimer[client] = CreateTimer(0.1, Speedometer_Timer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Continue;
}



/**
 * @brief Event_OnPlayerTeam
 * 
 * @param event Event identifier for the event
 * @param name N??
 * @param dontBroadcast
 */
public Action Event_OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_bIsPlayerAlive[client] = false;
    if (g_bIsEnabled[client])
    {
        delete g_hSpeedometerTimer[client];
    }
    return Plugin_Continue;
}

public Action Speedometer_Timer(Handle timer, any client)
{
    if (g_bIsPlayerAlive[client] || g_bIsEnabled[client])
    {
        // Thanks to TheTwistedPanda for this code:
        float _fTemp[3];
        float _fVelocity;
        //get proper vector and calculate velocity
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", _fTemp);
        for(new i = 0; i <= 2; i++)
        {
            _fTemp[i] *= _fTemp[i];
        }
        _fVelocity = SquareRoot(_fTemp[0] + _fTemp[1] + _fTemp[2]);
        
        //display the speed
        char sBuffer[128];
        Format(sBuffer, sizeof(sBuffer), "%T", "SPEEDOMETER_VELOCITY", client, _fVelocity);
        g_hMessageHandles[client] = StartMessageOne("KeyHintText", client);
        BfWriteByte(g_hMessageHandles[client], client); 
        BfWriteString(g_hMessageHandles[client], sBuffer); 
        EndMessage();
        return Plugin_Continue;
    }
    else if (!g_bIsPlayerAlive[client] || !g_bIsEnabled[client] || !IsClientConnected(client))
    {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public void onClientDisconnect(int client)
{
    g_bIsEnabled[client] = false;
    delete g_hSpeedometerTimer[client];
    delete g_hMessageHandles[client];
}