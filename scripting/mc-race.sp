public void Race_Menu(int client, Race NewRace)
{
    Menu menu = new Menu(Race_Menu_Handler);

    char szBuffer[128];
    char szItem[128];

    //RACE ID
    Format(szBuffer, sizeof szBuffer, "%d", NewRace.ID);

	// RACE TYPE
    if(NewRace.Race_Type == 0)
	    AddMenuItem(menu, szBuffer, "Race Type | Stopwatch");
    else
        AddMenuItem(menu, szBuffer, "Race Type | Completion");

    //RACE TIME
    if(NewRace.Race_Type == 0){
        switch (NewRace.Race_Time_Type) {
            case 0: Format(szItem, sizeof szItem, "Race Time | 5 Min");
            case 1: Format(szItem, sizeof szItem, "Race Time | 10 Min");
        }
        AddMenuItem(menu, szBuffer, szItem);
    }
    else{
        AddMenuItem(menu, "", "", ITEMDRAW_IGNORE);
    }

    //RACE POINTS
    switch (NewRace.Race_Points) {
        case 0: Format(szItem, sizeof szItem, "Race Points | 50pts");
        case 1: Format(szItem, sizeof szItem, "Race Points | 100pts");
        case 2: Format(szItem, sizeof szItem, "Race Points | 500pts");
        case 3: Format(szItem, sizeof szItem, "Race Points | 1000pts");
        case 4: Format(szItem, sizeof szItem, "Race Points | 5000pts");
        case 5: Format(szItem, sizeof szItem, "Race Points | 10000pts");
    }
    AddMenuItem(menu, szBuffer, szItem);

    //RACE PLAYER
    Racer Opponent;
    Opponent = NewRace.GetRacer(2);
    if(strcmp(Opponent.szName, "", false) == 0)
        Format(szItem, sizeof szItem, "Race Opponent | None");
    else {
        //GET CLIENT NAME
        char szOpponentName[MAX_NAME_LENGTH];
        GetClientName(Opponent.Client_ID, szOpponentName, sizeof szOpponentName);
        Format(szItem, sizeof szItem, "Race Opponent | %s", Opponent.szName);
    }
    AddMenuItem(menu, szBuffer, szItem);

    //RACE PLAYER
    Format(szItem, sizeof szItem, "Race Style | %s", g_szStyleMenuPrint[NewRace.Race_Style]);
    AddMenuItem(menu, szBuffer, szItem);

    //SEND INVITATION
    AddMenuItem(menu, "", "", ITEMDRAW_IGNORE);
    AddMenuItem(menu, szBuffer, "Send Invite");

    SetMenuExitBackButton(menu, true);
    SetMenuTitle(menu, "Race Menu\n \n");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Race_Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select) {

        //GET RACE ID
        char szBuffer[64];
        GetMenuItem(menu, param2, szBuffer, sizeof szBuffer);

        switch (param2) {
            case 0: RaceType(param1, StringToInt(szBuffer));
            case 1: RaceTime(param1, StringToInt(szBuffer));
            case 2: RacePoints(param1, StringToInt(szBuffer));
            case 3: RaceOpponent(param1, StringToInt(szBuffer));
            case 4: RaceStyle(param1, StringToInt(szBuffer));
            case 5: CreateInvite(param1, StringToInt(szBuffer));
        }
    }
	else if (action == MenuAction_Cancel) {
        //GET RACE ID
        char szBuffer[64];
        GetMenuItem(menu, param2, szBuffer, sizeof szBuffer);

        BUFFER_TempRacesList.Erase(StringToInt(szBuffer));
        
        delete menu;
    }

    return 0;
}

public void RaceType(int client, int Race_ID)
{   
    Race TempRace;
    TempRace.SetDefaultValues();
    BUFFER_TempRacesList.GetArray(Race_ID, TempRace, sizeof TempRace);

    if(TempRace.Race_Type == 0)
        TempRace.SetRaceType(1);
    else
        TempRace.SetRaceType(0);

    BUFFER_TempRacesList.SetArray(Race_ID, TempRace, sizeof TempRace);

    Race_Menu(client, TempRace);
}

