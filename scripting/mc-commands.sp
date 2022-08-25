public void CreateCMDS()
{
    //COMMANDS
    RegConsoleCmd("sm_challenge", Challenge_Info, "[Map Challenge] Displays additional information of the ongoing challenge");
    RegConsoleCmd("sm_mcp", ChallengeProfile, "[Map Challenge] Displays the players profile");
    RegConsoleCmd("sm_mctop", TopLeaderBoard, "[Map Challenge] Displays the overall challenge top players (TOP 50) (TOP 50)");
    RegConsoleCmd("sm_mcct", LeaderBoard, "[Map Challenge] Displays the ongoing challenge leaderboard (TOP 50)");
    RegConsoleCmd("sm_mct", Challenge_Timeleft, "[Map Challenge] Displays remaining time left of the current challenge");
    RegAdminCmd("sm_add_challenge", Create_Challenge, ADMFLAG_ROOT, "[Map Challenge] Add new challenge");
    RegAdminCmd("sm_end_challenge", Manual_ChallengeEnd, ADMFLAG_ROOT, "[Map Challenge] Ends the ongoing challenge");
    RegConsoleCmd("sm_time_prefix", Misc_Time_Prefix, "[Map Challenge] Displays available time prefixes");

}

/////
//CREATE CHALLENGE
/////
public Action Create_Challenge(int client, int args)
{

    if(!IsValidClient(client))
        return Plugin_Handled;

    if(args != 4){
        CPrintToChat(client, "%t", "Add_Challenge_ERROR_Format", g_szChatPrefix);
        CPrintToChat(client, "Type {red}/time_acronyms{default} to all possible formats");
    }
    else{
        //GET ARGUMENTS VALUES
        char szMapName[32];
        GetCmdArg(1, szMapName, sizeof(szMapName));

        char szstyle[32];
        GetCmdArg(2, szstyle, sizeof(szstyle));
        int style = StringToInt(szstyle);

        if (szstyle[0] == '#') {
            ReplaceString(szstyle, sizeof szstyle, "#", "", false);

            ArrayList styles = new ArrayList(32);

            for (int j = 0; j < MAX_STYLES; j++) {
                styles.PushString(g_szStyleAcronyms[j]);
            }

            style = styles.FindString(szstyle);

            if ( style == -1 ) {
                CPrintToChat(client, "%t", "style_not_found", g_szChatPrefix);
                return Plugin_Handled;
            }

            delete styles;
        }
        else {
            CPrintToChat(client, "%t", "Add_Challenge_ERROR_Format", g_szChatPrefix);
            CPrintToChat(client, "Type {red}/time_acronyms{default} to all possible formats");
            return Plugin_Handled;
        }

        char szpoints[32];
        GetCmdArg(3, szpoints, sizeof(szpoints));
        int points = StringToInt(szpoints);

        char szduration[32];
        GetCmdArg(4, szduration, sizeof(szduration));
        float duration;
        int type;
        if (szduration[0] == 'd' || szduration[0] == 'D') {
            if (szduration[0] == 'd')
                ReplaceString(szduration, sizeof szduration, "d", "", false);
            else
                ReplaceString(szduration, sizeof szduration, "D", "", false);
            type = 0;
        }
        else if(szduration[0] == 'h' || szduration[0] == 'H'){
            if (szduration[0] == 'h')
                ReplaceString(szduration, sizeof szduration, "h", "", false);
            else
                ReplaceString(szduration, sizeof szduration, "H", "", false);
            type = 1;
        }
        else if(szduration[0] == 'm' || szduration[0] == 'M'){
            if (szduration[0] == 'm')
                ReplaceString(szduration, sizeof szduration, "m", "", false);
            else
                ReplaceString(szduration, sizeof szduration, "M", "", false);
            type = 2;
        }
        else {
            CPrintToChat(client, "%t", "Add_Challenge_ERROR_Format", g_szChatPrefix);
            CPrintToChat(client, "Type {red}/time_acronyms{default} to all possible formats");
            return Plugin_Handled;
        }

        duration = StringToFloat(szduration);

        if(!g_bIsChallengeActive)
            db_selectMapNameEquals(client, szMapName, style, points, duration, type);
        else
            CPrintToChat(client, "%t", "Challenge_Active", g_szChatPrefix);
    }

    return Plugin_Handled;
}

