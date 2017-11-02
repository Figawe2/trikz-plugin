/**


    Change log


    1.0 - Initial release

    1.1 - Fixed a bug where restore would only display yes instead of yes or no

    1.2 - Fixed a bug where the cp angles were messed up

    1.3 - Fixed a bug where giveflash and autoflash and autoswitch wouldn't work

    1.4 - Used colorvariables instead of morecolors, to make hex colors possible

    1.5 - Added forwards

    1.6 - Added anti-block using collision hook































*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <trikz>

#include <colorvariables>

#include <msharedutil/ents>
#include <collisionhook>

/**
* - Convars
*/

ConVar g_ignoreRadio;

#define INF_MAXPLAYERS MAXPLAYERS+1

/**
* - Player Data
*/

/**
* - Int
*/


int g_iPartner[INF_MAXPLAYERS];

/**
* - Float
*/

float g_fCheckpoint[INF_MAXPLAYERS][2][3][3];

/**
* - Bool
*/

bool g_bBlock[INF_MAXPLAYERS];
bool g_bRestore[INF_MAXPLAYERS][2];
bool g_bAutoswitch[INF_MAXPLAYERS];
bool g_bAutoflash[INF_MAXPLAYERS];
bool g_bCheckpoint[INF_MAXPLAYERS][2];

/*
* - End of player data
*/


// OFFSETS

int g_Offset_hMyWeapons;
int g_Offset_iAmmo;

char g_Prefix[256];

/*
* - Forwards
*/

// Pre

Handle g_AutoflashForward_Pre;
Handle g_AutoswitchForward_Pre;
Handle g_BlockForward_Pre;
Handle g_CheckpointSaveForward_Pre;
Handle g_CheckpointLoadForward_Pre;
Handle g_PartnerForward_Pre;
Handle g_TeleportForward_Pre;
Handle g_UnpartnerForward_Pre;

// End of pre

// Post

Handle g_AutoflashForward_Post;
Handle g_AutoswitchForward_Post;
Handle g_BlockForward_Post;
Handle g_CheckpointSaveForward_Post;
Handle g_CheckpointLoadForward_Post;
Handle g_PartnerForward_Post;
Handle g_TeleportForward_Post;
Handle g_UnpartnerForward_Post;

// End of post

/*
* - End of forwards
*/

public Plugin myinfo =
{
    author = "denwo",
    url = "no url currently",
    name = "Trikz",
    description = "A Trikz plugin made by denwo( i used other people's code and ideas )",
    version = "1.6"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("trikz");

    CreateNative("T_GetClientPartner", Native_GetClientPartner);
    CreateNative("T_GetClientAutoflash", Native_GetClientAutoflash);
    CreateNative("T_GetClientAutoswitch", Native_GetClientAutoswitch);
    CreateNative("T_GetClientBlock", Native_GetClientBlock);
    CreateNative("T_GetClientCheckpoint", Native_GetClientCheckpoint);
    CreateNative("T_GetClientBCheckpoint", Native_GetClientBCheckpoint);

    return APLRes_Success;
}

