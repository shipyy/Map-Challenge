/* 
-----
Plugin Info
-----
*/
public Plugin myinfo =
{
	name = "Map Challenges",
	author = "https://github.com/shipyy",
	description = "Allows Creation of challenges for surf maps",
	version = "1.0.0",
	url = "https://github.com/shipyy/Map-Challenge"
};

/* ----- VARIABLES -----*/

// SQL driver
Handle g_hDb = null;

// Used to track failed transactions when making database changes
int g_failedTransactions[2];

//CHALLENGE
int g_iChallenge_ID = -1;
bool g_bIsChallengeActive = false;
bool g_bIsCurrentMapChallenge = false;

int g_iChallenge_Initial_TimeStamp;
int g_iChallenge_Final_TimeStamp;
//int g_iChallenge_Duration;
//int g_iCurrent_TimeStamp;
int g_iChallenge_Points;
int g_iChallenge_Style;
char g_sChallenge_MapName[32];

char g_szMapName[128];

char g_szStyleMenuPrint[][] =
{
	"Normal",
	"Sideways",
	"Half-Sideways",
	"Backwards",
	"Low-Gravity",
	"Slow Motion",
	"Fast Forward",
	"Freestyle"
};

char g_szStyleAcronyms[][] =
{
	"n",
	"sw",
	"hsw",
	"bw",
	"lg",
	"sm",
	"ff",
	"fs"
};

// Client's steamID
char g_szSteamID[MAXPLAYERS + 1][32];

char g_szChatPrefix[64] = "MAP CHALLENGE";

GlobalForward g_NewChallengeForward;
GlobalForward g_ChallengeEndForward;

/* ----- INCLUDES ----- */
#include <surftimer>
#include <colorlib>
#include <map-challenge>
#include "mc-queries.sp"
#include "mc-sql.sp"
#include "mc-misc.sp"
#include "mc-api.sp"

#define PERCENT 0x25
#define MAX_STYLES 8

stock bool IsValidClient(int client)
{   
    if (client >= 1 && client <= MaxClients && IsClientInGame(client))
        return true;
    return false;
}

//CHECK IF CHALLENGE IS ACTIVE
	//END CHALLENGE
	//FORWARD ONMAPFINISH
public void OnPluginStart()
{
    EngineVersion eGame = GetEngineVersion();
    if(eGame != Engine_CSGO && eGame != Engine_CSS)
		SetFailState("[Surf Timer][TDF] This plugin is for CSGO/CSS only.");
    
    // reload language files
    LoadTranslations("mapchallenge.phrases");

    Register_Forwards();

}

public void OnMapStart(){

    db_setupDatabase();

    //COMMANDS
    RegConsoleCmd("sm_challenge", Challenge_Info, "[Map Challenge] Displays additional information of the ongoing challenge");
    RegConsoleCmd("sm_mcp", ChallengeProfile, "[Map Challenge] Displays the players profile");
    RegConsoleCmd("sm_mctop", TopLeaderBoard, "[Map Challenge] Displays the overall challenge top players (TOP 50) (TOP 50)");
    RegConsoleCmd("sm_mcct", LeaderBoard, "[Map Challenge] Displays the ongoing challenge leaderboard (TOP 50)");
    RegConsoleCmd("sm_mct", Challenge_Timeleft, "[Map Challenge] Displays remaining time left of the current challenge");
    RegAdminCmd("sm_add_challenge", Create_Challenge, ADMFLAG_ROOT, "[Map Challenge] Add new challenge");
    RegAdminCmd("sm_end_challenge", Manual_ChallengeEnd, ADMFLAG_ROOT, "[Map Challenge] Ends the ongoing challenge");

    //CURRENT MAP NAME
    GetCurrentMap(g_szMapName, sizeof(g_szMapName));

    //CHECK CHALLENGE IS ACTIVE
    db_CheckChallengeActive();
}

public void OnClientPutInServer(int client)
{   
    if (!IsValidClient(client))
		return;

    GetClientAuthId(client, AuthId_Steam2, g_szSteamID[client], MAX_NAME_LENGTH, true);
}

public void ResetDefaults(){
    //SET DEFAULTS
    g_bIsChallengeActive = false;
    g_bIsCurrentMapChallenge = false;

    g_iChallenge_Initial_TimeStamp = 0;
    g_iChallenge_Final_TimeStamp = 0;
    g_iChallenge_Style = 0;
    g_sChallenge_MapName = "";
}

public void db_CheckChallengeActive()
{
    char szQuery[255];
    Format(szQuery, sizeof(szQuery), "SELECT id, active, mapname, points, UNIX_TIMESTAMP(StartDate), UNIX_TIMESTAMP(EndDate), TIMESTAMPDIFF(SECOND,CURRENT_TIMESTAMP, EndDate) as Time_Diff FROM ck_challenges ORDER BY id DESC LIMIT 1;");
    SQL_TQuery(g_hDb, sql_CheckChallengeActiveCallback, szQuery, DBPrio_Low);
}