/////
//END CHALLENGE VIA CMD
/////
public Action Manual_ChallengeEnd(int client, int args)
{
    if (!IsValidClient(client))
		return Plugin_Handled;

    if(g_bIsChallengeActive)
        db_EndCurrentChallenge(client, g_iChallenge_ID);
    else
        CPrintToChat(client, "%t", "Challenge_Inactive", g_szChatPrefix);
    
    return Plugin_Handled;
}

/////
//SHOW PLAYERS PROFILE
//CODE BASE RETRIVED FROM https://github.com/surftimer/SurfTimer
/////
public Action ChallengeProfile(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    if(args > 0) {
        char szPlayerName[MAX_NAME_LENGTH];
        GetCmdArg(1, szPlayerName, sizeof szPlayerName);
        db_GetPlayerSteamdID(client, szPlayerName);
    }
    else
    {
        ProfileMenu(client, "");
    }

    return Plugin_Handled;

}

public void ProfileMenu(int client, char szSteamID[32])
{
	if(StrEqual(szSteamID, ""))
	{
        char szBuffer[256];
        char szPlayerName[MAX_NAME_LENGTH];
        Menu menu = CreateMenu(ProfilePlayerSelectMenuHandler);
        SetMenuTitle(menu, "Challenge Profile Menu - Choose a player\n------------------------------\n");

        for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i))
			{
                GetClientName(i, szPlayerName, sizeof(szPlayerName));
                Format(szBuffer, sizeof szBuffer, "%d", i);
                AddMenuItem(menu, szBuffer, szPlayerName);
			}
        }
        
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else
	{
        db_viewPlayerProfile(client, szSteamID);
	}
}

public int ProfilePlayerSelectMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{	
        char szBuffer[8];
        
        GetMenuItem(menu, param2, szBuffer, sizeof szBuffer);

        db_viewPlayerProfile(StringToInt(szBuffer), g_szSteamID[(StringToInt(szBuffer))]);

	}
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}

/////
//SHOW OVERALL CHALLENGES LEADERBOARD (TOP 50)
//CODE BASE RETRIVED FROM https://github.com/surftimer/SurfTimer
/////
public Action TopLeaderBoard(int client, int args)
{   
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    Menu menu = CreateMenu(TOPStyleSelectHandler);
    SetMenuTitle(menu, "Profile Menu - Select a style");
    AddMenuItem(menu, "0", "Normal");
    AddMenuItem(menu, "1", "Sideways");
    AddMenuItem(menu, "2", "Half-Sideways");
    AddMenuItem(menu, "3", "Backwards");
    AddMenuItem(menu, "4", "Low-Gravity");
    AddMenuItem(menu, "5", "Slow Motion");
    AddMenuItem(menu, "6", "Fast Forwards");
    AddMenuItem(menu, "7", "Freestyle");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public int TOPStyleSelectHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
        char szStyle[32];
        GetMenuItem(menu, param2, szStyle, sizeof(szStyle));
        
        db_DisplayOverallTOP(param1, StringToInt(szStyle));
	}
	else if (action == MenuAction_End)
		delete menu;

	return 0;
}

/////
//SHOW CHALLENGE LEADERBOARD
/////
public Action LeaderBoard(int client, int args)
{   
    if(!IsValidClient(client))
        return Plugin_Handled;

    if(g_bIsChallengeActive)
        db_SelectCurrentChallengeTop(client);
    else
        CPrintToChat(client, "%t", "Challenge_Inactive", g_szChatPrefix);

    return Plugin_Handled;
}

/////
//DISPLAY CURRENT CHALLENGE TIMELEFT
/////
public Action Challenge_Timeleft(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;

    if(g_bIsChallengeActive)
        db_GetRemainingTime(client);
    else
        CPrintToChat(client, "%t", "Challenge_Inactive", g_szChatPrefix);

    return Plugin_Handled;
}

/////
//DISPLAY CURRENT CHALLENGE INFO
/////
public Action Challenge_Info(int client, int args)
{   
    if(!IsValidClient(client))
        return Plugin_Handled;

    db_ChallengeInfo(client);

    return Plugin_Handled;
}

/////
//DISPLAY TIME PREFIXES
/////
public Action Misc_Time_Prefix(int client, int args)
{   
    if(!IsValidClient(client))
        return Plugin_Handled;

    CPrintToChat(client, "%t", "Time_Prefix", g_szChatPrefix);

    return Plugin_Handled;
}