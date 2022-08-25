ConVar g_sChatPrefix;
ConVar g_sChallengeFlag;

void ConVars_Create()
{
    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("mapchallenge");
    
    g_sChatPrefix = AutoExecConfig_CreateConVar("mc_chat_prefix", "{blue}Map Challenge {default}|", "Chat messages prefix");
    HookConVarChange(g_sChatPrefix, Convars_Changed);
    
    g_sChallengeFlag = AutoExecConfig_CreateConVar("ck_challenge_flag", "z", "Flag required to Create/End Challenge");
    HookConVarChange(g_sChallengeFlag, Convars_Changed);


    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}

public void Convars_Get()
{
    //CHAR PREFIX
    GetConVarString(g_sChatPrefix, g_szChatPrefix, sizeof g_szChatPrefix);

    //CHALLENGE CREATE/END FLAG
    char szFlag[24];
    AdminFlag Aflag;
    GetConVarString(g_sChallengeFlag, szFlag, sizeof szFlag);
    bool validFlag = FindFlagByChar(szFlag[0], Aflag);
    if (!validFlag)
		g_iChallengeFlag = ADMFLAG_ROOT;
	else
		g_iChallengeFlag = FlagToBit(Aflag);
}

public void Convars_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
    //CHAR PREFIX
    if (convar == g_sChatPrefix) {
            GetConVarString(g_sChatPrefix, g_szChatPrefix, sizeof g_szChatPrefix);
    }
    //CHALLENGE CREATE/END FLAG
    else if (g_sChallengeFlag) {
        AdminFlag Aflag;
        bool validFlag = FindFlagByChar(newValue[0], Aflag);
        if (!validFlag)
            g_iChallengeFlag = ADMFLAG_ROOT;
        else
            g_iChallengeFlag = FlagToBit(Aflag);
    }
}