public OnPluginStart()
{

    if ( (g_Offset_hMyWeapons = FindSendPropInfo( "CBasePlayer", "m_hMyWeapons" )) == -1 )
    {
        SetFailState( "Couldn't find offset for m_hMyWeapons!" );
    }

    if ( (g_Offset_iAmmo = FindSendPropInfo( "CCSPlayer", "m_iAmmo" )) == -1 )
    {
        SetFailState( "Couldn't find offset for m_iAmmo!" );
    }

    /**
    * - Commands
    */

    RegConsoleCmd("sm_autoflash",Cmd_Autoflash);
    RegConsoleCmd("sm_af", Cmd_Autoflash);

    RegConsoleCmd("sm_autoswitch", Cmd_Autoswitch);
    RegConsoleCmd("sm_as", Cmd_Autoswitch);

    RegConsoleCmd("sm_block", Cmd_Block);
    RegConsoleCmd("sm_bl", Cmd_Block);
    RegConsoleCmd("sm_ghost", Cmd_Block);
    RegConsoleCmd("sm_switch", Cmd_Block);

    RegConsoleCmd("sm_checkpoints", Cmd_Checkpoint);
    RegConsoleCmd("sm_checkpoint", Cmd_Checkpoint);
    RegConsoleCmd("sm_cpmenu", Cmd_Checkpoint);
    RegConsoleCmd("sm_cp", Cmd_Checkpoint);

    RegConsoleCmd("sm_flashbang", Cmd_Flash);
    RegConsoleCmd("sm_giveflash", Cmd_Flash);
    RegConsoleCmd("sm_flash", Cmd_Flash);
    RegConsoleCmd("sm_f", Cmd_Flash);

    RegConsoleCmd("sm_partner", Cmd_Partner);
    RegConsoleCmd("sm_buddy", Cmd_Partner);
    RegConsoleCmd("sm_mate", Cmd_Partner);
    RegConsoleCmd("sm_p", Cmd_Partner);

    RegConsoleCmd("sm_teleportto", Cmd_Teleport);
    RegConsoleCmd("sm_teleport", Cmd_Teleport)
    RegConsoleCmd("sm_tpto", Cmd_Teleport);
    RegConsoleCmd("sm_tp", Cmd_Teleport);

    RegConsoleCmd("sm_trikzmemu", Cmd_Trikz);
    RegConsoleCmd("sm_trikz", Cmd_Trikz);
    RegConsoleCmd("sm_menu", Cmd_Trikz);
    RegConsoleCmd("sm_t", Cmd_Trikz);

    RegConsoleCmd("sm_unpartner", Cmd_Unpartner);
    RegConsoleCmd("sm_breakup", Cmd_Unpartner);
    RegConsoleCmd("sm_nobuddy", Cmd_Unpartner);
    RegConsoleCmd("sm_nomate", Cmd_Unpartner);
    
    /**
    * - End of commands
    */

    g_ignoreRadio = FindConVar("sv_ignoregrenaderadio");

    g_ignoreRadio.SetBool(true);    

    /**
    * - Events
    */

    HookEvent("weapon_fire",E_WeaponFire,EventHookMode_Pre);
    HookEvent("player_spawn",E_SpawnPost,EventHookMode_Post);
    HookConVarChange(g_ignoreRadio,E_OnConVarChange);

    /**
    * - End of events
    */

    /**
    * - Translation
    */

    LoadTranslations("trikz.phrases");

    FormatEx(g_Prefix,sizeof(g_Prefix),"%t", "P_Prefix");

    /**
    * - End of translation
    */

    /**
    * - Forwards
    */

    // Pre

    g_AutoflashForward_Pre = CreateGlobalForward("T_OnAutoflash", ET_Hook, Param_Cell);
    g_AutoswitchForward_Pre = CreateGlobalForward("T_OnAutoSwitch", ET_Hook, Param_Cell);
    g_BlockForward_Pre = CreateGlobalForward("T_OnBlock", ET_Hook,Param_Cell);
    g_CheckpointSaveForward_Pre = CreateGlobalForward("T_OnCheckpointSave", ET_Hook, Param_Cell, Param_Cell);
    g_CheckpointLoadForward_Pre = CreateGlobalForward("T_OnCheckpointLoad", ET_Hook, Param_Cell, Param_Cell);
    g_PartnerForward_Pre = CreateGlobalForward("T_OnPartner", ET_Hook, Param_Cell, Param_Cell);
    g_TeleportForward_Pre = CreateGlobalForward("T_OnTeleport", ET_Hook, Param_Cell, Param_Cell);
    g_UnpartnerForward_Pre = CreateGlobalForward("T_OnUnpartner", ET_Hook, Param_Cell, Param_Cell);

    // End of pre

    // Post

    g_AutoflashForward_Post = CreateGlobalForward("T_OnAutoflashPost", ET_Event, Param_Cell);
    g_AutoswitchForward_Post = CreateGlobalForward("T_OnAutoSwitchPost", ET_Event, Param_Cell);
    g_BlockForward_Post = CreateGlobalForward("T_OnBlockPost", ET_Event,Param_Cell);
    g_CheckpointSaveForward_Post = CreateGlobalForward("T_OnCheckpointSavePost", ET_Event, Param_Cell, Param_Cell);
    g_CheckpointLoadForward_Post = CreateGlobalForward("T_OnCheckpointLoadPost", ET_Event, Param_Cell, Param_Cell);
    g_PartnerForward_Post = CreateGlobalForward("T_OnPartnerPost", ET_Event, Param_Cell, Param_Cell);
    g_TeleportForward_Post = CreateGlobalForward("T_OnTeleportPost", ET_Event, Param_Cell, Param_Cell);
    g_UnpartnerForward_Post = CreateGlobalForward("T_OnUnpartnerPost", ET_Event, Param_Cell, Param_Cell);

    // End of post

    /**
    * - End of forwards
    */
}