public void RaceTime(int client, int Race_ID)
{
    Race TempRace;
    TempRace.SetDefaultValues();
    BUFFER_TempRacesList.GetArray(Race_ID, TempRace, sizeof TempRace);

    if(TempRace.Race_Type == 0) {
        switch (TempRace.Race_Time_Type) {
            case 0: {
                TempRace.SetRaceTimeType(1);
                TempRace.SetRaceTime(10);
            }
            case 1: {
                TempRace.SetRaceTimeType(0);
                TempRace.SetRaceTime(5);
            }
        }
    }

    //SET THE CHANGED TEMPRACE IN THE TEMPRACE BUFFER
    BUFFER_TempRacesList.SetArray(Race_ID, TempRace, sizeof TempRace);

    Race_Menu(client, TempRace);
}

public void RacePoints(int client, int Race_ID)
{
    Race TempRace;
    TempRace.SetDefaultValues();
    BUFFER_TempRacesList.GetArray(Race_ID, TempRace, sizeof TempRace);

    TempRace.SetNextPointsValue();

    BUFFER_TempRacesList.SetArray(Race_ID, TempRace, sizeof TempRace);

    Race_Menu(client, TempRace);
}

public void RaceStyle(int client, int Race_ID)
{   
    Race TempRace;
    TempRace.SetDefaultValues();
    BUFFER_TempRacesList.GetArray(Race_ID, TempRace, sizeof TempRace);

    TempRace.SetNextStyleValue();

    BUFFER_TempRacesList.SetArray(Race_ID, TempRace, sizeof TempRace);

    Race_Menu(client, TempRace);
}

public void RaceOpponent(int client, int Race_ID)
{
    Race TempRace;
    TempRace.SetDefaultValues();
    BUFFER_TempRacesList.GetArray(Race_ID, TempRace, sizeof TempRace);

    Racer Opponent;
    TempRace.GetRacer(2);

    //INCREMENT ID IF IT DOESNT SURPASS MAXCLIENTS
    Opponent.SetNextOpponentValue();

    //GET NEXT VALID CLIENT ID
    while (!IsValidClient(Opponent.GetClientID())) {
        Opponent.SetNextOpponentValue();
    }

    //GET CLIENT NAME
    char szOpponentName[MAX_NAME_LENGTH];
    GetClientName(Opponent.GetClientID(), szOpponentName, sizeof szOpponentName);
    Opponent.setClientName(szOpponentName);

    BUFFER_TempRacesList.SetArray(Race_ID, TempRace, sizeof TempRace);

    Race_Menu(client, TempRace);
}

//public void SendInvitation(int client){}
//CREATE A NEW INVITATION
//ADD TO THE A ARRAYLIST OF INVITATIONS
//CREATE TIMER THAT CHECKS IF THE INVITATIONS BUFFER CONTAINS ANY INVITATION WITH THE PLAYER CLIENT ID (LISTENER , CHECK IF THE CLIENT IS THE PLAYER 2 IN ANY INVITATION)
public void CreateInvite(int client, int Race_ID)
{
    Race TempRace;
    TempRace.SetDefaultValues();
    BUFFER_TempRacesList.GetArray(Race_ID, TempRace, sizeof TempRace);

    //IF PLAYER DIDNT SELECT A OPPONENT
    if(strcmp(TempRace.GetOpponent().getClientName(), "", false) == 0) {
        CPrintToChat(client, "DIDNT SELECT OPPONENT");
        return;
    }

    //SET THE PLAYER1 OF THE RACE HAS THE PLAYER WHO IS CREATING THE RACE
    Racer TempRacer;
    TempRacer.SetDefaultValues();

    //SET CLIENTID
    TempRacer.setClientID(client);  

    //SET CLIENT NAME
    char szTempName[MAX_NAME_LENGTH];
    GetClientName(client, szTempName, sizeof szTempName);
    TempRacer.setClientName(szTempName);

    //SET THE RACER TO THE RACE BEING HANDLED
    TempRace.SetRacer(TempRacer, 1);

    //CREATE THE INVITE
    Invite NewInvite;
    NewInvite.SetDefaultValues();

    NewInvite.New(TempRace.GetID(), TempRace.GetRacer(1), TempRace.GetRacer(2), false, false, false, false);
    
    BUFFER_RacesList.PushArray(TempRace);
    BUFFER_TempRacesList.Erase(TempRace.GetID());
    BUFFER_Invitations.PushArray(NewInvite);

}