public void sql_CheckChallengeActiveCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
	if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_CheckChallengeActiveCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){
        if(SQL_FetchInt(hndl, 1) == 1){
            SQL_FetchString(hndl, 2, g_sChallenge_MapName, sizeof(g_sChallenge_MapName));
            PrintToServer("\n\n\nLoaded MapName : %s\n\n\n", g_sChallenge_MapName);

            g_iChallenge_Initial_TimeStamp = SQL_FetchInt(hndl, 4);
            g_iChallenge_Final_TimeStamp = SQL_FetchInt(hndl, 5);

            //CHECK IF CURRENT TIME STAMP IS NEWER THAN HE END_DATE OF THE CURRENT CHALLENGE
            int time_diff = SQL_FetchInt(hndl, 6);
            g_iChallenge_Points = SQL_FetchInt(hndl, 3);

            g_iChallenge_ID = SQL_FetchInt(hndl, 0);

            //REACHED END OF CHALLENGE
            if(time_diff <= 0){
                db_EndCurrentChallenge(0, g_iChallenge_ID);
            }
            else{
                g_bIsChallengeActive = true;

                if(StrEqual(g_szMapName, g_sChallenge_MapName, false))
                    g_bIsCurrentMapChallenge = true;

                //Timer that check regularly if the time remaining of current challenge has run out
                CreateTimer(360.0, Check_Challenge_End, INVALID_HANDLE, TIMER_REPEAT);
            }
        }
        else{
            g_bIsChallengeActive = false;
            g_iChallenge_ID = SQL_FetchInt(hndl, 0);
            //SQL_FetchString(hndl, 2, g_sChallenge_MapName, sizeof(g_sChallenge_MapName));
        }
    }
}

//CREATE CHALLENGE
public Action Create_Challenge(int client, int args)
{

    if(!IsValidClient(client))
        return Plugin_Handled;

    if(args != 4)
        CPrintToChat(client, "%t", "Add_Challenge_ERROR_Format", g_szChatPrefix);
    else{
        //GET ARGUMENTS VALUES
        char szMapName[32];
        GetCmdArg(1, szMapName, sizeof(szMapName));

        char szstyle[32];
        GetCmdArg(2, szstyle, sizeof(szstyle));
        int style = StringToInt(szstyle);

        char szpoints[32];
        GetCmdArg(3, szpoints, sizeof(szpoints));
        int points = StringToInt(szpoints);

        char szduration[32];
        GetCmdArg(4, szduration, sizeof(szduration));
        int duration = StringToInt(szduration);

        if(!g_bIsChallengeActive)
            db_selectMapNameEquals(client, szMapName, style, points, duration);
        else
            CPrintToChat(client, "%t", "Challenge_Active", g_szChatPrefix);
    }

    return Plugin_Handled;
}

public void db_selectMapNameEquals(int client, char szMapName[32], int style, int points, int duration)
{
    Handle pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackString(pack, szMapName);
    WritePackCell(pack, style);
    WritePackCell(pack, points);
    WritePackCell(pack, duration);

    char szQuery[256];
    Format(szQuery, sizeof(szQuery), "SELECT DISTINCT mapname FROM ck_zones WHERE mapname = '%s' LIMIT 1;", szMapName);
    SQL_TQuery(g_hDb, sql_selectMapNameEqualsCallback, szQuery, pack, DBPrio_Low);
}

public void sql_selectMapNameEqualsCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
    if (hndl == null)
    {
        LogError("[Map Challenge] SQL Error (sql_selectMapNameEqualsCallback): %s", error);
        CloseHandle(pack);
        return;
    }
    
    ResetPack(pack);
    int client = ReadPackCell(pack);
    char szMapName[32];
    ReadPackString(pack, szMapName, sizeof(szMapName));
    int style = ReadPackCell(pack);
    int points = ReadPackCell(pack);
    int duration = ReadPackCell(pack);
    CloseHandle(pack);
    
    if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
        db_AddChallenge(client, szMapName, style, points, duration);
	}
	else
	{
		CPrintToChat(client, "%t", "Map_Not_Valid", g_szChatPrefix, szMapName);
	}
}

