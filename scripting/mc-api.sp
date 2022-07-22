public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("map_challenge");
	return APLRes_Success;
}

void Register_Forwards()
{
	g_NewChallengeForward = new GlobalForward("surftimer_OnNewChallenge", ET_Event, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_String, Param_String);
}

/**
 * Sends a new record forward on surftimer_OnNewChallenge.
 * 
 * @param szRecordDiff     String containing the challenges map name.
 */
void SendNewChallengeForward(int client, const char[] szChallenge_MapName)
{
    /* Start New record function call */
    Call_StartForward(g_NewChallengeForward);

    /* Push parameters one at a time */
    Call_PushCell(client);
    Call_PushString(szChallenge_MapName);
    Call_PushCell(g_iChallenge_Style);
    Call_PushCell(g_iChallenge_Points);
    
    char szInitialTimeFormatted[32];
    FormatTime(szInitialTimeFormatted, sizeof(szInitialTimeFormatted), "%c", g_iChallenge_Final_TimeStamp);

    char szFinalTimeFormatted[32];
    FormatTime(szFinalTimeFormatted, sizeof(szFinalTimeFormatted), "%c", g_iChallenge_Initial_TimeStamp);

    Call_PushString(szInitialTimeFormatted);
    Call_PushString(szFinalTimeFormatted);

    /* Finish the call, get the result */
    Call_Finish();
}