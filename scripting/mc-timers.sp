//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////`````CHALLENGES`````////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
//REPEATING TIMER THAT CHECKS CHALLENGE TIMELEFT
/////
public Action Check_Challenge_Timeleft(Handle timer)
{
    if(g_bIsChallengeActive){
        db_GetRemainingTime_Timer();
    }

    return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////`````RACE`````///////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////
//REPEATING TIMER THAT CHECKS FOR INVITATIONS
/////
public Action Check_RaceInvitations(Handle timer)
{
    Invite TempInvite;
    int Player2_ID;
    for (int i = 0; i < BUFFER_Invitations.Length; i++) {
        TempInvite.SetDefaultValues();
        BUFFER_Invitations.GetArray(i, TempInvite, sizeof TempInvite);

        Player2_ID = TempInvite.Player2.GetClientID();

        if (!g_bInRace[Player2_ID] && !g_bisResponding[Player2_ID] && !TempInvite.GetReceived()) {
            TempInvite.SetSent(true);
            BUFFER_Invitations.SetArray(TempInvite.GetID(), TempInvite, sizeof TempInvite);
            SendInvite(TempInvite);
        }
    }

    return Plugin_Continue;
}

/////
//REPEATING TIMER THAT CLEANS INVITATIONS BUFFER
/////
public Action Cleaner_RaceInvitations(Handle timer)
{   
    Race tempRace;
    Racer Player1,Player2;
    Invite TempInvite;

    for (int i = 0; i < BUFFER_Invitations.Length; i++) {
        TempInvite.SetDefaultValues();
        BUFFER_Invitations.GetArray(i, TempInvite, sizeof TempInvite);
        BUFFER_RacesList.GetArray(TempInvite.GetID(), tempRace, sizeof tempRace);

        Player1 = tempRace.GetRacer(1);
        Player2 = tempRace.GetRacer(2);

        if (TempInvite.GetReceived() && TempInvite.GetSent() && (TempInvite.GetAccepted() || TempInvite.GetDenied())) {
            
            g_bisResponding[Player2.GetClientID()] = false;
            g_bisWaitingResponse[Player1.GetClientID()] = false;

            tempRace.SetRaceStatus(-1);
            BUFFER_RacesList.SetArray(TempInvite.GetID(), tempRace, sizeof tempRace);
            BUFFER_Invitations.Erase(TempInvite.GetID());
            
        }
    }

    return Plugin_Continue;
}

/////
//REPEATING TIMER THAT CLEANS RACELIST BUFFER
/////
public Action Cleaner_Races(Handle timer)
{
    Race TempRace;
    for (int i = 0; i < BUFFER_RacesList.Length; i++) {
        TempRace.SetDefaultValues();
        BUFFER_RacesList.GetArray(i, TempRace, sizeof TempRace);

        if(TempRace.GetRaceStatus() == -1)
            BUFFER_RacesList.Erase(TempRace.GetID());
    }

    return Plugin_Continue;
}

/////
//REPEATING TIMER THAT CHECKS FOR NEW RACES STARTING AND HANDLES THE ACTUALL RACES THEMSELVES
/////
public Action Stopwatches(Handle timer)
{   
    Race tempRace;
    Racer Player1, Player2;
    Stopwatch tempStopwatch;
    for (int i = 0; i < BUFFER_Stopwatches.Length; i++) {
        tempRace.SetDefaultValues();
        tempStopwatch.SetDefaultValues();
        BUFFER_RacesList.GetArray(i, tempRace, sizeof tempRace);
        BUFFER_Stopwatches.GetArray(i, tempStopwatch, sizeof tempStopwatch);

        Player1 = tempRace.GetRacer(1);
        Player2 = tempRace.GetRacer(2);

        if(tempRace.GetRaceStatus() == 1) {

            //GET STOPWATCH TIME
            float time = tempStopwatch.GetTime();

            //FORMAT STOPWATCH TIME TO DISPLAY
            char szFormattedStopwatch[32];
            FormatTimeFloat(0, time, szFormattedStopwatch, sizeof szFormattedStopwatch, true);

            //COUNTDOWN
            if(tempStopwatch.GetCountdown() > 0.0) {

                SetHudTextParams(-1.0, -1.0, 0.1, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
                ShowSyncHudText(Player1.GetClientID(), Stopwatch_Handle, "Race Will Start In\n-----%d-----", RoundToZero(tempStopwatch.GetCountdown()));
                ShowSyncHudText(Player2.GetClientID(), Stopwatch_Handle, "Race Will Start In\n-----%d-----", RoundToZero(tempStopwatch.GetCountdown()));

                tempStopwatch.CountdownDecrease();

                BUFFER_Stopwatches.SetArray(tempStopwatch.GetRaceID(), tempStopwatch, sizeof tempStopwatch);
            }
            //IN RACE
            else {

                //TP PLAYERS TO START
                if (tempStopwatch.GetTime() == tempRace.GetRaceTime()) {
                    surftimer_TeleportClient(Player1.GetClientID());
                    surftimer_TeleportClient(Player2.GetClientID());
                }

                if (tempStopwatch.GetTime() > 0.0) {
                    SetHudTextParams(-1.0, 0.2, 0.1, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);

                    //SHOWHUD TO PLAYERS
                    ShowSyncHudText(Player1.GetClientID(), Stopwatch_Handle, szFormattedStopwatch);
                    ShowSyncHudText(Player2.GetClientID(), Stopwatch_Handle, szFormattedStopwatch);

                    tempStopwatch.TimeDecrease();
                }
                else if (tempRace.GetRaceStatus() == -1 || tempStopwatch.GetTime() <= 0.0){
                    EndRace(tempStopwatch.GetRaceID());
                }
            }
        }
            
    }

    return Plugin_Continue;
}