public void db_AddChallenge(int client, char szMapName[32], int style, int points, int duration)
{
    g_sChallenge_MapName = szMapName;
    g_iChallenge_Points = points;
    g_iChallenge_Style = style;

    if(StrEqual(szMapName, g_szMapName, false))
        g_bIsCurrentMapChallenge = true;

    char szInitial_TimeStamp[32];
    //char szFinal_TimeStamp[32];

    //GET TIME STAMPS IN UNIX CODE
    g_iChallenge_Initial_TimeStamp = GetTime();
    g_iChallenge_Final_TimeStamp = g_iChallenge_Initial_TimeStamp + (60 * 60 * (24 * duration));
    //g_iChallenge_Duration = duration;

    //FORMAT UNIX TIMESTAMPS TO THE FORMAT USED IN THE DATABASE
    FormatTime(szInitial_TimeStamp, sizeof(szInitial_TimeStamp), "%F %X", g_iChallenge_Initial_TimeStamp);
    //FormatTime(szFinal_TimeStamp, sizeof(szFinal_TimeStamp), "%F %X", g_iChallenge_Final_TimeStamp);

    //char szFinal_TimeStamp_SQL_FORMAT[128];
    //Format(szFinal_TimeStamp_SQL_FORMAT, sizeof(szFinal_TimeStamp_SQL_FORMAT), "DATE_ADD(%s, INTERVAL %i DAY)", szInitial_TimeStamp, duration); 

    char szQuery_Insert[1024];
    Format(szQuery_Insert, sizeof(szQuery_Insert), "INSERT INTO ck_challenges (mapname, StartDate, style, points, active) VALUES ('%s', '%s', '%i', '%i', '%i');", szMapName, szInitial_TimeStamp, g_iChallenge_Style, g_iChallenge_Points, 1);
    //SQL_TQuery(g_hDb, sql_db_AddChallengeCallback, szQuery, duration, DBPrio_Low);

    char szQuery_Update[1024];
    Format(szQuery_Update, sizeof(szQuery_Update), "UPDATE ck_challenges SET EndDate = DATE_ADD(StartDate, INTERVAL %i DAY);", duration);
    //SQL_TQuery(g_hDb, sql_db_AddChallengeCallback, szQuery, duration, DBPrio_Low);
    
    Transaction add_challange_transactions = SQL_CreateTransaction();
    SQL_AddQuery(add_challange_transactions, szQuery_Insert);
    SQL_AddQuery(add_challange_transactions, szQuery_Update);

    SQL_ExecuteTransaction(g_hDb, add_challange_transactions, SQLTxn_AddChallenge_Success , SQLTxn_AddChallenge_Failed, client);
}

public void SQLTxn_AddChallenge_Success(Handle db, any data, int numQueries, Handle[] results, any[] queryData)
{   
    g_bIsChallengeActive = true;
    g_iChallenge_ID = g_iChallenge_ID + 1;
    CPrintToChatAll("%t", "Challenge_Added", g_szChatPrefix, g_sChallenge_MapName);
    PrintToServer("[Map Challenge] Challenge Successfully Created");

    CreateTimer(360.0, Check_Challenge_End, INVALID_HANDLE, TIMER_REPEAT);

    SendNewChallengeForward(data);
}

public void SQLTxn_AddChallenge_Failed(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	PrintToServer("[Map Challenge] Challenge Creation Failed");
}

public Action Manual_ChallengeEnd(int client, int args)
{
    if (!IsValidClient(client))
		return Plugin_Handled;

    if(g_bIsChallengeActive)
        db_EndCurrentChallenge(client, g_iChallenge_ID);
    else
        CPrintToChat(client, "%t", "Challenge_Inactive", g_szChatPrefix);
    
    return Plugin_Handled;
}

public void db_EndCurrentChallenge(int client, int challenge_ID)
{
    char szQuery[256];
    Format(szQuery, sizeof(szQuery), "UPDATE ck_challenges SET active = 0 WHERE id = '%i';", challenge_ID);
    SQL_TQuery(g_hDb, sql_EndCurrentChallengeCallback, szQuery, client, DBPrio_Low);
}

public void sql_EndCurrentChallengeCallback(Handle owner, Handle hndl, const char[] error, any client)
{
    if (hndl == null)
    {
        LogError("[Map Challange] SQL Error (sql_EndCurrentChallengeCallback): %s", error);
        return;
    }
    
    db_DistributePoints(client);
}

public Action surftimer_OnMapFinished(int client, float fRunTime, char sRunTime[54], int rank, int total, int style)
{
    if(g_bIsCurrentMapChallenge && g_bIsChallengeActive && (g_iChallenge_Style == style))
        db_PlayerExistsCheck(client, fRunTime, style);

    return Plugin_Handled;
}

public void db_PlayerExistsCheck(int client, float runtime, int style)
{
    if (!IsValidClient(client))
		return;
    
    Handle pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackFloat(pack, runtime);
    WritePackCell(pack, style);
    
    char szQuery[255];
    Format(szQuery, sizeof(szQuery), "SELECT * FROM ck_challenge_players WHERE steamid = '%s' AND style = '%i';", g_szSteamID[client], style);
    SQL_TQuery(g_hDb, sql_PlayerExistsCheckCallback, szQuery, pack, DBPrio_Low);
}

public void sql_PlayerExistsCheckCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
	if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_PlayerExistsCheckCallback): %s", error);
		CloseHandle(pack);
		return;
	}

	ResetPack(pack);
	int client = ReadPackCell(pack);
	float runtime = ReadPackFloat(pack);
	int style = ReadPackCell(pack);
    
    // Found old time from database
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
        db_TimesExistsCheck(client, runtime, style);
	else
        db_InsertPlayer(client, runtime, style);
}