/**
* - Stocks
*/

stock bool IsValidClient(int client)
{
    if( 0 < client <= MaxClients && IsPlayerAlive(client) && IsClientInGame(client) && !IsFakeClient(client) )
    {
        return true;
    }
    return false;
}

stock int SaveCP(int client,int cpnumber)
{
    if(!client || !cpnumber) return 1;

    if(!IsPlayerAlive(client)) return 1;

    Action pre, post;

    cpnumber = cpnumber - 1;

    Call_StartForward(g_CheckpointSaveForward_Pre);

    Call_PushCell(client);
    Call_PushCell(cpnumber);

    Call_Finish(pre);

    float origin[3],angles[3],velocity[3];

    GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);

    GetClientEyeAngles(client, angles);
 
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

    g_fCheckpoint[client][cpnumber][0] = origin;
    g_fCheckpoint[client][cpnumber][1] = angles;
    g_fCheckpoint[client][cpnumber][2] = velocity;

    g_bCheckpoint[client][cpnumber] = true;

    Call_StartForward(g_CheckpointSaveForward_Post);
    
    Call_PushCell(client);
    Call_PushCell(cpnumber);

    Call_Finish(post);

    return 0;
}   

stock int LoadCP(int client, int cpnumber)
{
    if(!client || !cpnumber) return 1;

    cpnumber = cpnumber - 1;

    if(g_bCheckpoint[client][cpnumber] == false) return 1;
    
    Action pre,post;


    float origin[3], angles[3], velocity[3];

    origin = g_fCheckpoint[client][cpnumber][0];
    angles = g_fCheckpoint[client][cpnumber][1];
    velocity = g_fCheckpoint[client][cpnumber][2];

    bool b[2];

    b[0] = g_bRestore[client][0];
    b[1] = g_bRestore[client][1];

    Call_StartForward(g_CheckpointLoadForward_Pre);

    Call_PushCell(client);
    Call_PushCell(cpnumber);

    Call_Finish(pre);

    if(b[0] && b[1])
    {
        TeleportEntity(client,origin,angles,velocity);
    }
    else if(!b[0] && b[1])
    {
        TeleportEntity(client,origin,NULL_VECTOR,velocity);
    }
    else if(b[0] && !b[1])
    {
        velocity[0] = 0.0;
        velocity[1] = 0.0;
        velocity[2] = 0.0;

        TeleportEntity(client,origin,angles,velocity);
    }
    else if(!b[0] && !b[1])
    {
        velocity[0] = 0.0;
        velocity[1] = 0.0;
        velocity[2] = 0.0;

        TeleportEntity(client,origin,NULL_VECTOR,velocity);
    }

    Call_StartForward(g_CheckpointLoadForward_Post);

    Call_PushCell(client);
    Call_PushCell(cpnumber);

    Call_Finish(post);

    return 0;
}

stock void GiveFlashbang(client)
{
    GivePlayerItem(client, "weapon_flashbang");
}

stock int GetClientFlashbangs( int client )
{
    decl String:szWep[32];
    int weapon;
    
    for ( int i = 0; i <= 128; i += 4 )
    {
        weapon = GetEntDataEnt2( client, g_Offset_hMyWeapons + i );
        
        if ( weapon != -1 )
        {
            GetEntityClassname( weapon, szWep, sizeof( szWep ) );
            
            if ( StrEqual( szWep, "weapon_flashbang" ) )
            {
                return GetEntData( client, g_Offset_iAmmo + (GetEntProp( weapon, Prop_Send, "m_iPrimaryAmmoType" ) * 4) );
            }
        }
    }
    
    return 0;

}

/**
* - End of stocks
*/


/**
* - Commands
*/

