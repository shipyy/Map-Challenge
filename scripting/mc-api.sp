public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("map_challenge");
	return APLRes_Success;
}

void Register_Forwards()
{
	g_NewChallengeForward = new GlobalForward("mapchallenge_OnNewChallenge", ET_Event, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_String, Param_String);
	g_ChallengeEndForward = new GlobalForward("mapchallenge_OnChallengeEnd", ET_Event, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_String, Param_String, Param_Cell, Param_Cell);
}

/**
 * Sends a new record forward on surftimer_OnNewChallenge.
 * 
 * @param szChallenge_MapName     String containing the challenges map name.
 * @param g_iChallenge_Style      String containing the challenges style.
 * @param g_iChallenge_Points      integer containing the challenge rank1 points.
 * @param szInitialTimeFormatted      String containing the challenges start date.
 * @param szFinalTimeFormatted      String containing the challenges end date.
 */
void SendNewChallengeForward(int client)
{
    /* Start New record function call */
    Call_StartForward(g_NewChallengeForward);

    /* Push parameters one at a time */
    Call_PushCell(client);
    Call_PushString(g_sChallenge_MapName);
    Call_PushCell(g_iChallenge_Style);
    Call_PushCell(g_iChallenge_Points);
    
    char szInitialTimeFormatted[32];
    FormatTime(szInitialTimeFormatted, sizeof(szInitialTimeFormatted), "%c", g_iChallenge_Initial_TimeStamp);

    char szFinalTimeFormatted[32];
    FormatTime(szFinalTimeFormatted, sizeof(szFinalTimeFormatted), "%c", g_iChallenge_Final_TimeStamp);

    Call_PushString(szInitialTimeFormatted);
    Call_PushString(szFinalTimeFormatted);

    /* Finish the call, get the result */
    Call_Finish();
}

/**
 * Sends a new record forward on surftimer_OnNewChallenge.
 * 
 * @param szChallenge_MapName     String containing the challenges map name.
 * @param g_iChallenge_Style      String containing the challenges style.
 * @param g_iChallenge_Points      integer containing the challenge rank1 points.
 * @param szInitialTimeFormatted      String containing the challenges start date.
 * @param szFinalTimeFormatted      String containing the challenges end date.
 */
void SendChallengeEndForward(int client, ArrayList szChallengeTop5, int totalparticipants)
{
    /* Start New record function call */
    Call_StartForward(g_ChallengeEndForward);

    /* Push parameters one at a time */
    Call_PushCell(client);
    Call_PushString(g_sChallenge_MapName);
    Call_PushCell(g_iChallenge_Style);
    Call_PushCell(g_iChallenge_Points);
    
    char szInitialTimeFormatted[32];
    FormatTime(szInitialTimeFormatted, sizeof(szInitialTimeFormatted), "%c", g_iChallenge_Initial_TimeStamp);

    char szFinalTimeFormatted[32];
    FormatTime(szFinalTimeFormatted, sizeof(szFinalTimeFormatted), "%c", g_iChallenge_Final_TimeStamp);

    Call_PushString(szInitialTimeFormatted);
    Call_PushString(szFinalTimeFormatted);

    if(szChallengeTop5.Length != 5){
        for(int i = szChallengeTop5.Length; i <5; i++)
            szChallengeTop5.PushString("");
    }
    Call_PushCell(szChallengeTop5);

    Call_PushCell(totalparticipants);

    /* Finish the call, get the result */
    Call_Finish();
}

