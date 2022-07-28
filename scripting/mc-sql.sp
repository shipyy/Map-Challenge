/* ----- DATABASE SETUP ----- */
public void db_setupDatabase()
{
	/*===================================
	=    INIT CONNECTION TO DATABASE    =
	===================================*/
	char szError[255];
	g_hDb = SQL_Connect("surftimer", false, szError, 255);

	if (g_hDb == null)
	{
		SetFailState("[Map Challenge] Unable to connect to database (%s)", szError);
		return;
	}

	char szIdent[8];
	SQL_ReadDriver(g_hDb, szIdent, 8);

	if (strcmp(szIdent, "mysql", false) == 0)
	{
		SQL_LockDatabase(g_hDb);
		SQL_FastQuery(g_hDb, "SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));");
	}
	else if (strcmp(szIdent, "sqlite", false) == 0)
	{
		SetFailState("[Map Challenge] Sorry SQLite is not supported.");
		return;
	}
	else
	{
		SetFailState("[Map Challenge] Invalid database type");
		return;
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