public Action Cmd_Autoflash(int client,int args)
{
    if(!client) return Plugin_Handled;

    Action pre,post;

    Call_StartForward(g_AutoflashForward_Pre);

    Call_PushCell(client);

    Call_Finish(pre);

    g_bAutoflash[client] = !g_bAutoflash[client];

    if(args == 1) return Plugin_Handled;

    Call_StartForward(g_AutoflashForward_Post);

    Call_PushCell(client);

    Call_Finish(post);

    char status[8];

    Format(status, sizeof(status), "%s", g_bAutoflash[client] ? "Enabled" : "Disabled" );

    CPrintToChat(client, "%s %t", g_Prefix, "P_Autoflash", status);

    return Plugin_Handled;

}

public Action Cmd_Autoswitch(int client, int args)
{
    if(!client) return Plugin_Handled;

    Action pre,post;

    Call_StartForward(g_AutoswitchForward_Pre);

    Call_PushCell(client);

    Call_Finish(pre);

    g_bAutoswitch[client] = !g_bAutoswitch[client];

    Call_StartForward(g_AutoswitchForward_Post);

    Call_PushCell(client);

    Call_Finish(post);

    char status[8];

    Format(status, sizeof(status), "%s", g_bAutoswitch[client] ? "Enabled" : "Disabled" );
    
    if(args == 1) return Plugin_Handled;

    CPrintToChat(client, "%s %t", g_Prefix, "P_Autoswitch", status);

    return Plugin_Handled;
}


public Action Cmd_Block(int client,int args)
{
    if(!client) return Plugin_Handled;

    Action pre,post;

    Call_StartForward(g_BlockForward_Pre);

    Call_PushCell(client);

    Call_Finish(pre);

    g_bBlock[client] = !g_bBlock[client];

    char status[256];

    if(g_bBlock[client])
    {
        SetEntityCollisionGroup(client,5);
        SetEntityRenderMode(client, RENDER_NORMAL);
    }
    else if(!g_bBlock[client])
    {
        SetEntityCollisionGroup(client,2);
        SetEntityRenderMode(client, RENDER_TRANSALPHA);
        SetEntityRenderColor(client, 255, 255, 255, 100);
    }
    
    Call_StartForward(g_BlockForward_Post);

    Call_PushCell(client);

    Call_Finish(post);

    Format(status,sizeof(status),"%s", g_bBlock[client] ? "Enabled" : "Disabled");

    if(args == 1) return Plugin_Handled;

    CPrintToChat(client, "%s %t", g_Prefix, "P_Block", status);

    return Plugin_Handled;
}

public Action Cmd_Checkpoint(int client, int args)
{
    if(!client) return Plugin_Handled;

    char szDisplay[256];

    Panel panel = new Panel();

    panel.SetTitle("Checkpoint menu");

    panel.DrawItem(" ", ITEMDRAW_RAWLINE);

    panel.DrawItem("Save Checkpoint 1");
    panel.DrawItem("Load Checkpoint 1");

    panel.DrawItem(" ", ITEMDRAW_RAWLINE);

    panel.DrawItem("Save Checkpoint 2");
    panel.DrawItem("Load Checkpoint 2");

    panel.DrawItem(" ", ITEMDRAW_RAWLINE);

    Format(szDisplay,sizeof(szDisplay), "Restore Angles: %s", g_bRestore[client][0] ? "Yes" : "No");
    
    panel.DrawItem(szDisplay);

    Format(szDisplay,sizeof(szDisplay), "Restore Velocity: %s", g_bRestore[client][1] ? "Yes" : "No");
    
    panel.DrawItem(szDisplay);

    panel.DrawItem(" ", ITEMDRAW_RAWLINE);

    panel.DrawItem("Back to trikz menu");

    panel.DrawItem(" ", ITEMDRAW_RAWLINE);
    
    panel.DrawItem(" ", ITEMDRAW_NOTEXT);
    panel.DrawItem(" ", ITEMDRAW_NOTEXT);

    panel.DrawItem("Exit", ITEMDRAW_CONTROL);

    panel.Send(client, H_CheckpointPanel, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public Action Cmd_Flash(int client,int args)
{
    if(!client) return Plugin_Handled;

    if(GetClientFlashbangs(client) < 2)
    {
        GiveFlashbang(client);
    }

    return Plugin_Handled;
}

public Action Cmd_Partner(int client, int args)
{
    if(!client) return Plugin_Handled;

    if(g_iPartner[client] != 0)
    {
        CPrintToChat(client, "%s %t", g_Prefix, "P_HavePartner");
        return Plugin_Handled;
    }

    Menu menu = new Menu(H_PartnerMenu);

    menu.SetTitle("Select A Player \n");

    char szInfo[32],szDisplay[128];

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i)) continue;
        if(IsFakeClient(i)) continue;
        if( g_iPartner[i] != 0 ) continue;
        if(i == client) continue;

        FormatEx( szInfo, sizeof( szInfo ), "%i", GetClientUserId( i ) );        
        
        GetClientName(i, szDisplay, sizeof(szDisplay));

        menu.AddItem(szInfo, szDisplay);
    }

    if(menu.ItemCount == 0)
    {
        CPrintToChat(client, "%s %t", g_Prefix, "P_NoPlayersPartner");

        return Plugin_Handled;
    }

    menu.Display(client,MENU_TIME_FOREVER);

    return Plugin_Handled;

}

