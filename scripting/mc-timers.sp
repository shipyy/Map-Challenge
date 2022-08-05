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