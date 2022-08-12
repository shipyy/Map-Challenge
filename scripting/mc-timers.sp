/////
//REPEATING TIMER THAT CHECKS IF A CHALLENGE IS ACTIVE
/////
public Action Check_Challenge_Active(Handle timer)
{
    if(!g_bIsChallengeActive){
        db_CheckChallengeActive();
    }

    return Plugin_Handled;
}

/////
//REPEATING TIMER THAT CHECKS IF A CHALLENGE HAS ENDED
/////
public Action Check_Challenge_End(Handle timer)
{
    if(g_bIsChallengeActive){
        db_CheckChallengeEnd();
    }

    return Plugin_Handled;
}

/////
//REPEATING TIMER THAT CHECKS  CHALLENGE TIMELEFT
/////
public Action Check_Challenge_Timeleft(Handle timer)
{
    if(g_bIsChallengeActive){
        db_GetRemainingTime_Timer();
    }

    return Plugin_Handled;
}