public Action Cmd_Teleport(int client,int args)
{
    if(!client) return Plugin_Handled;

    Menu menu = new Menu(H_TeleportMenu);

    menu.SetTitle("Select a Player");

    char szInfo[32], szDisplay[128];

    for( int i=1; i <= MaxClients;i++ )
    {
        if(i == client) continue;
        if(!IsClientInGame(i)) continue;
        if(IsFakeClient(i)) continue;

        FormatEx(szInfo, sizeof(szInfo), "%i", GetClientUserId(i));

        GetClientName(i,szDisplay, sizeof(szDisplay));

        menu.AddItem(szInfo,szDisplay);
    }

    if(menu.ItemCount == 0)
    {
        CPrintToChat(client, "%s %t", g_Prefix, "P_NoPlayersTeleport");
        return Plugin_Handled;
    }

    menu.Display(client,MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public Action Cmd_Trikz(int client,int args)
{
    if(!client) return Plugin_Handled;

    char szDisplay[256];

    Panel panel = new Panel();

    panel.SetTitle("Trikz menu");

    panel.DrawItem(" ", ITEMDRAW_RAWLINE);

    Format(szDisplay,sizeof(szDisplay), "%s Autoswitch", g_bAutoswitch[client] ? "Disable" : "Enable" );

    panel.DrawItem(szDisplay);

    Format(szDisplay,sizeof(szDisplay), "%s Autoflash", g_bAutoflash[client] ? "Disable" : "Enable" );

    panel.DrawItem(szDisplay);
    
    Format(szDisplay,sizeof(szDisplay), "%s Block", g_bBlock[client] ? "Disable" : "Enable" );

    panel.DrawItem(szDisplay);
    
    panel.DrawItem(" ", ITEMDRAW_RAWLINE);

    panel.DrawItem("Give Flashbang");

    panel.DrawItem(" ", ITEMDRAW_RAWLINE);

    panel.DrawItem("Open Checkpoint menu");

    panel.DrawItem("Teleport to Player");

    panel.DrawItem(" ", ITEMDRAW_RAWLINE);

    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);

    panel.DrawItem("Exit", ITEMDRAW_CONTROL);

    panel.Send(client, H_TrikzPanel, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public Action Cmd_Unpartner(int client, int args)
{
    if(!client && IsFakeClient(client)) return Plugin_Handled;

    Action pre,post;

    if(g_iPartner[client] == 0)
    {
        CPrintToChat(client, "%s %t", g_Prefix, "P_NoPartnerBreakup");
        return Plugin_Handled;
    }

    Call_StartForward(g_UnpartnerForward_Pre);

    int partner = g_iPartner[client];

    Call_PushCell(client);
    Call_PushCell(partner);

    Call_Finish(pre);

    if(partner && client && !IsFakeClient(partner) && !IsFakeClient(client))
    {
        g_iPartner[client] = 0;
        g_iPartner[partner] = 0;
        

        CPrintToChat(client, "%s %t", g_Prefix, "P_PartnershipCancelled");
        CPrintToChat(partner, "%s %t", g_Prefix, "P_PartnershipCancelled");
    }

    Call_StartForward(g_UnpartnerForward_Post);

    Call_PushCell(client);
    Call_PushCell(partner);

    Call_Finish(post);

    return Plugin_Handled;
}

/**
* - End of commands
*/

/**
* - Menus / Panels
*/

public int H_CheckpointPanel(Menu panel, MenuAction action, int client, int index)
{
    if(!client || !index) return 1;

    if(IsClientInGame(client) && index < 10 && index > 0)
    {
        EmitSoundToClient(client, "buttons/button14.wav");
    }
    else if(IsClientInGame(client) && index == 10)
    {
        EmitSoundToClient(client, "buttons/combine_button7.wav");
    }

    switch(index)
    {
        case 1:
        {
            SaveCP(client,1);
        }
        case 2:
        {
            LoadCP(client,1);
        }
        case 3:
        {
            SaveCP(client,2);
        }
        case 4:
        {
            LoadCP(client,2);
        }
        case 5:
        {
            g_bRestore[client][0] = !g_bRestore[client][0];
        }
        case 6:
        {
            g_bRestore[client][1] = !g_bRestore[client][1];
        }
        case 7:
        {
            FakeClientCommand(client,"sm_trikz");

            return 0;
        }
        case 10:
        {
            CloseHandle(panel);

            return 0;
        }
    }

    FakeClientCommand(client,"sm_checkpoint");

    return 0;
}

public int H_PartnerMenu(Menu oldmenu, MenuAction action, int sender, int index)
{
    if( g_iPartner[sender] != 0 ) return 1;

    char szInfo[32];

    if(!GetMenuItem(oldmenu, index, szInfo, sizeof(szInfo))) return 1;

    int reciever = GetClientOfUserId( StringToInt(szInfo) );

    if( !reciever ) return 1;

    if(IsFakeClient(reciever) || IsFakeClient(sender)) return 1;

    if( g_iPartner[reciever] != 0 || g_iPartner[sender] != 0 ) return 1;

    char szDisplay[MAX_NAME_LENGTH];

    GetClientName( sender,szDisplay,sizeof(szDisplay));

    Menu menu = new Menu(H_PartnerMenu_Confirm);

    menu.SetTitle("%s wants to be your partner! Do you accept?\n", szDisplay);

    FormatEx(szInfo, sizeof(szInfo), "%i", GetClientUserId(sender));

    menu.AddItem(szInfo,"Agree\n");
    menu.AddItem("","Decline");

    menu.Display( reciever, MENU_TIME_FOREVER );

    return 0;

}

public int H_PartnerMenu_Confirm(Menu oldmenu, MenuAction action, int reciever, int index)
{
    if(!reciever)
    {
        return 1;
    }
    if(g_iPartner[reciever] != 0)
    {
        return 1;
    }

    char szInfo[32];
    if ( !GetMenuItem( oldmenu, index, szInfo, sizeof( szInfo ) ) )
    {
        return 1;
    }

    int sender = GetClientOfUserId( StringToInt( szInfo ) );

    if(IsFakeClient(sender)) { 
            
        return 1;
    }

    if(g_iPartner[sender] != 0)
    {
        return 1;
    }
    
    Action pre,post;

    Call_StartForward(g_PartnerForward_Pre);
    
    Call_PushCell(sender);
    Call_PushCell(reciever);

    Call_Finish(pre);

    g_iPartner[sender] = reciever;
    g_iPartner[reciever] = sender;

    char szName[MAX_NAME_LENGTH];

    GetClientName(reciever, szName,sizeof(szName));

    CPrintToChat(sender, "%T %T", "P_Prefix", "P_PartneredWith", szName);    

    GetClientName(sender, szName,sizeof(szName));

    CPrintToChat(reciever, "%T %T", "P_Prefix", "P_PartneredWith", szName);

    Call_StartForward(g_PartnerForward_Post);

    Call_PushCell(sender);
    Call_PushCell(reciever);

    Call_Finish(post);

    return 0;
}

public int H_TeleportMenu(Menu oldmenu, MenuAction action, int sender, int index)
{
    if(!sender) return 1;

    char szInfo[32];
    if(!GetMenuItem( oldmenu, index, szInfo, sizeof( szInfo ) ) ) return 1;

    int reciever = GetClientOfUserId( StringToInt( szInfo  ) );

    if(!reciever) return 1;

    if(IsFakeClient(reciever)) return 1;
    
    char szDisplay[128];

    GetClientName(sender, szDisplay, sizeof(szDisplay));

    Menu menu = new Menu(H_TeleportMenu_Confirm);

    menu.SetTitle("%s wants to teleport to you! Do you accept?", szDisplay);

    Format(szInfo,sizeof(szInfo), "%i", GetClientUserId(sender));

    menu.AddItem(szInfo,"Agree\n");

    menu.AddItem("", "Decline");

    menu.Display(reciever,MENU_TIME_FOREVER);

    return 0;
}

public int H_TeleportMenu_Confirm(Menu menu, MenuAction action, int reciever, int index)
{
    if(!reciever) return 1;
    if(IsFakeClient(reciever)) return 1;

    char szInfo[32];

    if(!GetMenuItem(menu, index, szInfo, sizeof(szInfo))) return 1;
    
    int sender = GetClientOfUserId( StringToInt(szInfo) );

    if(!reciever) return 1;
    if(IsFakeClient(reciever)) return 1;
    
    Action pre,post;

    Call_StartForward(g_TeleportForward_Pre);
    
    Call_PushCell(sender);
    Call_PushCell(reciever);

    Call_Finish(pre);

    float origin[3];
    
    GetEntPropVector(reciever, Prop_Send, "m_vecOrigin", origin);

    TeleportEntity(sender,origin,NULL_VECTOR,NULL_VECTOR);

    Call_StartForward(g_TeleportForward_Post);

    Call_PushCell(sender);
    Call_PushCell(reciever);

    Call_Finish(post);

    return 0;
}

public int H_TrikzPanel(Menu panel, MenuAction action, int client, int index)
{
    if(!client || !index && !IsClientConnected(client)) return 1;

    if(index < 10)
    {
        EmitSoundToClient(client, "buttons/button14.wav");
    }
    else if(index == 10)
    {
        EmitSoundToClient(client, "buttons/combine_button7.wav");
    }

    switch(index)
    {
        case 1:
        {
            FakeClientCommand(client,"sm_autoswitch");
        }
        case 2:
        {
            FakeClientCommand(client,"sm_autoflash");
        }
        case 3:
        {
            FakeClientCommand(client,"sm_block");
        }
        case 4:
        {
            FakeClientCommand(client,"sm_flash");
        }
        case 5:
        {
            FakeClientCommand(client,"sm_cp");
            
            return 0;
        }
        case 6:
        {
            FakeClientCommand(client,"sm_tpto");

            return 0;
        }
        case 10:
        {

            CloseHandle(panel);
        
            return 0;
        }
    }
    
    FakeClientCommand(client,"sm_trikz");

    return 0;
}

/**
* - End of menus / panels
*/


/**
* - Events
*/

public Action E_SpawnPost(Event event,const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(client)
    {
        GiveFlashbang(client);
    }

}

public Action E_WeaponFire(Event event,const char[] name, bool dontBroadcast)
{
    char weapon[256];

    event.GetString("weapon",weapon,sizeof(weapon));

    int client = GetClientOfUserId(event.GetInt("userid"));

    if(client)
    {
        if(StrEqual(weapon,"flashbang"))
        {        
            if(g_bAutoflash[client] && GetClientFlashbangs(client) < 2)
            {
                GiveFlashbang(client);
            }
            if(g_bAutoswitch[client])
            {
                CreateTimer(0.15,T_SwitchToFlashbang,GetClientSerial(client));
            }   
        }
    }
}

public void E_OnConVarChange(ConVar convar, const char[] oldvalue, const char[] newvalue)
{
    convar.SetBool(true, false, false);
}

/**
* - End of events
*/

/**
* - Timers
*/

public Action T_SwitchToFlashbang(Handle timer, any serial)
{
    int client = GetClientFromSerial(serial);
    
    if(client)
    {
        FakeClientCommand(client, "use weapon_knife");
        FakeClientCommand(client, "use weapon_flashbang");
    }
}

public Action T_KillFlashbang(Handle timer, any edict)
{
    char classname[128];
    
    if(!GetEdictClassname(edict, classname, sizeof(classname))) return Plugin_Handled

    // - Just to be safe
    if(IsValidEdict(edict) && IsValidEntity(edict) && StrEqual(classname,"flashbang_projectile"))
    {
        AcceptEntityInput(edict,"kill");

        return Plugin_Stop;
    }

    return Plugin_Continue;
}

/**
* - End of timers
*/

/**
* - Forwards
*/

public Action CH_PassFilter(int ent1, int ent2, bool &result)
{
    if(IsValidClient(ent1) && IsValidClient(ent2))
    {
        if((g_iPartner[ent1] != 0 && g_iPartner[ent1] != ent2) || (g_iPartner[ent2] != 0 && g_iPartner[ent2] != ent1))
        {
            result = false;

            return Plugin_Handled;
        }
        if(!g_bBlock[ent1] || !g_bBlock[ent2])
        {
            result = false;

            return Plugin_Handled;
        }
    }

    if(IsValidEdict(ent2))
    {
        char classname[32];
        GetEdictClassname(ent2,classname,sizeof(classname));

        if(StrEqual(classname, "flashbang_projectile", false))
        {
            int owner = GetEntPropEnt(ent2, Prop_Send,"m_hOwnerEntity")

            if(IsValidClient(owner))
            {
                if(!g_bBlock[owner] || !g_bBlock[ent1])
                {
                    result = true;
                    return Plugin_Handled;
                }
                if((g_iPartner[owner] != 0 && g_iPartner[owner] == ent1) || (g_iPartner[ent1] != 0 && g_iPartner[owner] == ent1) ) 
                {
                    result = true;

                    return Plugin_Handled;
                }
                else
                {
                    result = false;

                    return Plugin_Handled;
                }
            }
        }
    }
    result = true;

    return Plugin_Continue;
}

public OnClientDisconnect(int client)
{
    if(client && IsValidEntity(client) && !IsFakeClient(client) && IsClientConnected(client))
    {
        FakeClientCommand(client, "sm_breakup");
    }
}

public OnClientPutInServer(int client)
{
    if(client)
    {
        g_bAutoflash[client] = true;
        g_bAutoswitch[client] = true;
        g_bBlock[client] = true;

        g_bCheckpoint[client][0] = false;
        g_bCheckpoint[client][1] = false;
        
        g_bRestore[client][0] = false;
        g_bRestore[client][1] = false;
        
        for(int i=0; i < 3; i++)
        {
            g_fCheckpoint[client][0][0][i] = 0.0;
            g_fCheckpoint[client][0][1][i] = 0.0;
            g_fCheckpoint[client][0][2][i] = 0.0;

            g_fCheckpoint[client][1][0][i] = 0.0;
            g_fCheckpoint[client][1][1][i] = 0.0;
            g_fCheckpoint[client][1][2][i] = 0.0;
        }

    }
}

public OnEntityCreated(int entity, const char[] classname)
{

    if(IsValidEdict(entity) && IsValidEntity(entity) && StrEqual(classname, "flashbang_projectile"))
    {
        CreateTimer(1.2,T_KillFlashbang,entity);
    }
}

/**
* - End of forwards
*/

/**
* - Natives
*/

public int Native_GetClientPartner(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return g_iPartner[client];
}

public int Native_GetClientAutoflash(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return g_bAutoflash[client];
}

public int Native_GetClientAutoswitch(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return g_bAutoswitch[client];
}

public int Native_GetClientBlock(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return g_bBlock[client];
}

public int Native_GetClientCheckpoint(Handle plugin,int numParams)
{
    int client = GetNativeCell(1);
    int cpnumber = GetNativeCell(2);

    float origin[3], angles[3], velocity[3];

    view_as<float>(GetNativeArray(3, origin,3));
    view_as<float>(GetNativeArray(4, angles,3));
    view_as<float>(GetNativeArray(5, velocity,3));

    for(int i=0; i < 3 ;i++)
    {
        origin[i] = g_fCheckpoint[client][cpnumber][0][i];
        angles[i] = g_fCheckpoint[client][cpnumber][1][i];
        velocity[i] = g_fCheckpoint[client][cpnumber][2][i];
    }

    return 1;
}

public int Native_GetClientBCheckpoint(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int cpnumber = GetNativeCell(2);

    return g_bCheckpoint[client][cpnumber];
}


/**
* - End of natives
*/
