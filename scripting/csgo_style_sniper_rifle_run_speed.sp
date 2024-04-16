#include <sourcemod>
#include <sdktools>

#define REQUIRE_EXTENSIONS
#include <dhooks>

#define GAMEDATA_FILE   "csgo_style_sniper_rifle_run_speed"

#define TEAM_SURVIVOR   2

// https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/imovehelper.h#L33-L39
enum
{
    WL_NotInWater = 0,
    WL_Feet,
    WL_Waist,
    WL_Eyes
};

Handle g_hSDKCall_CTerrorPlayer_IsZoomed = null;
Handle g_hSDKCall_CCSPlayer_GetHealthBuffer = null;

ConVar survivor_awp_run_speed = null;
ConVar survivor_sniper_rifle_run_speed = null;
ConVar survivor_hunting_rifle_run_speed = null;
ConVar survivor_limp_health = null;

bool CTerrorPlayer_IsZoomed( int iClient )
{
    return SDKCall( g_hSDKCall_CTerrorPlayer_IsZoomed, iClient );
}

float CCSPlayer_GetHealthBuffer( int iClient )
{
    return SDKCall( g_hSDKCall_CCSPlayer_GetHealthBuffer, iClient );
}

bool PlayerRunSpeedMayBeChanged( int iClient )
{
    // Survivors already move slower when walking through water
    if ( GetEntProp( iClient, Prop_Data, "m_nWaterLevel" ) )
    {
        return false;
    }

    // Adrenaline gives a speed boost
    if ( GetEntProp( iClient, Prop_Send, "m_bAdrenalineActive", 1 ) )
    {
        return false;
    }

    // Survivors already move slower when zooming with the scope
    if ( CTerrorPlayer_IsZoomed( iClient ) )
    {
        return false;
    }

    // Survivors already move slower when their health is low
    int nTotalHealth = GetClientHealth( iClient ) + RoundFloat( CCSPlayer_GetHealthBuffer( iClient ) );
    if ( nTotalHealth < survivor_limp_health.IntValue )
    {
        return false;
    }

    return true;
}

public MRESReturn DHook_CTerrorPlayer_GetRunTopSpeed( int iClient, DHookReturn hReturn )
{
    if ( GetClientTeam( iClient ) == TEAM_SURVIVOR )
    {
        if ( !PlayerRunSpeedMayBeChanged( iClient ) )
        {
            return MRES_Ignored;
        }

        int iActiveWeapon = GetEntPropEnt( iClient, Prop_Send, "m_hActiveWeapon" );
        if ( iActiveWeapon != INVALID_ENT_REFERENCE )
        {
            char szWeaponName[64];
            GetEntityClassname( iActiveWeapon, szWeaponName, sizeof( szWeaponName ) );
            if ( StrEqual( szWeaponName, "weapon_sniper_awp" ) )
            {
                hReturn.Value = survivor_awp_run_speed.FloatValue;
                return MRES_Supercede;
            }

            if ( StrEqual( szWeaponName, "weapon_sniper_military" ) )
            {
                hReturn.Value = survivor_sniper_rifle_run_speed.FloatValue;
                return MRES_Supercede;
            }

            if ( StrEqual( szWeaponName, "weapon_hunting_rifle" ) )
            {
                hReturn.Value = survivor_hunting_rifle_run_speed.FloatValue;
                return MRES_Supercede;
            }
        }
    }

    return MRES_Ignored;
}

public void OnPluginStart()
{
    GameData hGameData = new GameData( GAMEDATA_FILE );
    if ( hGameData == null )
    {
        SetFailState( "Unable to load gamedata file \"" ... GAMEDATA_FILE ... "\"" );
    }

    StartPrepSDKCall( SDKCall_Player );
    if ( !PrepSDKCall_SetFromConf( hGameData, SDKConf_Virtual, "CTerrorPlayer::IsZoomed" ) )
    {
        delete hGameData;
        SetFailState( "Unable to find gamedata offset entry for \"CTerrorPlayer::IsZoomed\"" );
    }

    PrepSDKCall_SetReturnInfo( SDKType_Bool, SDKPass_Plain );
    g_hSDKCall_CTerrorPlayer_IsZoomed = EndPrepSDKCall();

    StartPrepSDKCall( SDKCall_Player );
    if ( !PrepSDKCall_SetFromConf( hGameData, SDKConf_Virtual, "CCSPlayer::GetHealthBuffer" ) )
    {
        delete hGameData;
        SetFailState( "Unable to find gamedata offset entry for \"CCSPlayer::GetHealthBuffer\"" );
    }

    PrepSDKCall_SetReturnInfo( SDKType_Float, SDKPass_Plain );
    g_hSDKCall_CCSPlayer_GetHealthBuffer = EndPrepSDKCall();

    DynamicDetour hDDetour_CTerrorPlayer_GetRunTopSpeed = new DynamicDetour( Address_Null, CallConv_THISCALL, ReturnType_Float, ThisPointer_CBaseEntity );
    if ( !hDDetour_CTerrorPlayer_GetRunTopSpeed.SetFromConf( hGameData, SDKConf_Signature, "CTerrorPlayer::GetRunTopSpeed" ) )
    {
        delete hGameData;
        SetFailState( "Unable to setup dynamic detour for \"CTerrorPlayer::GetRunTopSpeed\"" );
    }

    hDDetour_CTerrorPlayer_GetRunTopSpeed.Enable( Hook_Post, DHook_CTerrorPlayer_GetRunTopSpeed );
    delete hGameData;

    survivor_limp_health = FindConVar( "survivor_limp_health" );

    survivor_awp_run_speed = CreateConVar( "survivor_awp_run_speed", "220.0" );
    survivor_sniper_rifle_run_speed = CreateConVar( "survivor_sniper_rifle_run_speed", "220.0" );
    survivor_hunting_rifle_run_speed = CreateConVar( "survivor_hunting_rifle_run_speed", "220.0" );
}

public Plugin myinfo =
{
    name = "[L4D2] CS: GO-Style Sniper Rifle Run Speed",
    author = "Justin \"Sir Jay\" Chellah",
    description = "Allows server operators to change the run speed for survivors when they're holding an AWP, Sniper Rifle, or Hunting Rifle",
    version = "1.0.0",
    url = "https://www.justin-chellah.com/"
};