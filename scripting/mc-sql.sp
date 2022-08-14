/////
//DATABASE INIT
/////

public void db_setupDatabase()
{
	char szError[255];
	g_hDb = SQL_Connect("surftimer", false, szError, 255);

	if (g_hDb == null)
		SetFailState("[Map Challenge] Unable to connect to database (%s)", szError);

	char szIdent[8];
	SQL_ReadDriver(g_hDb, szIdent, 8);

	if (strcmp(szIdent, "mysql", false) != 0) {
		SetFailState("[Map Challenge] Invalid database type");
	}

	// If tables haven't been created yet.
	if (!SQL_FastQuery(g_hDb, "SELECT name FROM ck_challenge_players LIMIT 1"))
	{
		SQL_UnlockDatabase(g_hDb);
		db_createTables();
		return;
	}
	
	SQL_UnlockDatabase(g_hDb);

}

public void db_createTables()
{
	Transaction createTableTnx = SQL_CreateTransaction();

	SQL_AddQuery(createTableTnx, sql_CreateChallenges);
	SQL_AddQuery(createTableTnx, sql_CreateChallenges_Times);
	SQL_AddQuery(createTableTnx, sql_CreateChallenges_Players);
	SQL_AddQuery(createTableTnx, sql_CreateFinished_Challenges);

	SQL_ExecuteTransaction(g_hDb, createTableTnx, SQLTxn_CreateDatabaseSuccess, SQLTxn_CreateDatabaseFailed);

}

public void SQLTxn_CreateDatabaseSuccess(Handle db, any data, int numQueries, Handle[] results, any[] queryData)
{
	PrintToServer("[Map Challenge] Database tables succesfully created!");
}

public void SQLTxn_CreateDatabaseFailed(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	SetFailState("[Map Challenge] Database tables could not be created! Error: %s", error);
}

public void SQL_CheckCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (SQL_CheckCallback): %s", error);
		return;
	}
}

/////
//DATA QUERING
/////

//CHECK IF THERE IS A ONGOING CHALLENGE
public void db_CheckChallengeActive()
{
    char szQuery[255];
    Format(szQuery, sizeof(szQuery), sql_CheckActiveChallenge);
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

            SQL_FetchString(hndl, 4, g_sChallenge_InitialDate, sizeof(g_sChallenge_InitialDate));
            SQL_FetchString(hndl, 5, g_sChallenge_FinalDate, sizeof(g_sChallenge_FinalDate));

            g_fChallenge_Initial_UNIX = SQL_FetchFloat(hndl, 6);
            g_fChallenge_Final_UNIX = SQL_FetchFloat(hndl, 7);

            //CHECK IF CURRENT TIME STAMP IS NEWER THAN HE END_DATE OF THE CURRENT CHALLENGE
            float time_diff = SQL_FetchFloat(hndl, 8);
            g_iChallenge_Points = SQL_FetchInt(hndl, 3);

            g_iChallenge_ID = SQL_FetchInt(hndl, 0);

            //REACHED END OF CHALLENGE
            if(time_diff <= 0.0){
                db_EndCurrentChallenge(0, g_iChallenge_ID);
            }
            else{
                g_bIsChallengeActive = true;

                if(StrEqual(g_szMapName, g_sChallenge_MapName, false))
                    g_bIsCurrentMapChallenge = true;
            }
        }
        else{
            ResetDefaults();
            //g_iChallenge_ID = SQL_FetchInt(hndl, 0);
            //SQL_FetchString(hndl, 2, g_sChallenge_MapName, sizeof(g_sChallenge_MapName));
        }
    }
}

