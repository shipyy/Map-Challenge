public void Race_Menu(int client, Race NewRace)
{
    CPrintToChatAll("lenth %d", BUFFER_TempRacesList.Length);

    Menu menu = new Menu(Race_Menu_Handler);

    char szBuffer[128];
    char szItem[128];

    //RACE ID
    Format(szBuffer, sizeof szBuffer, "%d", NewRace.ID);

	// RACE TYPE
    if(BUFFER_TempRacesList.Get(NewRace.ID, Race::Race_Type) == 0)
	    AddMenuItem(menu, szBuffer, "Race Type | Stopwatch");
    else
        AddMenuItem(menu, szBuffer, "Race Type | Completion");

    //RACE TIME
    Format(szItem, sizeof szItem, "Race Time | %d", BUFFER_TempRacesList.Get(NewRace.ID, Race::Race_Time));
    if(BUFFER_TempRacesList.Get(NewRace.ID, Race::Race_Type) == 0){
        switch (BUFFER_TempRacesList.Get(NewRace.ID, Race::Race_Time)) {
            case 0: Format(szItem, sizeof szItem, "Race Time | 5 Min");
            case 1: Format(szItem, sizeof szItem, "Race Time | 10 Min");
        }
        AddMenuItem(menu, szBuffer, szItem);
    }

    //RACE POINTS
    Format(szItem, sizeof szItem, "Race Points | %d", BUFFER_TempRacesList.Get(NewRace.ID, Race::Race_Points));
    switch (BUFFER_TempRacesList.Get(NewRace.ID, Race::Race_Points)) {
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

    int type = BUFFER_TempRacesList.Get(Race_ID, Race::Race_Type);

    if(type == 0)
        BUFFER_TempRacesList.Set(Race_ID, 1, Race::Race_Type);
    else
        BUFFER_TempRacesList.Set(Race_ID, 0, Race::Race_Type);

    Race TempRace;
    TempRace.SetDefaultValues();
    BUFFER_TempRacesList.GetArray(Race_ID, TempRace, sizeof TempRace);

    Race_Menu(client, TempRace);
}

public void RaceTime(int client, int Race_ID)
{

    int Time_Type = BUFFER_TempRacesList.Get(Race_ID, Race::Race_Time);

    if(Time_Type == 0)
        BUFFER_TempRacesList.Set(Race_ID, 1, Race::Race_Time);
    else if(Time_Type == 1)
        BUFFER_TempRacesList.Set(Race_ID, 0, Race::Race_Time);

    Race TempRace;
    TempRace.SetDefaultValues();
    BUFFER_TempRacesList.GetArray(Race_ID, TempRace, sizeof TempRace);

    Race_Menu(client, TempRace);
}

public void RacePoints(int client, int Race_ID)
{

    int Points_Type = BUFFER_TempRacesList.Get(Race_ID, Race::Race_Points);

    if(Points_Type != 5)
        BUFFER_TempRacesList.Set(Race_ID, Points_Type + 1, Race::Race_Points);
    else
        BUFFER_TempRacesList.Set(Race_ID, 0, Race::Race_Points);

    Race TempRace;
    TempRace.SetDefaultValues();
    BUFFER_TempRacesList.GetArray(Race_ID, TempRace, sizeof TempRace);

    Race_Menu(client, TempRace);
}

public void RaceOpponent(int client, int Race_ID)
{
    Race temp_race;
    BUFFER_TempRacesList.GetArray(Race_ID, temp_race, sizeof Race);

    Racer Opponent;
    temp_race.GetRacer(2);

    //INCREMENT ID IF IT DOESNT SURPASS MAXCLIENTS
    if(Opponent.Client_ID < MaxClients)
        Opponent.setClientID(Opponent.Client_ID + 1);
    else
        Opponent.setClientID(0);

    //GET NEXT VALID CLIENT ID
    while (!IsValidClient(Opponent.Client_ID)) {
        Opponent.setClientID(Opponent.Client_ID + 1);
    }

    //GET CLIENT NAME
    char szOpponentName[MAX_NAME_LENGTH];
    GetClientName(0, szOpponentName, sizeof szOpponentName);
    Opponent.szName = szOpponentName;

    Race TempRace;
    TempRace.SetDefaultValues();
    BUFFER_TempRacesList.GetArray(Race_ID, TempRace, sizeof TempRace);

    Race_Menu(client, TempRace);
}

//public void SendInvitation(int client){}
//CREATE A NEW INVITATION
//ADD TO THE A ARRAYLIST OF INVITATIONS
//CREATE TIMER THAT CHECKS IF THE INVITATIONS BUFFER CONTAINS ANY INVITATION WITH THE PLAYER CLIENT ID (LISTENER , CHECK IF THE CLIENT IS THE PLAYER 2 IN ANY INVITATION)

//public void AcceptInvitation(int client){}
//ADD TO CURRENT RACES BUFFER
//REMOVE FROM INVITATION BUFFER
//REMOVE FROM TEMP RACES BUFFER
//START RACE

//public void DenyInvitation(int client){}
//CREATE TIMER THAT CHECKS IF THE INVITATIONS BUFFER CONTAINS ANY INVITATION WITH THE PLAYER CLIENT ID (LISTENER , CHECK IF THE CLIENT IS THE PLAYER 1 IN ANY INVITATION)
//SEND NOTIFICATION TO THE PLAYER WHO REQUESTED THE RACE THAT RACE WAS REFUSED
//REMOVE FROM INVITATION BUFFER
//REMOVE FROM TEMP RACES BUFFER
//START RACE