public void db_InsertPlayer(int client, float runtime, int style)
{
    Handle pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackFloat(pack, runtime);
    WritePackCell(pack, style);
    
    char szUName[MAX_NAME_LENGTH];

    if (IsValidClient(client))
		GetClientName(client, szUName, MAX_NAME_LENGTH);
	else
		return;

    //ESCPA NAME STRING
    char szName[MAX_NAME_LENGTH * 2 + 1];
    SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH * 2 + 1);
    
    //FORMAT UNIX TIMESTAMPS TO THE FORMAT USED IN THE DATABASE
    char szInitial_TimeStamp[32];
    char szFinal_TimeStamp[32];
    FormatTime(szInitial_TimeStamp, sizeof(szInitial_TimeStamp), "%F %X", g_iChallenge_Initial_TimeStamp);
    FormatTime(szFinal_TimeStamp, sizeof(szFinal_TimeStamp), "%F %X", g_iChallenge_Final_TimeStamp);
    
    char szQuery[255];
    for(int i = 0; i < MAX_STYLES; i++){
        Format(szQuery, sizeof(szQuery), "INSERT INTO ck_challenge_players (steamid, name, style, points) VALUES ('%s', '%s', '%i', '%i');", g_szSteamID[client], szName, i, 0);
        SQL_TQuery(g_hDb, sql_InsertPlayerCallback, szQuery, pack, DBPrio_Low);
    }
}

public void sql_InsertPlayerCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
    if (hndl == null)
	{
        LogError("[Map Challenge] SQL Error (sql_InsertPlayerCallback): %s", error);
        CloseHandle(pack);
        return;
    }
    
    ResetPack(pack);
    int client = ReadPackCell(pack);
    float runtime = ReadPackFloat(pack);
    int style = ReadPackCell(pack);
    
    db_TimesExistsCheck(client, runtime, style);
}


public void db_TimesExistsCheck(int client, float runtime, int style)
{
    if (!IsValidClient(client))
		return;
    
    Handle pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackFloat(pack, runtime);
    WritePackCell(pack, style);

	//FORMAT UNIX TIMESTAMPS TO THE FORMAT USED IN THE DATABASE
    char szInitial_TimeStamp[32];
    char szFinal_TimeStamp[32];
    FormatTime(szInitial_TimeStamp, sizeof(szInitial_TimeStamp), "%F %X", g_iChallenge_Initial_TimeStamp);
    FormatTime(szFinal_TimeStamp, sizeof(szFinal_TimeStamp), "%F %X", g_iChallenge_Final_TimeStamp);
    
    char szQuery[255];
    Format(szQuery, sizeof(szQuery), "SELECT runtime FROM ck_challenge_times WHERE steamid = '%s' AND mapname = '%s' AND runtime > -1.0 AND style = %i AND Run_Date BETWEEN '%s' AND '%s';", g_szSteamID[client], g_szMapName, style, szInitial_TimeStamp, szFinal_TimeStamp);
    SQL_TQuery(g_hDb, sql_TimesExistsCheckCallback, szQuery, pack, DBPrio_Low);
}

public void sql_TimesExistsCheckCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
	if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_TimesExistsCheckCallback): %s", error);
		CloseHandle(pack);
		return;
	}

	ResetPack(pack);
	int client = ReadPackCell(pack);
	float runtime = ReadPackFloat(pack);
	int style = ReadPackCell(pack);
    
    // Found old time from database
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){
        if(SQL_FetchFloat(hndl, 0) >= runtime)
            db_UpdateTime(client, runtime, style);
    }
	else{
        db_InsertTime(client, runtime, style);
    }
}

public void db_UpdateTime(int client, float runtime, int style)
{
	if (!IsValidClient(client))
		return;

	//FORMAT UNIX TIMESTAMPS TO THE FORMAT USED IN THE DATABASE
	char szInitial_TimeStamp[32];
	char szFinal_TimeStamp[32];
	FormatTime(szInitial_TimeStamp, sizeof(szInitial_TimeStamp), "%F %X", g_iChallenge_Initial_TimeStamp);
	FormatTime(szFinal_TimeStamp, sizeof(szFinal_TimeStamp), "%F %X", g_iChallenge_Final_TimeStamp);

	char szQuery[255];
	Format(szQuery, sizeof(szQuery), "UPDATE ck_challenge_times SET runtime = '%f' WHERE steamid = '%s' AND mapname = '%s' AND runtime > -1.0 AND style = %i AND Run_Date BETWEEN '%s' AND '%s';", runtime, g_szSteamID[client], g_szMapName, style, szInitial_TimeStamp, szFinal_TimeStamp);
	SQL_TQuery(g_hDb, sql_UpdateTimesCallback, szQuery, DBPrio_Low);
}

public void db_InsertTime(int client, float runtime, int style)
{
	char szUName[MAX_NAME_LENGTH];

	if (IsValidClient(client))
		GetClientName(client, szUName, MAX_NAME_LENGTH);
	else
		return;

	//ESCPA NAME STRING
	char szName[MAX_NAME_LENGTH * 2 + 1];
	SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH * 2 + 1);

	//FORMAT UNIX TIMESTAMPS TO THE FORMAT USED IN THE DATABASE
	char szInitial_TimeStamp[32];
	char szFinal_TimeStamp[32];
	FormatTime(szInitial_TimeStamp, sizeof(szInitial_TimeStamp), "%F %X", g_iChallenge_Initial_TimeStamp);
	FormatTime(szFinal_TimeStamp, sizeof(szFinal_TimeStamp), "%F %X", g_iChallenge_Final_TimeStamp);

	char szQuery[255];
	Format(szQuery, sizeof(szQuery), "INSERT INTO ck_challenge_times (id, steamid, name, mapname, runtime, style) VALUES ('%i', '%s', '%s', '%s', '%f', '%i');", g_iChallenge_ID, g_szSteamID[client], szName, g_szMapName, runtime, style);
	SQL_TQuery(g_hDb, sql_UpdateTimesCallback, szQuery, client, DBPrio_Low);
}