//CHALLENGE CREATION
public void db_selectMapNameEquals(int client, char szMapName[32], int style, int points, float duration)
{
    Handle pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackString(pack, szMapName);
    WritePackCell(pack, style);
    WritePackCell(pack, points);
    WritePackFloat(pack, duration);

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
    float duration = ReadPackFloat(pack);
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

public void db_AddChallenge(int client, char szMapName[32], int style, int points, float duration)
{

    if(StrEqual(szMapName, g_szMapName, false))
        g_bIsCurrentMapChallenge = true;

    char szQuery_Insert[1024];

    int days;
    int hours;
    char szStart[512];
    char szEnd[512];

    days = RoundToZero(duration);
    hours = RoundToZero(FloatAbs(FloatFraction(duration)) * 12 / 0.5);
    Format(szStart, sizeof szStart, "UTC_TIMESTAMP(6)");
    Format(szEnd, sizeof szStart, "UTC_TIMESTAMP(6) + INTERVAL %i DAY + INTERVAL %i HOUR", days, hours);

    Format(szQuery_Insert, sizeof(szQuery_Insert), sql_InsertChallenge, szMapName, szStart, szEnd, style, points, 1);

    Transaction add_challange_transactions = SQL_CreateTransaction();
    SQL_AddQuery(add_challange_transactions, szQuery_Insert);
    SQL_AddQuery(add_challange_transactions, "SELECT StartDate, EndDate, UNIX_TIMESTAMP(StartDate), UNIX_TIMESTAMP(EndDate), mapname, points, style, id FROM ck_challenges ORDER BY id DESC LIMIT 1;");

    SQL_ExecuteTransaction(g_hDb, add_challange_transactions, SQLTxn_AddChallenge_Success , SQLTxn_AddChallenge_Failed, client);
}

public void SQLTxn_AddChallenge_Success(Handle db, any data, int numQueries, Handle[] results, any[] queryData)
{   
    g_bIsChallengeActive = true;

    CreateTimer(30.0, Check_Challenge_End, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
    CreateTimer(360.0, Check_Challenge_Timeleft, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

    if (SQL_HasResultSet(results[1]) && SQL_FetchRow(results[1])) {
        SQL_FetchString(results[1], 0, g_sChallenge_InitialDate, sizeof(g_sChallenge_InitialDate));
        SQL_FetchString(results[1], 1, g_sChallenge_FinalDate, sizeof(g_sChallenge_FinalDate));

        g_fChallenge_Initial_UNIX = SQL_FetchFloat(results[1], 2);
        g_fChallenge_Final_UNIX = SQL_FetchFloat(results[1], 3);

        SQL_FetchString(results[1], 4, g_sChallenge_MapName, sizeof g_sChallenge_MapName);

        g_iChallenge_Points = SQL_FetchInt(results[1], 5);
        g_iChallenge_Style = SQL_FetchInt(results[1], 6);

        g_iChallenge_ID = SQL_FetchInt(results[1], 7);

        CPrintToChatAll("%t", "Challenge_Added", g_szChatPrefix, g_sChallenge_MapName);
    }

    PrintToServer("[Map Challenge] Challenge Successfully Created");

    SendNewChallengeForward(data);
}

public void SQLTxn_AddChallenge_Failed(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	PrintToServer("[Map Challenge] Challenge Creation Failed %s", error);
}

/////
//END CHALLENGE
/////
public void db_EndCurrentChallenge(int client, int challenge_ID)
{
    char szQuery[256];
    Format(szQuery, sizeof(szQuery), sql_EndChallenge, challenge_ID);
    SQL_TQuery(g_hDb, sql_EndCurrentChallengeCallback, szQuery, client, DBPrio_Low);
}

public void sql_EndCurrentChallengeCallback(Handle owner, Handle hndl, const char[] error, any client)
{
    if (hndl == null)
    {
        LogError("[Map Challange] SQL Error (sql_EndCurrentChallengeCallback): %s", error);
        return;
    }
    
    db_AddFinishedChallenge(client);
}

public void db_DistributePoints(int client){

    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), sql_SelectParticipants, g_iChallenge_ID);
    SQL_TQuery(g_hDb, sql_DistributePointsCallback, szQuery, client, DBPrio_Low);

}

/////
//DISTRIBUTE POINTS TO PARTICIPANTS
/////
public void sql_DistributePointsCallback(Handle owner, Handle hndl, const char[] error, any client)
{
    if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_DistributePointsCallback): %s", error);
		return;
	}

    if (SQL_HasResultSet(hndl)) {
        ArrayList szTop5 = new ArrayList(sizeof TOP5_entry);

        if(SQL_GetRowCount(hndl) <= 0){
            SendChallengeEndForward(client, szTop5, 0);
            db_UpdateFinishedChallengeData(client, "none", 0);
            ResetDefaults();
            CPrintToChatAll("%t", "Challenge_Ended", g_szChatPrefix, 0, g_sChallenge_MapName);
            return;
        }

        int nr_players = SQL_GetRowCount(hndl);

        int rank = 1;
        float winner_runtime;
        char szPlayerSteamID[32];
        int style;
        int points_to_add;
        while(SQL_FetchRow(hndl)){
            SQL_FetchString(hndl, 0, szPlayerSteamID, sizeof(szPlayerSteamID));

            style = SQL_FetchInt(hndl, 1);

            if(rank == 1){
                points_to_add = g_iChallenge_Points;
                winner_runtime = SQL_FetchFloat(hndl, 4);
                db_UpdateFinishedChallengeData(client, szPlayerSteamID, nr_players);
            }
            else if(1 < rank <= 10)
                points_to_add = RoundUp(RoundToZero(g_iChallenge_Points * (1.0 - ((rank-1) * 0.1))));
            else
                points_to_add = 5;
    
            AddChallengePoints(szPlayerSteamID, style, points_to_add);

            if (rank <= 5) {
                TOP5_entry temp;

                SQL_FetchString(hndl, 2, temp.szPlayerName, sizeof(temp.szPlayerName));

                float temp_runtime;
                temp_runtime = SQL_FetchFloat(hndl, 4);
                FormatTimeFloat(client, temp_runtime, temp.szRuntimeFormatted, sizeof temp.szRuntimeFormatted, true);

                float runtime_difference;
                runtime_difference = winner_runtime - temp_runtime;
                FormatTimeFloat(client, runtime_difference * -1.0, temp.szRuntimeDifference, sizeof temp.szRuntimeDifference, true);

                szTop5.PushArray(temp, sizeof(temp));
            }

            if(rank == nr_players)
                SendChallengeEndForward(client, szTop5, nr_players);

            rank++;
        }

        CPrintToChatAll("%t", "Challenge_Points_Distributed", g_szChatPrefix);
        CPrintToChatAll("%t", "Challenge_Ended", g_szChatPrefix, nr_players, g_sChallenge_MapName);
    }

    ResetDefaults();
}

