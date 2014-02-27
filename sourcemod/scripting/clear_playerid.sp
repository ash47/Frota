#include <sourcemod>
#include <sdktools>

const MAX_PLAYER_IDS = 32

public OnPluginStart()
{
    RegServerCmd("clear_playerid", clear_playerid)
}

public Action:clear_playerid(argc)
{
    if (argc != 1)
    {
        PrintToServer("clear_playerid <playerid>")
        return Plugin_Handled
    }

    new String:buffer[32]
    GetCmdArg(1, buffer, sizeof(buffer))

    PrintToServer("clearing player: ")
    PrintToServer(buffer)

    new playerId = StringToInt(buffer)
    if (playerId < 0 || playerId >= MAX_PLAYER_IDS)
    {
        PrintToServer("clear_playerid <playerid>")
        return Plugin_Handled
    }

    new ent = GetPlayerResourceEntity()
    new offs = FindSendPropInfo("CDOTA_PlayerResource", "m_iPlayerSteamIDs")

    SetEntData(ent, offs + 8*playerId, 0, 4, true)
    SetEntData(ent, offs + 8*playerId + 4, 0, 4, true)

    return Plugin_Handled
}