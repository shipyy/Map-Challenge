/////
//CK_CHALLENGES
/////
char sql_CreateChallenges[] = "CREATE TABLE IF NOT EXISTS ck_challenges (id INT NOT NULL AUTO_INCREMENT, mapname VARCHAR(32), StartDate TIMESTAMP(6), EndDate TIMESTAMP(6), style INT(12) NOT NULL DEFAULT '0', points INT(12) NOT NULL DEFAULT '0', active INT(12) NOT NULL DEFAULT '0', PRIMARY KEY(id)) DEFAULT CHARSET=utf8mb4;";
char sql_CheckActiveChallenge[] = "SELECT id, active, mapname, points, StartDate, EndDate, UNIX_TIMESTAMP(StartDate), UNIX_TIMESTAMP(EndDate), UNIX_TIMESTAMP(EndDate) - UNIX_TIMESTAMP(UTC_TIMESTAMP(6)) as Time_Diff FROM ck_challenges ORDER BY id DESC LIMIT 1;"
char sql_InsertChallenge[] = "INSERT INTO ck_challenges (mapname, StartDate, EndDate, style, points, active) VALUES ('%s', %s, %s, '%i', '%i', '%i');"
char sql_EndChallenge[] = "UPDATE ck_challenges SET active = 0 WHERE id = '%i';"
char sql_RemainingTime[] = "SELECT UNIX_TIMESTAMP(EndDate) - UNIX_TIMESTAMP(UTC_TIMESTAMP(6)) as Time_Diff FROM ck_challenges WHERE id = '%i';"
char sql_ChallengeInfo[] = "SELECT id, mapname, StartDate, EndDate, points, style, UNIX_TIMESTAMP(EndDate) - UNIX_TIMESTAMP(UTC_TIMESTAMP(6)) as Time_Diff FROM ck_challenges WHERE active = 1;"

/////
//CK_CHALLENGE_TIMES
/////
char sql_CreateChallenges_Times[] = "CREATE TABLE IF NOT EXISTS ck_challenge_times (id INT(12) NOT NULL, steamid VARCHAR(32), name VARCHAR(32), mapname VARCHAR(32), runtime decimal(12, 6) NOT NULL DEFAULT '0.000000', style INT(12) NOT NULL DEFAULT '0', Run_Date TIMESTAMP(6)  ON UPDATE UTC_TIMESTAMP(6) NOT NULL DEFAULT UTC_TIMESTAMP(6), PRIMARY KEY(id, steamid, mapname, runtime)) DEFAULT CHARSET=utf8mb4;";
char sql_SelectParticipants[] = "SELECT steamid, style, name, mapname, runtime FROM ck_challenge_times WHERE id = '%i' ORDER BY runtime ASC;"
char sql_InsertRuntime[] = "INSERT INTO ck_challenge_times (id, steamid, name, mapname, runtime, style, Run_Date) VALUES ('%i', '%s', '%s', '%s', '%f', '%i', %s);"
char sql_UpdateRuntime[] = "UPDATE ck_challenge_times SET runtime = '%f' WHERE steamid = '%s' AND mapname = '%s' AND runtime > -1.0 AND style = %i AND Run_Date BETWEEN '%s' AND '%s';"
char sql_CheckRuntimeExists[] = "SELECT runtime FROM ck_challenge_times WHERE steamid = '%s' AND mapname = '%s' AND runtime > -1.0 AND style = %i AND Run_Date BETWEEN '%s' AND '%s';"
char sql_SelectCurrentChallengeLeaderboard[] = "SELECT name, runtime, style FROM ck_challenge_times WHERE id = '%i' ORDER BY runtime ASC LIMIT 50;"

/////
//CK_CHALLENGE_PLAYERS
/////
char sql_CreateChallenges_Players[] = "CREATE TABLE IF NOT EXISTS ck_challenge_players (steamid VARCHAR(32), name VARCHAR(32), style INT(12) NOT NULL DEFAULT '0', points INT(12) NOT NULL DEFAULT '0', PRIMARY KEY(steamid, style)) DEFAULT CHARSET=utf8mb4;";
char sql_InsertPlayer[] = "INSERT INTO ck_challenge_players (steamid, name, style, points) VALUES ('%s', '%s', '%i', '%i');"
char sql_AddPoints[] = "UPDATE ck_challenge_players SET points = points + %i WHERE steamid = '%s' AND style = %i;"
char sql_SelectPlayerProfile[] = "SELECT * FROM ck_challenge_players WHERE steamid = '%s' ORDER BY style ASC;"
char sql_SelectPlayerWithStyle[] = "SELECT * FROM ck_challenge_players WHERE steamid = '%s' AND style = '%i';"


/////
//CK_CHALLENGES_FINISHED
/////
char sql_CreateFinished_Challenges[] = "CREATE TABLE IF NOT EXISTS ck_challenges_finished (id INT(12) NOT NULL, winner VARCHAR(32), nr_participants INT(12) NOT NULL DEFAULT '0', mapname VARCHAR(32), style INT(12) NOT NULL DEFAULT '-1', points INT(12) NOT NULL DEFAULT '-1', StartDate TIMESTAMP(6), EndDate TIMESTAMP(6), PRIMARY KEY(id)) DEFAULT CHARSET=utf8mb4;";
char sql_InsertFinishedChallenge[] = "INSERT INTO ck_challenges_finished (id, StartDate, EndDate) VALUES ('%i', (SELECT StartDate FROM ck_challenges WHERE id = '%i'), (SELECT EndDate FROM ck_challenges WHERE id = '%i'));"

char sql_UpdateFinishedChallengeData[] = "UPDATE ck_challenges_finished SET winner = '%s', nr_participants = '%i', mapname = '%s', style = '%i', points = '%i' WHERE id = '%i';"