public void AddChallengePoints(char szSteamID[32], int style, int points_to_add)
{
    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), sql_AddPoints, points_to_add, szSteamID, style);
    SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low); 
}

/////
//ADD FINISHED CHALLENGE DATA TO CK_FINISHED_CHALLENGES
/////
public void db_AddFinishedChallenge(int client)
{
    Transaction finished_challenge_transaction = SQL_CreateTransaction();

    char szQuery[1024];
    Format(szQuery, sizeof szQuery, sql_InsertFinishedChallenge, g_iChallenge_ID, g_iChallenge_ID, g_iChallenge_ID);

    SQL_AddQuery(finished_challenge_transaction, szQuery);

    SQL_ExecuteTransaction(g_hDb, finished_challenge_transaction, finished_challenge_transaction_Success , finished_challenge_transaction_Failed, client, DBPrio_High);
}

public void finished_challenge_transaction_Success(Handle db, any client, int numQueries, Handle[] results, any[] queryData)
{
    PrintToServer("[MapChallenge] Finished Challenge Transaction Sucessfully Done!");
    db_DistributePoints(client);
}

public void finished_challenge_transaction_Failed(Handle db, any pack, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    if (strcmp(error, "",false) != 0)
	    LogError("[MapChallenge] SQL Error (finished_challenge_transaction): %s", error);
    else
        PrintToServer("[MapChallenge] Finished Challenge Transaction already performed by another server!");
}

