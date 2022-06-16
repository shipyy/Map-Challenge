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
//int g_iCurrent_TimeStamp;
int g_iChallenge_Points;
int g_iChallenge_Style;
char g_sChallenge_MapName[32];

char g_szMapName[128];

// Client's steamID
char g_szSteamID[MAXPLAYERS + 1][32];

char g_szChatPrefix[64] = "[MAP CHALLENGE]";

/* ----- INCLUDES ----- */
#include <surftimer>
#include <colorlib>
#include "queries.sp"
#include "sql.sp"
#include "misc.sp"

stock bool IsValidClient(int client)
{
    PrintToServer("client index : %d", client);
    
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

}

public void OnMapStart(){

    db_setupDatabase();

    //COMMANDS
    RegConsoleCmd("sm_ct", LeaderBoard, "[surftimer] Displays the ongoing challenge leaderboard (TOP 50)");
    RegAdminCmd("sm_add_challenge", Create_Challenge, ADMFLAG_ROOT, "[surfTimer] Add new challenge");
    RegAdminCmd("sm_end_challenge", Manual_ChallengeEnd, ADMFLAG_ROOT, "[surfTimer] Ends the ongoing challenge");

    //CURRENT MAP NAME
    GetCurrentMap(g_szMapName, sizeof(g_szMapName));

    //CHECK CHALLENGE IS ACTIVE
    db_CheckChallengeActive();
}

public void db_CheckChallengeActive()
{
    char szQuery[255];
    PrintToServer(szQuery);
    Format(szQuery, sizeof(szQuery), "SELECT id, active, mapname, TIMESTAMPDIFF(SECOND,CURRENT_TIMESTAMP, EndDate) as Time_Diff FROM ck_challenges ORDER BY id DESC LIMIT 1;");
    SQL_TQuery(g_hDb, sql_CheckChallengeActiveCallback, szQuery, DBPrio_Low);
}

public void sql_CheckChallengeActiveCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
	if (hndl == null)
	{
		LogError("[SurfTimer] SQL Error (sql_CheckChallengeActiveCallback): %s", error);
		return;
	}

	// Found old time from database
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){
        if(SQL_FetchInt(hndl, 1) == 1){

            //CHECK IF CURRENT TIME STAMP IS NEWER THAN HE END_DATE OF THE CURRENT CHALLENGE
            int time_diff = SQL_FetchInt(hndl, 3);

            g_iChallenge_ID = SQL_FetchInt(hndl, 0);

            //REACHED END OF CHALLENGE
            if(time_diff <= 0){
                db_EndCurrentChallenge(g_iChallenge_ID);
            }
            else{
                g_bIsChallengeActive = true;
                SQL_FetchString(hndl, 2, g_sChallenge_MapName, sizeof(g_sChallenge_MapName));
                if(strcmp(g_szMapName, g_sChallenge_MapName))
                    g_bIsCurrentMapChallenge = true;
            }
        }
        else{
            g_bIsChallengeActive = false;
            g_iChallenge_ID = -1;
            SQL_FetchString(hndl, 2, g_sChallenge_MapName, sizeof(g_sChallenge_MapName));
        }
        PrintToServer("\n\n\n---CHECKED CHALLENGE---\n\n\n");
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
        style = 0;

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
        LogError("[SurfTimer] SQL Error (sql_selectMapNameEqualsCallback): %s", error);
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
    PrintToServer("\n\n\nADDING\n\n\n");

    g_sChallenge_MapName = szMapName;
    g_iChallenge_Points = points;
    g_iChallenge_Style = style;

    char szInitial_TimeStamp[32];
    //char szFinal_TimeStamp[32];

    //GET TIME STAMPS IN UNIX CODE
    g_iChallenge_Initial_TimeStamp = GetTime();
    //g_iChallenge_Final_TimeStamp = g_iChallenge_Initial_TimeStamp + ( 60 * 60 * (24 * duration) );

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

    SQL_ExecuteTransaction(g_hDb, add_challange_transactions, SQLTxn_AddChallenge_Success, SQLTxn_AddChallenge_Failed);
}

public void SQLTxn_AddChallenge_Success(Handle db, any data, int numQueries, Handle[] results, any[] queryData)
{   
    g_bIsChallengeActive = true;
    CPrintToChatAll("%t", "Challenge_Added", g_szChatPrefix, g_sChallenge_MapName);
    PrintToServer("[Map Challenge] Challenge Successfully Created");
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
        db_EndCurrentChallenge(g_iChallenge_ID);
    else
        CPrintToChat(client, "%t", "Challenge_Inactive", g_szChatPrefix);
    
    return Plugin_Handled;
}

public void db_EndCurrentChallenge(int challenge_ID)
{

    char szQuery[256];
    Format(szQuery, sizeof(szQuery), "UPDATE ck_challenges SET active = 0 WHERE id = '%i';", challenge_ID);
    SQL_TQuery(g_hDb, sql_EndCurrentChallengeCallback, szQuery, challenge_ID, DBPrio_Low);
}

public void sql_EndCurrentChallengeCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
    if (hndl == null)
    {
        LogError("[Map Challange] SQL Error (sql_EndCurrentChallengeCallback): %s", error);
        return;
    }
    else{

        //SET DEFAULTS
        g_bIsChallengeActive = false;
        g_bIsCurrentMapChallenge = false;
        g_iChallenge_ID = g_iChallenge_ID + 1; // incremented because challenges could be being created/deleted within the same map session

        g_iChallenge_Initial_TimeStamp = 0;
        g_iChallenge_Final_TimeStamp = 0;
        g_iChallenge_Points = 0;
        g_iChallenge_Style = 0;
        g_sChallenge_MapName = "";

        CPrintToChatAll("%t", "Challenge_Ended", g_szChatPrefix);
    }
}

