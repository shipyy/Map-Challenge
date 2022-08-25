public void FormatTimeFloat(int client, float time, char[] string, int length, bool runtime)
{
	char szDays[16];
	char szHours[16];
	char szMinutes[16];
	char szSeconds[16];
	char szMS[16];

	int time_rounded = RoundToZero(time);

	int days = time_rounded / 86400;
	int hours = (time_rounded - (days * 86400)) / 3600;
	int minutes = (time_rounded - (days * 86400) - (hours * 3600)) / 60;
	int seconds = (time_rounded - (days * 86400) - (hours * 3600) - (minutes * 60));
	int ms = RoundToZero(FloatFraction(time) * 1000);

	// 00:00:00:00:000
	// 00:00:00:000
	// 00:00:000

	//MILISECONDS
	if (ms < 10)
		Format(szMS, 16, "00%d", ms);
	else
		if (ms < 100)
			Format(szMS, 16, "0%d", ms);
		else
			Format(szMS, 16, "%d", ms);

	//SECONDS
	if (seconds < 10)
		Format(szSeconds, 16, "0%d", seconds);
	else
		Format(szSeconds, 16, "%d", seconds);

	//MINUTES
	if (minutes < 10)
		Format(szMinutes, 16, "0%d", minutes);
	else
		Format(szMinutes, 16, "%d", minutes);

	//HOURS
	if (hours < 10)
		Format(szHours, 16, "0%d", hours);
	else
		Format(szHours, 16, "%d", hours);

	//DAYS
	if (days < 10)
		Format(szDays, 16, "0%d", days);
	else
		Format(szDays, 16, "%d", days);

	if (!runtime) {
		if (days > 0) {
			Format(string, length, "%sd %sh %sm %ss %sms", szDays, szHours, szMinutes, szSeconds, szMS);
		}
		else {
			if (hours > 0) {
				Format(string, length, "%sh %sm %ss %sms", szHours, szMinutes, szSeconds, szMS);
			}
			else {
				Format(string, length, "%sm %ss %sms", szMinutes, szSeconds, szMS);
			}
		}
	}
	else {
		if (hours > 0) {
			Format(string, length, "%s:%s:%s.%s", szHours, szMinutes, szSeconds, szMS);
		}
		else {
			Format(string, length, "%s:%s.%s", szMinutes, szSeconds, szMS);
		}
	}

}

stock bool IsValidClient(int client)
{   
    if (client >= 1 && client <= MaxClients && IsClientInGame(client))
        return true;
    return false;
}

public void ResetDefaults()
{
	g_bIsChallengeActive = false;
	g_bIsCurrentMapChallenge = false;
	
	g_fChallenge_Initial_UNIX = 0.0;
	g_fChallenge_Final_UNIX = 0.0;
	g_sChallenge_InitialDate = "";
	g_sChallenge_FinalDate = "";
	g_iChallenge_Style = 0;
	g_sChallenge_MapName = "";
	//g_fChallenge_Duration = 0.0;
}

public int RoundUp(int value)
{
	return value += 10 - (value % 10);
}

public int TotalPlayers()
{
	int count = 0;

	for (int i = 0; i <= MaxClients; i++)
		if(IsValidClient(i) && !IsFakeClient(i))
			count++;

	return count;
}

public void DeleteHandles()
{
	delete BUFFER_TempRacesList;
	delete BUFFER_RacesList;
	delete BUFFER_Invitations;
	delete BUFFER_Stopwatches;
}