public void db_UpdateFinishedChallengeData(int client, char szPlayerSteamID[32], int nr_players)
{
    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), sql_UpdateFinishedChallengeData, szPlayerSteamID, nr_players, g_sChallenge_MapName, g_iChallenge_Style, g_iChallenge_Points, g_iChallenge_ID);
    SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low); 
}


/////
//ON MAP FINISHED DATA HANDLING
////
public void db_PlayerExistsCheck(int client, float runtime, int style)
{
    if (!IsValidClient(client))
		return;
    
    Handle pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackFloat(pack, runtime);
    WritePackCell(pack, style);
    
    char szQuery[255];
    Format(szQuery, sizeof(szQuery), sql_SelectPlayerWithStyle, g_szSteamID[client], style);
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
    CloseHandle(pack);

    if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
        db_TimesExistsCheck(client, runtime, style);
    else
        db_InsertPlayer(client, runtime, style);
}

public void db_InsertPlayer(int client, float runtime, int style)
{
    //INSERT PROFILES
    Handle data = CreateDataPack();
    WritePackCell(data, client);
    WritePackFloat(data, runtime);
    WritePackCell(data, style);

    Transaction InsertProfiles = SQL_CreateTransaction();

    char szUName[MAX_NAME_LENGTH];
    
    GetClientName(client, szUName, MAX_NAME_LENGTH);

    //ESCAPE NAME STRING
    char szName[MAX_NAME_LENGTH * 2 + 1];
    SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH * 2 + 1);

    char szQuery[255];
    for(int i = 0; i < MAX_STYLES; i++){
        Format(szQuery, sizeof(szQuery), sql_InsertPlayer, g_szSteamID[client], szName, i, 0);
        SQL_AddQuery(InsertProfiles, szQuery);
    }

    SQL_ExecuteTransaction(g_hDb, InsertProfiles, SQLTxn_CreateProfilesSuccess, SQLTxn_CreateProfilesFailed, data);
}

public void SQLTxn_CreateProfilesSuccess(Handle db, any data, int numQueries, Handle[] results, any[] queryData)
{
    PrintToServer("[Map Challenge] Player Profiles succesfully created!");

    ResetPack(data);
    int client = ReadPackCell(data);
    float runtime = ReadPackFloat(data);
    int style = ReadPackCell(data);
    CloseHandle(data);

    db_TimesExistsCheck(client, runtime, style);
}

public void SQLTxn_CreateProfilesFailed(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    CloseHandle(data);
    LogError("[Map Challenge] Player Profile's could not be created! Error: %s", error);
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
    CloseHandle(pack);
    
    db_TimesExistsCheck(client, runtime, style);
}

public void db_TimesExistsCheck(int client, float runtime, int style)
{
    Handle pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackFloat(pack, runtime);
    WritePackCell(pack, style);
    
    char szQuery[255];
    Format(szQuery, sizeof(szQuery), sql_CheckRuntimeExists, g_szSteamID[client], g_szMapName, style, g_sChallenge_InitialDate, g_sChallenge_FinalDate);
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
        if(runtime <= SQL_FetchFloat(hndl, 0))
            db_UpdateTime(client, runtime, style);
    }
	else{
        db_InsertTime(client, runtime, style);
    }
}

public void db_UpdateTime(int client, float runtime, int style)
{
    char szQuery[255];
    Format(szQuery, sizeof(szQuery), sql_UpdateRuntime, runtime, g_szSteamID[client], g_szMapName, style, g_sChallenge_InitialDate, g_sChallenge_FinalDate);
    SQL_TQuery(g_hDb, sql_UpdateTimesCallback, szQuery, client, DBPrio_Low);
}

