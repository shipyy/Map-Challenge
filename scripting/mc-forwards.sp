public Action surftimer_OnMapFinished(int client, float fRunTime, char sRunTime[54], int rank, int total, int style)
{   
    //CHALLENGES
    if(g_bIsCurrentMapChallenge && g_bIsChallengeActive && (g_iChallenge_Style == style))
        db_PlayerExistsCheck(client, fRunTime, style);
        
    //RACES
    //CHECK IF THE CLIENT IS IN A RACE
    if (g_bInRace[client]) {
        int RaceID = GetRaceIDFromClient(client);

        Race tempRace;
        Racer Player1,Player2;
        Stopwatch tempStopwatch;

        tempRace.SetDefaultValues();
        tempStopwatch.SetDefaultValues();

        BUFFER_Stopwatches.GetArray(RaceID, tempStopwatch, sizeof tempStopwatch);
        BUFFER_RacesList.GetArray(RaceID, tempRace, sizeof tempRace);

        //IF PLAYER FINISHED WITH THE RACE STYLE
        if (tempRace.GetRaceStyle() == style) {
            //STOPWATCH RACE
            if (tempRace.GetRaceType() == 0) {
                Player1 = tempRace.GetRacer(1);
                Player2 = tempRace.GetRacer(2);

                if(tempStopwatch.GetTime() > 0.0) {
                    if (client == Player1.GetClientID()) {
                        Player1.SetRuntime(fRunTime);
                    }
                    else {
                        Player2.SetRuntime(fRunTime);
                    }
                }
                else {
                    tempRace.SetRaceStatus(-1);
                    EndRace(tempRace.GetID());
                }
            }
            //1ST COMPLETION RACE
            else {
                tempRace.SetRaceStatus(-1);
                EndRace(tempRace.GetID());
            }
        }
    }
    
    return Plugin_Handled;
}