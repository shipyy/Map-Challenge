/////
//Plugin Info
/////
public Plugin myinfo =
{
	name = "Map Challenges",
	author = "https://github.com/shipyy",
	description = "Allows Creation of challenges for surf maps",
	version = "1.0.0",
	url = "https://github.com/shipyy/Map-Challenge"
};

/////
//VARIABLES
/////

// SQL driver
Handle g_hDb = null;

//CHALLENGE
int g_iChallenge_ID = 0;
bool g_bIsChallengeActive = false;
bool g_bIsCurrentMapChallenge = false;

float g_fChallenge_Initial_UNIX;
float g_fChallenge_Final_UNIX;
char g_sChallenge_InitialDate[64];
char g_sChallenge_FinalDate[64];
//float g_fChallenge_Duration;
int g_iChallenge_Points;
int g_iChallenge_Style;
char g_sChallenge_MapName[32];

int MAX_STYLES = 8;

//CURRENT MAPNAME
char g_szMapName[128];

char g_szStyleMenuPrint[][] =
{
	"Normal",
	"Sideways",
	"Half-Sideways",
	"Backwards",
	"Low-Gravity",
	"Slow Motion",
	"Fast Forward",
	"Freestyle"
};

char g_szStyleAcronyms[][] =
{
	"n",
	"sw",
	"hsw",
	"bw",
	"lg",
	"sm",
	"ff",
	"fs"
};

// Client's steamID
char g_szSteamID[MAXPLAYERS + 1][32];

char g_szChatPrefix[64] = "MAP CHALLENGE";

/////
//FORWARDS
/////
GlobalForward g_NewChallengeForward;
GlobalForward g_ChallengeEndForward;

/////
//ENUMS
/////
enum struct TOP5_entry{
	char szPlayerName[MAX_NAME_LENGTH];
	char szRuntimeFormatted[32];
	char szRuntimeDifference[32];
}
/////
//INCLUDES
/////
#include <surftimer>
#include <colorlib>
#include <mapchallenge>
#include "mc-queries.sp"
#include "mc-sql.sp"
#include "mc-misc.sp"
#include "mc-api.sp"
#include "mc-commands.sp"
#include "mc-timers.sp"

public void OnPluginStart()
{
    EngineVersion eGame = GetEngineVersion();
    if(eGame != Engine_CSGO)
		SetFailState("[MapChallenge] This plugin is for CSGO only.");
    
    // reload language files
    LoadTranslations("mapchallenge.phrases");

    Register_Forwards();

    db_setupDatabase();

    CreateCMDS();

}

public void OnMapStart(){
	
	//CURRENT MAP NAME
	GetCurrentMap(g_szMapName, sizeof(g_szMapName));
	
	//RESET VALUES
	ResetDefaults();
	
	//CHECK CHALLENGE IS ACTIVE)
	CreateTimer(30.0, Check_Challenge_Active, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
	//TIMER THAT CHECKS REGULARLY IF THE TIME REMAINING OF CURRENT CHALLENGE HAS RUN OUT
	CreateTimer(30.0, Check_Challenge_End, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(350.0, Check_Challenge_Timeleft, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{   
    if (!IsValidClient(client))
		return;

    GetClientAuthId(client, AuthId_Steam2, g_szSteamID[client], MAX_NAME_LENGTH, true);
}

public Action surftimer_OnMapFinished(int client, float fRunTime, char sRunTime[54], int rank, int total, int style)
{
	if(g_bIsCurrentMapChallenge && g_bIsChallengeActive && (g_iChallenge_Style == style))
		db_PlayerExistsCheck(client, fRunTime, style);

	return Plugin_Handled;
}