public void db_InsertTime(int client, float runtime, int style)
{
    char szUName[MAX_NAME_LENGTH];
    GetClientName(client, szUName, MAX_NAME_LENGTH);

	//ESCAPE NAME STRING
    char szName[MAX_NAME_LENGTH * 2 + 1];
    SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH * 2 + 1);
    
    char szStart[512];
    Format(szStart, sizeof szStart, "UTC_TIMESTAMP(6)");

    char szQuery[255];
    Format(szQuery, sizeof(szQuery), sql_InsertRuntime, g_iChallenge_ID, g_szSteamID[client], szName, g_szMapName, runtime, style, szStart);
    SQL_TQuery(g_hDb, sql_UpdateTimesCallback, szQuery, client, DBPrio_Low);
}

public void sql_UpdateTimesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null) {
		LogError("[Map Challenge] SQL Error (sql_UpdateTimesCallback): %s", error);
		return;
    }
    else {
        CPrintToChat(data, "%t", "Challenge_NewTime", g_szChatPrefix);
    }
}

/////
//PLAYER PROFILES
/////
public void db_viewPlayerProfile(int client, char szSteamID[32])
{
    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), sql_SelectPlayerProfile, szSteamID);
    SQL_TQuery(g_hDb, sql_viewPlayerProfileCallback, szQuery, client, DBPrio_Low);
}

public void sql_viewPlayerProfileCallback(Handle owner, Handle hndl, const char[] error, any client)
{
    if (hndl == null)
    {
        LogError("[Map Challenge] SQL Error (sql_viewPlayerProfileCallback): %s", error);
        return;
    }

    if (SQL_HasResultSet(hndl) && SQL_GetRowCount(hndl) != 0){

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
    else {
        char szName[MAX_NAME_LENGTH];
        GetClientName(client, szName, MAX_NAME_LENGTH);
        CPrintToChat(client, "%t", "player_data_not_found", g_szChatPrefix, szName);
    }

}

public int Menu_ProfileHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
		delete menu;

	return 0;
}

public void db_GetPlayerSteamdID(int client, char szPlayerName[MAX_NAME_LENGTH])
{   
    Handle pack = CreateDataPack();
    WritePackCell(pack, client);
    WritePackString(pack, szPlayerName);

    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), "SELECT steamid FROM ck_challenge_players WHERE name = '%s';", szPlayerName);
    SQL_TQuery(g_hDb, sql_DGetPlayerSteamdIDCallback, szQuery, pack, DBPrio_Low);
}

public void sql_DGetPlayerSteamdIDCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
    if (hndl == null)
    {
        LogError("[Map Challenge] SQL Error (sql_DGetPlayerSteamdIDCallback): %s", error);
        CloseHandle(pack);
        return;
    }

    ResetPack(pack);
    int client = ReadPackCell(pack);
    char szPlayerName[MAX_NAME_LENGTH];
    ReadPackString(pack, szPlayerName, sizeof szPlayerName);
    CloseHandle(pack);

    if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){
        char szSteamID[32];
        SQL_FetchString(hndl, 0, szSteamID, sizeof szSteamID);
        db_viewPlayerProfile(client, szSteamID);
    }
    else {
        CPrintToChat(client, "%t", "player_not_found", g_szChatPrefix, szPlayerName);
    }
}

/////
//DISPLAY TOP CHALLENGE PLAYERS LEADERBOARD
/////
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
    CloseHandle(pack);

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
            //if(SQL_GetRowCount(hndl) == 0)
            if(strcmp(szPlayerName, "") == 0){
                CPrintToChat(client, "%t", "Overall_Challenge_LeaderBoard_Empty", g_szChatPrefix, g_szStyleMenuPrint[style]);
                return;
            }

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

