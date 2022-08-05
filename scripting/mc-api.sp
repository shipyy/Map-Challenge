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
 * Sends a new forward on mapchallenge_OnNewChallenge.
 * 
 * @param szChallenge_MapName           String containing the challenges map name.
 * @param g_iChallenge_Style            String containing the challenges style.
 * @param g_iChallenge_Points           integer containing the challenge rank1 points.
 * @param szInitialTimeFormatted        String containing the challenges start date.
 * @param szFinalTimeFormatted          String containing the challenges end date.
 */
void SendNewChallengeForward(int client)
{
    //START FORWARD CALL
    Call_StartForward(g_NewChallengeForward);

    //PUSH PARAMETERS
    Call_PushCell(client);
    Call_PushString(g_sChallenge_MapName);
    Call_PushCell(g_iChallenge_Style);
    Call_PushCell(g_iChallenge_Points);
    
    char szInitialTimeFormatted[32];
    FormatTime(szInitialTimeFormatted, sizeof(szInitialTimeFormatted), "%c", RoundToZero(g_fChallenge_Initial_UNIX));

    char szFinalTimeFormatted[32];
    FormatTime(szFinalTimeFormatted, sizeof(szFinalTimeFormatted), "%c", RoundToZero(g_fChallenge_Final_UNIX));


    Call_PushString(szInitialTimeFormatted);
    Call_PushString(szFinalTimeFormatted);

    //FINISH CALL
    Call_Finish();
}

/**
 * Sends a new forward on mapchallenge_OnChallengeEnd.
 * 
 * @param szChallenge_MapName           String containing the challenges map name.
 * @param g_iChallenge_Style            String containing the challenges style.
 * @param g_iChallenge_Points           integer containing the challenge rank1 points.
 * @param szInitialTimeFormatted        String containing the challenges start date.
 * @param szFinalTimeFormatted          String containing the challenges end date.
 */
void SendChallengeEndForward(int client, ArrayList szChallengeTop5, int totalparticipants)
{
    //START FORWARD CALL
    Call_StartForward(g_ChallengeEndForward);

    //PUSH PARAMETERS
    Call_PushCell(client);
    Call_PushString(g_sChallenge_MapName);
    Call_PushCell(g_iChallenge_Style);
    Call_PushCell(g_iChallenge_Points);
    
    char szInitialTimeFormatted[32];
    FormatTime(szInitialTimeFormatted, sizeof(szInitialTimeFormatted), "%c", RoundToZero(g_fChallenge_Initial_UNIX));

    char szFinalTimeFormatted[32];
    FormatTime(szFinalTimeFormatted, sizeof(szFinalTimeFormatted), "%c", RoundToZero(g_fChallenge_Final_UNIX));

    Call_PushString(szInitialTimeFormatted);
    Call_PushString(szFinalTimeFormatted);

    if(szChallengeTop5.Length != 5){
        for(int i = szChallengeTop5.Length; i <5; i++)
            szChallengeTop5.PushString("");
    }
    Call_PushCell(szChallengeTop5);

    Call_PushCell(totalparticipants);

    //FINISH CALL
    Call_Finish();
}