public void SendInvite(Invite invite)
{
    Racer Player1;
    Racer Player2;
    Player1 = invite.GetRacer(1);
    Player2 = invite.GetRacer(2);

    //SET THE CLIENT RECEIVING INVITE TO TRUE
    g_bisResponding[Player2.GetClientID()] = true;
    g_bisWaitingResponse[Player1.GetClientID()] = true;

    Menu menu = CreateMenu(Vote_Handler);
    char szBuffer[128];
    Format(szBuffer, sizeof szBuffer, "%d", invite.GetID());
    SetMenuTitle(menu, "Race Invite From %s", Player1.getClientName());
    AddMenuItem(menu, szBuffer, "Yes");
    AddMenuItem(menu, szBuffer, "No");
    SetMenuExitButton(menu, false);
    DisplayMenu(menu, Player2.GetClientID(), g_iInviteTimeout);
}

public int Vote_Handler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{	
        char szBuffer[128];
        GetMenuItem(menu, param2, szBuffer, sizeof szBuffer);
        switch (param2) {
            case 0: InviteCancel(StringToInt(szBuffer));
            case 1: StartRace(StringToInt(szBuffer));
        }
	}
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}

public void InviteCancel(int InviteID)
{   
    Race tempRace;
    Racer Player1, Player2;
    Invite tempInvite;

    BUFFER_RacesList.GetArray(InviteID, tempRace, sizeof tempRace);
    BUFFER_Invitations.GetArray(InviteID, tempInvite, sizeof tempInvite);

    Player1 = tempInvite.GetRacer(1);
    Player2 = tempInvite.GetRacer(2);

    CPrintToChat(Player1.GetClientID(), "%s denied the race invite", Player2.GetClientID());

    g_bisWaitingResponse[Player1.GetClientID()] = false;
    g_bisResponding[Player2.GetClientID()] = false;

    tempInvite.SetReceived(true);
    tempInvite.SetDenied(true);
    tempRace.SetRaceStatus(-1);

    BUFFER_RacesList.SetArray(tempRace.GetID(), tempRace, sizeof tempRace);
    BUFFER_Invitations.SetArray(tempRace.GetID(), tempInvite, sizeof tempInvite);
}

public void StartRace(int InviteID)
{   
    Race tempRace;
    Racer Player1,Player2;
    Invite tempInvite;

    BUFFER_RacesList.GetArray(InviteID, tempRace, sizeof tempRace);
    BUFFER_Invitations.GetArray(InviteID, tempInvite, sizeof tempInvite);

    Stopwatch tempStopwatch;
    tempStopwatch.New(InviteID, tempRace.GetRaceTime(), g_RaceCountdown);

    Player1 = tempRace.GetRacer(1);
    Player2 = tempRace.GetRacer(2);

    g_bInRace[Player1.GetClientID()] = true;
    g_bInRace[Player2.GetClientID()] = true;

    tempInvite.SetReceived(true);
    tempInvite.SetAccepted(true);

    if (tempRace.GetRaceType() == 0) {
        BUFFER_Stopwatches.PushArray(tempStopwatch, sizeof tempStopwatch);
        tempRace.SetRaceStatus(1);
        BUFFER_RacesList.SetArray(tempRace.GetID(), tempRace, sizeof tempRace);
    }

    //surftimer_SafeTeleport(,);
}

public int GetRaceIDFromClient(int client)
{
    return BUFFER_Stopwatches.FindValue(client, Stopwatch::Race_ID);
}