/////
//DISPLAY CURRENT CHALLENGE LEADERBOARD
/////
public void db_SelectCurrentChallengeTop(int client)
{
    char szQuery[255];
    Format(szQuery, sizeof(szQuery), sql_SelectCurrentChallengeLeaderboard, g_iChallenge_ID);
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
            FormatTimeFloat(client, player_runtime, szFormattedRuntime, sizeof(szFormattedRuntime), true);

            style = SQL_FetchInt(hndl, 2);

            switch(style){
                case 0: Format(szItem, sizeof(szItem), "[0%i]   | %s | (+00:00:000) | %s", rank, szFormattedRuntime, szPlayerName);
            }

        
            if(rank == 1){
                Format(szItem, sizeof(szItem), "[0%i]   | %s | (+00:00:000) | %s", rank, szFormattedRuntime, szPlayerName);
                rank_1_time = player_runtime;
            }
            else{
                FormatTimeFloat(client, player_runtime, szFormattedRuntime, sizeof(szFormattedRuntime), true);
                
                runtime_difference = rank_1_time - player_runtime;
                FormatTimeFloat(client, runtime_difference * -1.0, szFormattedDifference, sizeof(szFormattedDifference), true);
                

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


        menu.SetTitle("Map Challenge TOP for %s | %s \n    Rank   Time            Difference          Player\n", g_sChallenge_MapName, g_szStyleMenuPrint[style]);

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

/////
//DISPLAY CURRENT CHALLENGE TIMELEFT
/////
public void db_GetRemainingTime(int client){

    if(g_bIsChallengeActive){
        char szQuery[255];
        Format(szQuery, sizeof(szQuery), sql_RemainingTime, g_iChallenge_ID);
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

        float timeleft = SQL_FetchFloat(hndl, 0);
        
        if(timeleft > 0.0){
            char sztimeleft[32];
            FormatTimeFloat(data, timeleft, sztimeleft, sizeof(sztimeleft), false);

            CPrintToChat(data, "%t", "Challenge_Timeleft", g_szChatPrefix, sztimeleft);
        }
    }

}

public void db_GetRemainingTime_Timer(){

    if(g_bIsChallengeActive){
        char szQuery[255];
        Format(szQuery, sizeof(szQuery), sql_RemainingTime, g_iChallenge_ID);
        SQL_TQuery(g_hDb, sql_GetRemainingTime_TimerCallback, szQuery, DBPrio_Low);
    }

}

public void sql_GetRemainingTime_TimerCallback(Handle owner, Handle hndl, const char[] error, any data){

    if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_GetRemainingTime_TimerCallback): %s", error);
		return;
	}
    
    if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){

        char sztimeleft[32];

        float timeleft = SQL_FetchFloat(hndl, 0);

        if(timeleft > 0.0){
            for(int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i) && !IsFakeClient(i)) {

                    FormatTimeFloat(i, timeleft, sztimeleft, sizeof sztimeleft, false);

                    if( strcmp(g_szMapName, g_sChallenge_MapName, false) != 0 )
                        CPrintToChat(i, "%t", "Challenge_Ongoing", g_szChatPrefix, g_sChallenge_MapName);
                    else
                        CPrintToChat(i, "%t", "Challenge_Timeleft", g_szChatPrefix, sztimeleft);
                }
            }
        }
    }
}

/////
//CHECK IF CURRENT CHALLENGE HAS ENDED
/////
public void db_CheckChallengeEnd(){
	char szQuery[1024];
	Format(szQuery, sizeof(szQuery), sql_RemainingTime, g_iChallenge_ID);
	SQL_TQuery(g_hDb, sql_Check_Challenge_EndCallback, szQuery, DBPrio_Low);
}

public void sql_Check_Challenge_EndCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Map Challenge] SQL Error (sql_Check_Challenge_EndCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)){

        float time_diff = SQL_FetchFloat(hndl, 0);

        if(time_diff <= 0.0){
            db_EndCurrentChallenge(0, g_iChallenge_ID);
        }
    }
}

