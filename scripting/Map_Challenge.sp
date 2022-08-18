/////
//Plugin Info
/////
public Plugin myinfo =
{
	name = "Map Challenges",
	author = "https://github.com/shipyy",
	description = "Allows Creation of challenges for surf maps",
	version = "2.0.3",
	url = "https://github.com/shipyy/Map-Challenge"
};

/////
//VARIABLES
/////

// SQL driver
Handle g_hDb = null;

//CHALLENGES
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

//RACES
ArrayList BUFFER_RacesList; //ONGOING RACES BUFFER
ArrayList BUFFER_TempRacesList; //RACES BEING CREATED BUFFER
ArrayList BUFFER_Invitations; //INVITATIONS BUFFER

bool b_bInRace[MAXPLAYERS +1];
bool b_bWaitingInviteResponse[MAXPLAYERS +1]; //USE THIS VARIABLE TO CREATE THE TIMER AND WHENEVER CLIENT RECEIVES ANY INFO ABOUT INVITATION DELETE TIMER AND SET THIS TO FALSE

// Client's steamID
char g_szSteamID[MAXPLAYERS + 1][32];

char g_szChatPrefix[64];

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

enum struct Racer{
	int Client_ID;
    bool IsRacing;
    char szName[MAX_NAME_LENGTH];
    float Runtime;

	void SetDefaultValues() {
        this.Client_ID = 0;
        this.IsRacing = false;
        this.szName = "";
        this.Runtime = 0.0;
    }

	void setClientID(int ID){
		this.Client_ID = ID;
	}
}

enum struct Invite{
	int RaceID;
	Racer Player1;
    Racer Player2;
	bool Sent;
	bool Received;
	bool Accepted;
	bool Denied;

	void SetDefaultValues() {
		this.Player1.SetDefaultValues();
		this.Player2.SetDefaultValues();
		this.RaceID = 0;
		this.Sent = false;
		this.Received = false;
		this.Accepted = false;
		this.Denied = false;
	}
}

enum struct Race{
	int ID;
    int Race_Type; //0 - BASED ON TIMER | 1 - BASED ON 1ST TO COMPLETE
    int Race_Time;
    int Race_Points;
    Racer Player1;
    Racer Player2;
    Racer Winner;
    Invite Inv;

	void SetDefaultValues() {
		this.Player1.SetDefaultValues();
		this.Player2.SetDefaultValues();
		this.Winner.SetDefaultValues();
		this.Inv.SetDefaultValues();
		this.ID = 0;
		this.Race_Type = 0;
		this.Race_Time = 0;
		this.Race_Points = 0;
	}

	Racer GetRacer(int racer_nr) {
		if (racer_nr == 1)
    		return this.Player1;
		else
			return this.Player2;
  	}
}

/////
//INCLUDES
/////
#include <autoexecconfig>
#include <surftimer>
#include <colorlib>
#include <mapchallenge>
#include "mc-queries.sp"
#include "mc-sql.sp"
#include "mc-convars.sp"
#include "mc-misc.sp"
#include "mc-api.sp"
#include "mc-commands.sp"
#include "mc-timers.sp"
#include "mc-race.sp"

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

	ConVars_Create();
}

public void OnConfigsExecuted()
{
    GetConVarString(g_sChatPrefix, g_szChatPrefix, sizeof g_szChatPrefix);
}

public void OnMapStart()
{
	//CURRENT MAP NAME
	GetCurrentMap(g_szMapName, sizeof(g_szMapName));
	
	//RESET VALUES
	ResetDefaults();
	
	//CHECK CHALLENGE IS ACTIVE)
	CreateTimer(30.0, Check_Challenge_Active, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
	//TIMER THAT CHECKS REGULARLY IF THE TIME REMAINING OF CURRENT CHALLENGE HAS RUN OUT
	CreateTimer(30.0, Check_Challenge_End, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(350.0, Check_Challenge_Timeleft, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

	//CREATE BUFFERS FOR RACES
	BUFFER_RacesList = new ArrayList(sizeof Race);
	BUFFER_TempRacesList = new ArrayList(sizeof Race);

	//CREATE BUFFERS FOR INVITATIONS
	BUFFER_Invitations = new ArrayList(sizeof Invite);
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