public void EndRace(int RaceID)
{
    Race tempRace;
    Racer Player1,Player2;
    Stopwatch tempStopwatch;

    tempRace.SetDefaultValues();
    tempStopwatch.SetDefaultValues();

    BUFFER_Stopwatches.GetArray(RaceID, tempStopwatch, sizeof tempStopwatch);
    BUFFER_RacesList.GetArray(RaceID, tempRace, sizeof tempRace);

    Player1 = tempRace.GetRacer(1);
    Player2 = tempRace.GetRacer(2);

    if (tempRace.GetRaceType() == 0) {
        //PLAYER 1 WON
        if (Player1.GetRuntime() > Player2.GetRuntime()) {
            tempRace.SetWinner(Player1);
        }
        //PLAYER 2 WON
        else if (Player1.GetRuntime() < Player2.GetRuntime()) {
            tempRace.SetWinner(Player2);
        }
        //DRAW
        else {
            Racer draw;
            draw.setClientName("draw");
            tempRace.SetWinner(draw);
        }

        DisplayEndRaceHUD(tempRace.GetID());
    }
    else {
        if (Player1.GetRuntime() > 0.0) {
            tempRace.SetWinner(Player1);

            SetHudTextParams(-1.0, -1.0, 5.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
            ShowSyncHudText(Player1.GetClientID(), Stopwatch_Handle, "----- YOU WON -----");
            ShowSyncHudText(Player2.GetClientID(), Stopwatch_Handle, "%s Finished!\n----- YOU LOST ----", Player1.getClientName());
        }
        else if (Player2.GetRuntime() > 0.0){
            tempRace.SetWinner(Player2);

            SetHudTextParams(-1.0, -1.0, 5.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
            ShowSyncHudText(Player2.GetClientID(), Stopwatch_Handle, "----- YOU WON -----");
            ShowSyncHudText(Player1.GetClientID(), Stopwatch_Handle, "%s Finished!\n----- YOU LOST ----", Player2.getClientName());
        }
        DisplayEndRaceHUD(tempRace.GetID());
    }
}

public void DisplayEndRaceHUD(int RaceID)
{   
    Race tempRace;
    Racer Player1, Player2, Winner;
    Stopwatch tempStopwatch;

    tempRace.SetDefaultValues();
    tempStopwatch.SetDefaultValues();

    BUFFER_Stopwatches.GetArray(RaceID, tempStopwatch, sizeof tempStopwatch);
    BUFFER_RacesList.GetArray(RaceID, tempRace, sizeof tempRace);

    Winner = tempRace.GetWinner();
    Player1 = tempRace.GetRacer(1);
    Player2 = tempRace.GetRacer(2);

    int WinnerID = Winner.GetClientID() == Player1.GetClientID() ? true : false;

    if (WinnerID == Player1.GetClientID()) {
        SetHudTextParams(-1.0, -1.0, 5.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
        ShowSyncHudText(Player1.GetClientID(), Stopwatch_Handle, "----- YOU WON -----");
        ShowSyncHudText(Player2.GetClientID(), Stopwatch_Handle, "----- YOU LOST ----");
    }
    else if (WinnerID == Player2.GetClientID()) {
        SetHudTextParams(-1.0, -1.0, 5.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
        ShowSyncHudText(Player2.GetClientID(), Stopwatch_Handle, "----- YOU WON -----");
        ShowSyncHudText(Player1.GetClientID(), Stopwatch_Handle, "----- YOU LOST ----");
    }

    g_bisResponding[Player2.GetClientID()] = false;
    g_bisWaitingResponse[Player1.GetClientID()] = false;
    g_bInRace[Player1.GetClientID()] = false;
    g_bInRace[Player2.GetClientID()] = false;

    tempRace.SetRaceStatus(-1);
    RemoveFromBuffers(RaceID);
}

public void RemoveFromBuffers(int RaceID)
{
    BUFFER_Stopwatches.Erase(RaceID);
    BUFFER_Invitations.Erase(RaceID);
}