public void sql_UpdateTimesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_UpdateTimesCallback): %s", error);
		return;
    }
    else{
        CPrintToChat(data, "%t", "Challenge_NewTime", g_szChatPrefix);
    }
}

//SHOW PLAYERS PROFILE
//CODE BASE RETRIVED FROM https://github.com/surftimer/SurfTimer
public Action ChallengeProfile(int client, int args)
{
    char szSteamID[32];
    Format(szSteamID, sizeof(szSteamID), "");
    
    if(args > 0)
        GetCmdArg(0, szSteamID, sizeof(szSteamID));

    ProfileMenu(client, szSteamID);

    return Plugin_Handled;

}

public void ProfileMenu(int client, char szSteamID[32])
{
	if(StrEqual(szSteamID, ""))
	{
		char szPlayerName[MAX_NAME_LENGTH];
		Menu menu = CreateMenu(ProfilePlayerSelectMenuHandler);
		SetMenuTitle(menu, "Challenge Profile Menu - Choose a player\n------------------------------\n");
		GetClientName(client, szPlayerName, sizeof(szPlayerName));
		AddMenuItem(menu, szPlayerName, szPlayerName);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i) && i != client)
			{
				GetClientName(i, szPlayerName, sizeof(szPlayerName));
				AddMenuItem(menu, szPlayerName, szPlayerName);
			}
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else
	{
        db_viewPlayerProfile(client, szSteamID);
	}
}

public int ProfilePlayerSelectMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char szPlayerName[MAX_NAME_LENGTH];
		char szBuffer[MAX_NAME_LENGTH];
		char szSteamId[32];
		GetMenuItem(menu, param2, szPlayerName, sizeof(szPlayerName));
		for (int i = 0; i < MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
				GetClientName(i, szBuffer, sizeof(szBuffer));
				if (StrEqual(szPlayerName, szBuffer))
				{
					GetClientAuthId(i, AuthId_Steam2, szSteamId, 32, true);
					db_viewPlayerProfile(param1, szSteamId);
					break;	
				}
			}
		}
	}
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}

public void db_viewPlayerProfile(int client, char szSteamID[32])
{
    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), "SELECT * FROM ck_challenge_players WHERE steamid = '%s' ORDER BY style ASC;", szSteamID);
    SQL_TQuery(g_hDb, sql_viewPlayerProfileCallback, szQuery, client, DBPrio_Low);
}

public void sql_viewPlayerProfileCallback(Handle owner, Handle hndl, const char[] error, any client)
{
    if (hndl == null)
    {
        LogError("[Map Challenge] SQL Error (sql_viewPlayerProfileCallback): %s", error);
        return;
    }

    if (SQL_HasResultSet(hndl)){

        Menu menu = new Menu(Menu_ProfileHandler);

        char szItem[64];
        char szName[MAX_NAME_LENGTH];
        char szSteamID[32];
        int style;
        int points;
        int total_points = 0;

        while(SQL_FetchRow(hndl)){

            SQL_FetchString(hndl, 0, szSteamID, sizeof(szSteamID));
            SQL_FetchString(hndl, 1, szName, sizeof(szName));
            style = SQL_FetchInt(hndl, 2);
            points = SQL_FetchInt(hndl, 3);
            
            total_points = total_points + points;

            Format(szItem, sizeof(szItem), "%s - %i pts", g_szStyleMenuPrint[style], points);

            AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);

            if(style == 7)
                AddMenuItem(menu, "", "", ITEMDRAW_SPACER);

        }

        Format(szItem, sizeof(szItem), "Total Points - %i pts", total_points);
        AddMenuItem(menu, "", szItem, ITEMDRAW_DISABLED);

        menu.SetTitle("Challenge's Profile for %s\n%s\n", szName, szSteamID);

        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
        
    }

}

public int Menu_ProfileHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;

	return 0;
}


//SHOW OVERALL CHALLENGES LEADERBOARD (TOP 50)
//CODE BASE RETRIVED FROM https://github.com/surftimer/SurfTimer
public Action TopLeaderBoard(int client, int args)
{   
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    Menu menu = CreateMenu(TOPStyleSelectHandler);
    SetMenuTitle(menu, "Profile Menu - Select a style");
    AddMenuItem(menu, "0", "Normal");
    AddMenuItem(menu, "1", "Sideways");
    AddMenuItem(menu, "2", "Half-Sideways");
    AddMenuItem(menu, "3", "Backwards");
    AddMenuItem(menu, "4", "Low-Gravity");
    AddMenuItem(menu, "5", "Slow Motion");
    AddMenuItem(menu, "6", "Fast Forwards");
    AddMenuItem(menu, "7", "Freestyle");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public int TOPStyleSelectHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
        char szStyle[32];
        GetMenuItem(menu, param2, szStyle, sizeof(szStyle));
        
        db_DisplayOverallTOP(param1, StringToInt(szStyle));
	}
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}