public Action surftimer_OnMapFinished(int client, float fRunTime, char sRunTime[54], int rank, int total)
{
    
    if(g_bIsCurrentMapChallenge && g_bIsChallengeActive)
        db_TimesExistsCheck(client, fRunTime);

    return Plugin_Handled;
}

public void db_TimesExistsCheck(int client, float runtime)
{
	if (!IsValidClient(client))
		return;

	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackFloat(pack, runtime);

	//FORMAT UNIX TIMESTAMPS TO THE FORMAT USED IN THE DATABASE
	char szInitial_TimeStamp[32];
	char szFinal_TimeStamp[32];
	FormatTime(szInitial_TimeStamp, sizeof(szInitial_TimeStamp), "%F %X", g_iChallenge_Initial_TimeStamp);
	FormatTime(szFinal_TimeStamp, sizeof(szFinal_TimeStamp), "%F %X", g_iChallenge_Final_TimeStamp);

	char szQuery[255];
	Format(szQuery, sizeof(szQuery), "SELECT runtime FROM ck_challenge_times WHERE steamid = '%s' AND mapname = '%s' AND runtimepro > -1.0 AND style = 0 AND Run_Date BETWEEN '%s' AND '%s';", g_szSteamID[client], g_szMapName, szInitial_TimeStamp, szFinal_TimeStamp);
	SQL_TQuery(g_hDb, sql_TimesExistsCheckCallback, szQuery, pack, DBPrio_Low);
}

public void sql_TimesExistsCheckCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
	if (hndl == null)
	{
		LogError("[SurfTimer] SQL Error (sql_TimesExistsCheckCallback): %s", error);
		CloseHandle(pack);
		return;
	}

	ResetPack(pack);
	int client = ReadPackCell(pack);
	float runtime = ReadPackFloat(pack);

	if (!IsValidClient(pack))
		return;

	// Found old time from database
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		db_UpdateTime(client, runtime, 0);
	else
		db_InsertTime(client, runtime, 0);

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
	Format(szQuery, sizeof(szQuery), "UPDATE ck_challenge_times SET runtime = '%f' WHERE steamid = '%s' AND mapname = '%s' AND runtimepro > -1.0 AND style = 0 AND Run_Date BETWEEN '%s' AND '%s';", runtime, g_szSteamID[client], g_szMapName, szInitial_TimeStamp, szFinal_TimeStamp);
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
	Format(szQuery, sizeof(szQuery), "INSERT INTO ck_challenge_times (steamid, name, mapname, runtime, style) VALUES ('%s', '%s', '%s', '%f', '%i');", g_szSteamID[client], szName, g_szMapName, runtime, style);
	SQL_TQuery(g_hDb, sql_UpdateTimesCallback, szQuery, DBPrio_Low);
}

public void sql_UpdateTimesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_UpdateTimesCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		PrintToServer("[Map Challenge] SQL Operation Successfull");
	else
        PrintToServer("[Map Challenge] SQL Error (sql_UpdateTimesCallback): %s", error);

}

//SHOW CHALLENGE LEADERBOARD
public Action LeaderBoard(int client, int args)
{
    db_SelectChallengeTop(client);

    return Plugin_Handled;
}

public void db_SelectChallengeTop(int client){

    if(g_bIsChallengeActive){
        char szQuery[255];
        Format(szQuery, sizeof(szQuery), "SELECT name, runtime FROM ck_challenge_times WHERE id = '%i' ORDER BY runtime ASC LIMIT 50;", g_iChallenge_ID);
        SQL_TQuery(g_hDb, sql_SelectChallengeTopCallback, szQuery, client, DBPrio_Low);
    }
    else{
        CPrintToChat(client, "%t", "Challenge_Inactive", g_szChatPrefix);
    }

}

public void sql_SelectChallengeTopCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_SelectChallengeTopCallback): %s", error);
		return;
	}

        if (SQL_HasResultSet(hndl)){

            Menu menu = new Menu(Menu_ChallengeTopHandler);
            menu.SetTitle("Map Challenge TOP for %s \n    Rank    Time               Player\n", g_sChallenge_MapName);

            char szItem[64];
            int rank=1;

            float rank_1_time = 0.0;
            float runtime_difference = 0.0;
            while(SQL_FetchRow(hndl)){
                char szPlayerName[32];
                SQL_FetchString(hndl, 0, szPlayerName, sizeof(szPlayerName));

                float player_runtime = SQL_FetchFloat(hndl, 1);
                char szFormattedRuntime[64];
                FormatTimeFloat(1, player_runtime, 3, szFormattedRuntime, sizeof(szFormattedRuntime));

            
                if(rank == 1){
                    Format(szItem, sizeof(szItem), "[0%i]    | (%s) %s|   %s", rank, szFormattedRuntime, "ㅤ",szPlayerName);
                    rank_1_time = player_runtime;
                }
                else{
                    szFormattedRuntime = "";
                    runtime_difference = rank_1_time - player_runtime;
                    FormatTimeFloat(1, runtime_difference, 3, szFormattedRuntime, sizeof(szFormattedRuntime));

                    if (rank >= 10)
                        Format(szItem, sizeof(szItem), "[%i]    | (+%s) |   %s", rank, szFormattedRuntime, szPlayerName);
                    else
                        Format(szItem, sizeof(szItem), "[0%i]    | (+%s) |   %s", rank, szFormattedRuntime, szPlayerName);
                }

                AddMenuItem(menu, "", szItem);

                rank++;
            }
            
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