/////
//DISPLAY CURRENT CHALLENGE INFO
/////
public void db_ChallengeInfo(int client){
    char szQuery[1024];
    Format(szQuery, sizeof(szQuery), sql_ChallengeInfo);
    SQL_TQuery(g_hDb, SQL_Challenge_InfoCallback, szQuery, client, DBPrio_Low); 
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

        char szMapName[64];
        SQL_FetchString(hndl, 1, szMapName, sizeof(szMapName));

        char szStartDate[64];
        SQL_FetchString(hndl, 2, szStartDate, sizeof(szStartDate));

        char szEndDate[64];
        SQL_FetchString(hndl, 3, szEndDate, sizeof(szEndDate));

        int points = SQL_FetchInt(hndl, 4);

        int style = SQL_FetchInt(hndl, 5);

        float timeleft = SQL_FetchFloat(hndl, 6);

        //FORMAT VARIABLES
        Format(szItem, sizeof(szItem), "Challenge # %d", id);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        Format(szItem, sizeof(szItem), "Map : %s", szMapName);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        Format(szItem, sizeof(szItem), "Style : %s", g_szStyleMenuPrint[style]);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        //SPLIT TIME FROM DATE
        char splitsStart[2][256];
        ExplodeString(szStartDate, " ", splitsStart, sizeof(splitsStart), sizeof(splitsStart[]));
        //SPLIT EVERY TIME ELEMENT ( HOURS, MINUTES...)
        char splitsStart_Time[3][256];
        ExplodeString(splitsStart[1], ":", splitsStart_Time, sizeof(splitsStart_Time), sizeof(splitsStart_Time[]));
        //SPLIT DATE
        char splitsStart_Date[3][256];
        ExplodeString(splitsStart[0], "-", splitsStart_Date, sizeof(splitsStart_Date), sizeof(splitsStart_Date[]));

        int seconds = StringToInt(splitsStart_Time[2]);
        int ms = RoundToZero(FloatFraction(StringToFloat(splitsStart_Time[2])) * 1000);

        Format(szItem, sizeof(szItem), "Started : (UTC) %sh %sm %ds %dms  %s-%s-%s", splitsStart_Time[0], splitsStart_Time[1], seconds, ms, splitsStart_Date[2], splitsStart_Date[1], splitsStart_Date[0]);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);
        
        //SPLIT TIME FROM DATE
        char splitsEnd[2][256];
        ExplodeString(szEndDate, " ", splitsEnd, sizeof(splitsEnd), sizeof(splitsEnd[]));
        //SPLIT EVERY TIME ELEMENT ( HOURS, MINUTES...)
        char splitsEnd_Time[3][256];
        ExplodeString(splitsEnd[1], ":", splitsEnd_Time, sizeof(splitsEnd_Time), sizeof(splitsEnd_Time[]));
        //SPLIT DATE
        char splitsEnd_Date[3][256];
        ExplodeString(splitsEnd[0], "-", splitsEnd_Date, sizeof(splitsEnd_Date), sizeof(splitsEnd_Date[]));

        seconds = StringToInt(splitsEnd_Time[2]);
        ms = RoundToZero(FloatFraction(StringToFloat(splitsEnd_Time[2])) * 1000);

        Format(szItem, sizeof(szItem), "Ends : (UTC) %sh %sm %ds %dms  %s-%s-%s", splitsEnd_Time[0], splitsEnd_Time[1],  seconds, ms, splitsEnd_Date[2], splitsEnd_Date[1], splitsEnd_Date[0]);
        AddMenuItem(Challenge_Info_Menu, "", szItem, ITEMDRAW_DISABLED);

        char sztimeleft[64];
        FormatTimeFloat(data, timeleft, sztimeleft, sizeof(sztimeleft), false);
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