public void db_DisplayOverallTOP(int client, int style)
{
    Handle pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackCell(pack, style);

    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), "SELECT steamid, name, points FROM ck_challenge_players WHERE style = '%i' ORDER BY points DESC LIMIT 50;", style);
    SQL_TQuery(g_hDb, sql_DisplayOverallTOPCallback, szQuery, pack, DBPrio_Low);

}

public void sql_DisplayOverallTOPCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
    if (hndl == null)
    {
        LogError("[Map Challenge] SQL Error (sql_DisplayOverallTOPCallback): %s", error);
        CloseHandle(pack);
        return;
    }
    
    ResetPack(pack);
    int client = ReadPackCell(pack);
    int style = ReadPackCell(pack);

    if (SQL_HasResultSet(hndl)){

        Menu menu = new Menu(Menu_OverallChallengeTopHandler);
        menu.SetTitle("Challenges TOP for %s\n    Rank      Points          Player\n", g_szStyleMenuPrint[style]);

        char szItem[64];
        int rank = 1;
        char szRank[16];

        while(SQL_FetchRow(hndl)){
            
            char szSteamID[32];
            SQL_FetchString(hndl, 0, szSteamID, 32);

            char szPlayerName[32];
            SQL_FetchString(hndl, 1, szPlayerName, sizeof(szPlayerName));

            int points = SQL_FetchInt(hndl, 2);

            //when uysing select it always return TRUE using SQL_HasResultSet() so I just compare the value of a column to an empty string for the first row returned
            if(strcmp(szPlayerName, "") == 0){
                CPrintToChat(client, "%t", "Overall_Challenge_LeaderBoard_Empty", g_szChatPrefix, g_szStyleMenuPrint[style]);
                return;
            }
            
            //if (rank >= 10)
            //    Format(szItem, sizeof(szItem), "[%i]     | %i pts   | %s", rank, points, szPlayerName);
            //else
            //    Format(szItem, sizeof(szItem), "[0%i]   | %i pts    | %s", rank, points, szPlayerName);

            if (rank < 10)
			    Format(szRank, 16, "[0%i]  ", rank);
			else
			    Format(szRank, 16, "[%i]  ", rank);

            if (points < 10)
			    Format(szItem, sizeof(szItem), "%s       %i pts        %s", szRank, points, szPlayerName);
			else if (points < 100)
			    Format(szItem, sizeof(szItem), "%s     %i pts        %s", szRank, points, szPlayerName);
			else if (points < 1000)
			    Format(szItem, sizeof(szItem), "%s   %i pts        %s", szRank, points, szPlayerName);
			else if (points < 10000)
			    Format(szItem, sizeof(szItem), "%s %i pts        %s", szRank, points, szPlayerName);
			else if (points < 1000000)
			    Format(szItem, sizeof(szItem), "%s %i pts   %s", szRank, points, szPlayerName);
			else
			    Format(szItem, sizeof(szItem), "%s %i pts %s", szRank, points, szPlayerName);

            AddMenuItem(menu, szSteamID, szItem, ITEMDRAW_DEFAULT);

            rank++;
        }
        
        SetMenuPagination(menu, 5);
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
        
    }
    else{
        CPrintToChat(client, "%t", "Overall_Challenge_LeaderBoard_Empty", g_szChatPrefix, g_szStyleMenuPrint[style]);
    }

}

public int Menu_OverallChallengeTopHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select){
        char szsteamid[32];
        GetMenuItem(menu, param2, szsteamid, sizeof(szsteamid));
        db_viewPlayerProfile(param1, szsteamid);
    }
	else if (action == MenuAction_End) {
		delete menu;
	}

    return 0;
}

//SHOW CHALLENGE LEADERBOARD
public Action LeaderBoard(int client, int args)
{   
    if(!IsValidClient(client))
        return Plugin_Handled;

    if(g_bIsChallengeActive)
        db_SelectCurrentChallengeTop(client);
    else
        CPrintToChat(client, "%t", "Challenge_Inactive", g_szChatPrefix);

    return Plugin_Handled;
}

public void db_SelectCurrentChallengeTop(int client)
{
    char szQuery[255];
    Format(szQuery, sizeof(szQuery), "SELECT name, runtime, style FROM ck_challenge_times WHERE id = '%i' ORDER BY runtime ASC LIMIT 50;", g_iChallenge_ID);
    SQL_TQuery(g_hDb, sql_SelectCurrentChallengeTopCallback, szQuery, client, DBPrio_Low);
}

public void sql_SelectCurrentChallengeTopCallback(Handle owner, Handle hndl, const char[] error, any client)
{
    if (hndl == null)
    {
        LogError("[Map Challenge] SQL Error (sql_SelectCurrentChallengeTopCallback): %s", error);
        return;
    }
    
    if (SQL_HasResultSet(hndl)){
        Menu menu = new Menu(Menu_ChallengeTopHandler);

        char szItem[64];
        int rank = 1;

        int style = -1;

        float rank_1_time = 0.0;
        float runtime_difference = 0.0;

        while(SQL_FetchRow(hndl)){

            char szPlayerName[32];
            SQL_FetchString(hndl, 0, szPlayerName, sizeof(szPlayerName));


            float player_runtime = SQL_FetchFloat(hndl, 1);
            char szFormattedRuntime[64];
            char szFormattedDifference[64];
            FormatTimeFloat(client, player_runtime, 3, szFormattedRuntime, sizeof(szFormattedRuntime));

            style = SQL_FetchInt(hndl, 2);

            switch(style){
                case 0: Format(szItem, sizeof(szItem), "[0%i]   | %s | (+00:00:00) | %s", rank, szFormattedRuntime, szPlayerName);
            }

        
            if(rank == 1){
                Format(szItem, sizeof(szItem), "[0%i]   | %s | (+00:00:00) | %s", rank, szFormattedRuntime, szPlayerName);
                rank_1_time = player_runtime;
            }
            else{
                FormatTimeFloat(client, player_runtime, 3, szFormattedRuntime, sizeof(szFormattedRuntime));

                runtime_difference = rank_1_time - player_runtime;
                FormatTimeFloat(client, runtime_difference, 3, szFormattedDifference, sizeof(szFormattedDifference));
                

                if (rank >= 10)
                    Format(szItem, sizeof(szItem), "[%i]     | %s | (+%s) | %s", rank, szFormattedRuntime, szFormattedDifference, szPlayerName);
                else
                    Format(szItem, sizeof(szItem), "[0%i]   | %s | (+%s) | %s", rank, szFormattedRuntime, szFormattedDifference, szPlayerName);
            }

            AddMenuItem(menu, "", szItem);

            rank++;
        }

        if(style == -1){
            CPrintToChat(client, "%t", "Challenge_LeaderBoard_Empty", g_szChatPrefix);
            return;
        }


        menu.SetTitle("Map Challenge TOP for %s | %s \n    Rank   Time           Difference         Player\n", g_sChallenge_MapName, g_szStyleMenuPrint[style]);

        SetMenuPagination(menu, 5);
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
        
    }
    else{
        CPrintToChat(client, "%t", "Challenge_LeaderBoard_Empty", g_szChatPrefix);
    }

}

public int Menu_ChallengeTopHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End) {
		delete menu;
	}

	return 0;
}

//SHOW CHALLENGE LEADERBOARD
public Action Challenge_Timeleft(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;

    if(g_bIsChallengeActive)
        db_GetRemainingTime(client);
    else
        CPrintToChat(client, "%t", "Challenge_Inactive", g_szChatPrefix);

    return Plugin_Handled;
}

public void db_GetRemainingTime(int client){

    if(g_bIsChallengeActive){
        char szQuery[255];
        Format(szQuery, sizeof(szQuery), "SELECT TIMESTAMPDIFF(SECOND,CURRENT_TIMESTAMP, EndDate) as Time_Diff FROM ck_challenges WHERE id = '%i';", g_iChallenge_ID);
        SQL_TQuery(g_hDb, sql_GetRemainingTimeCallback, szQuery, client, DBPrio_Low);
    }
    else{
        CPrintToChat(client, "%t", "Challenge_Inactive", g_szChatPrefix);
    }

}

public void sql_GetRemainingTimeCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_GetRemainingTimeCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){

        float timeleft = SQL_FetchInt(hndl, 0) * 1.0;

        if(timeleft > 0){
            char sztimeleft[32];
            FormatTimeFloat(data, timeleft, 7, sztimeleft, sizeof(sztimeleft));

            CPrintToChat(data, "%t", "Challenge_Timeleft", g_szChatPrefix, sztimeleft);
        }
    }

}

public Action Check_Challenge_End(Handle timer)
{
    if(g_bIsChallengeActive){
        char szQuery[1024];
        Format(szQuery, sizeof(szQuery), "SELECT TIMESTAMPDIFF(SECOND,CURRENT_TIMESTAMP, EndDate) as Time_Diff FROM ck_challenges WHERE id = '%i';", g_iChallenge_ID);
        SQL_TQuery(g_hDb, sql_Check_Challenge_EndCallback, szQuery, DBPrio_Low);
    }

    return Plugin_Handled;
}

public void sql_Check_Challenge_EndCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_Check_Challenge_EndCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){

        float time_diff = SQL_FetchInt(hndl, 0) * 1.0;

        char sztimeleft[32];

        if(time_diff <= 0){
            db_EndCurrentChallenge(0, g_iChallenge_ID);
        }
        else{
            FormatTimeFloat(data, time_diff, 7, sztimeleft, sizeof(sztimeleft));

            for(int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i) && !IsFakeClient(i)) {
                    CPrintToChat(i, "%t", "Challenge_Timeleft", g_szChatPrefix, sztimeleft);
                    CPrintToChat(i, "%t", "Challenge_Ongoing", g_szChatPrefix, g_sChallenge_MapName);
                }
            }
        }
    }
}

public void db_DistributePoints(int client){

    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), "SELECT steamid, style, name, mapname FROM ck_challenge_times WHERE id = '%i' ORDER BY runtime ASC;", g_iChallenge_ID);
    SQL_TQuery(g_hDb, sql_DistributePointsCallback, szQuery, client, DBPrio_Low);

}

public void sql_DistributePointsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_DistributePointsCallback): %s", error);
		return;
	}

    if (SQL_HasResultSet(hndl)) {
        ArrayList szTop5 = new ArrayList(32);

        if(SQL_GetRowCount(hndl) <= 0){
            SendChallengeEndForward(data, szTop5, 0);
            ResetDefaults();
            return;
        }

        int nr_players = SQL_GetRowCount(hndl);

        int rank = 1;
        char szPlayerSteamID[32];
        int style;
        int points_to_add;
        while(SQL_FetchRow(hndl)){
            SQL_FetchString(hndl, 0, szPlayerSteamID, sizeof(szPlayerSteamID));

            style = SQL_FetchInt(hndl, 1);

            if(rank == 1)
                points_to_add = g_iChallenge_Points;
            else if(1 < rank <= 10)
                points_to_add = (g_iChallenge_Points / 2) - ((rank-2) * 100);
            else
                points_to_add = 5;
    
            AddChallengePoints(szPlayerSteamID, style, points_to_add);

            if (rank <= 5) {
                char sztemp[32];
                SQL_FetchString(hndl, 2, sztemp, sizeof(sztemp));
                szTop5.PushString(sztemp);
            }

            if(rank == nr_players)
                SendChallengeEndForward(data, szTop5, nr_players);

            rank++;
        }

        CPrintToChatAll("%t", "Challenge_Points_Distributed", g_szChatPrefix);
    }

    ResetDefaults();
}

public void AddChallengePoints(char szSteamID[32], int style, int points_to_add)
{
    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), "UPDATE ck_challenge_players SET points = points + %i WHERE steamid = '%s' AND style = %i;", points_to_add, szSteamID, style);
    SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low); 
}

public Action Challenge_Info(int client, int args)
{   
    if(!IsValidClient(client))
        return Plugin_Handled;

    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), "SELECT id, mapname, StartDate, EndDate, points, style, TIMESTAMPDIFF(SECOND,CURRENT_TIMESTAMP, EndDate) as Time_Diff FROM ck_challenges WHERE active = 1;");
    SQL_TQuery(g_hDb, SQL_Challenge_InfoCallback, szQuery, client, DBPrio_Low); 

    return Plugin_Handled;
}

public void SQL_Challenge_InfoCallback(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (SQL_Challenge_InfoCallback): %s", error);
		return;
    }

    if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
    {
        Menu Challenge_Info_Menu = new Menu(Menu_Challenge_Info_Handler);
        Challenge_Info_Menu.SetTitle("Challenge Info\n");

        char szItem[64];

        //LOAD ALL THE VARIABLES
        int id = SQL_FetchInt(hndl, 0);

        char szMapName[32];
        SQL_FetchString(hndl, 1, szMapName, sizeof(szMapName));

        char Start_Date[32];
        SQL_FetchString(hndl, 2, Start_Date, sizeof(Start_Date));

        char End_Date[32];
        SQL_FetchString(hndl, 3, End_Date, sizeof(End_Date));

        int points = SQL_FetchInt(hndl, 4);

        int style = SQL_FetchInt(hndl, 5);

        float timeleft = SQL_FetchInt(hndl, 6) * 1.0;

        //FORMAT VARIABLES
        Format(szItem, sizeof(szItem), "Challenge # %d", id);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        Format(szItem, sizeof(szItem), "Map : %s", szMapName);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        Format(szItem, sizeof(szItem), "Style : %s", g_szStyleMenuPrint[style]);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        Format(szItem, sizeof(szItem), "Started : %s", Start_Date);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        Format(szItem, sizeof(szItem), "Ends : %s", End_Date);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        char sztimeleft[32];
        FormatTimeFloat(data, timeleft, 7, sztimeleft, sizeof(sztimeleft));
        Format(szItem, sizeof(szItem), "TimeLeft : %s", sztimeleft);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        Format(szItem, sizeof(szItem), "Rank 1 Points : %d", points);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        SetMenuExitButton(Challenge_Info_Menu, true);
        DisplayMenu(Challenge_Info_Menu, data, MENU_TIME_FOREVER);
    }
    else{
        CPrintToChat(data, "%t", "Challenge_Inactive", g_szChatPrefix);
    }
}

public int Menu_Challenge_Info_Handler(Menu menu, MenuAction action, int param1, int param2)
{   
    if (action == MenuAction_Select)
        return 0;
	else if(action == MenuAction_End){
		delete menu;
    }
    
    return 0;
}