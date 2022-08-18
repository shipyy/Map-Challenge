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

//HANDLES
Handle g_hDb = null;
Handle Stopwatch_Handle = null;

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
ArrayList BUFFER_Stopwatches; //STOPWATCHES BUFFER

bool g_bInRace[MAXPLAYERS + 1];
bool g_bisResponding[MAXPLAYERS + 1];
bool g_bisWaitingResponse[MAXPLAYERS + 1];
int g_iInviteTimeout = 15;

float g_RaceCountdown = 10.0;

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

enum struct Stopwatch{
	int Race_ID;
	float time;
	float countdown;

	void SetDefaultValues() {
		this.Race_ID = 0;
		this.time = 0.0;
		this.countdown = 0.0;
	}

	//CONSTRUCTOR
	void New(int Race_ID, float time, float countdown) {
		this.Race_ID = Race_ID;
		this.time = time;
		this.countdown = countdown;
	}

	//GETTERS
	int GetRaceID() {
		return this.Race_ID;
	}

	float GetTime() {
		return this.time;
	}

	float GetCountdown() {
		return this.countdown;
	}
}

enum struct Racer{
	int Client_ID;
    char szName[MAX_NAME_LENGTH];
    float Runtime;

	void SetDefaultValues() {
        this.Client_ID = 0;
        this.szName = "";
        this.Runtime = 0.0;
    }

	//GETTERS
	int GetClientID() {
    	return this.Client_ID;
  	}

	char[] getClientName(){
		return this.szName;
	}

	float GetRuntime() {
    	return this.Runtime;
  	}

	//SETTERS
	void setClientID(int ID){
		this.Client_ID = ID;
	}

	void setClientName(char name[MAX_NAME_LENGTH]){
		this.szName = name;
	}

	void SetRuntime(float value) {
		this.Runtime = value;
	}

	void SetNextOpponentValue() {
		if(this.Client_ID < MaxClients)
			this.Client_ID++;
		else
			this.Client_ID = 0;
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

	//CONSTRUCTOR
	void New(int RaceID, Racer Player1, Racer Player2, bool Sent, bool Received, bool Accepted, bool Denied){
		this.RaceID = RaceID;
		this.Player2 = Player2;
		this.Sent = Sent;
		this.Received = Received;
		this.Accepted = Accepted;
		this.Denied = Denied;
	}

	//GETTERS
	int GetID() {
		return this.RaceID;	
	}

	bool GetSent() {
		return this.Sent;	
	}

	bool GetReceived() {
		return this.Received;
	}

	bool GetAccepted() {
		return this.Accepted;
	}
	
	bool GetDenied() {
		return this.Denied;
	}

	Racer GetRacer(int racer_nr) {
		if (racer_nr == 1)
    		return this.Player1;
		else
			return this.Player2;
  	}

	//SETTERS
	void SetSent(bool value) {
		this.Sent = value;
	}

	void SetReceived(bool value) {
		this.Received = value;
	}

	void SetAccepted(bool value) {
		this.Accepted = value;
	}

	void SetDenied(bool value) {
		this.Denied = value;
	}
}

enum struct Race{
	int ID;
    int Race_Type; //0 - BASED ON TIMER | 1 - BASED ON 1ST TO COMPLETE
    int Race_Time_Type;
    int Race_Points;
    int Race_Style;
    Racer Player1;
    Racer Player2;
    Racer Winner;
    Invite Inv;

	float Race_Time;
	int RaceStatus; // -1 ENDED/CANCELLED | 0 WAITINGRESPONSE/BEINGCREATED | 1 ONGOING/ACCEPTED

	void SetDefaultValues() {
		this.Player1.SetDefaultValues();
		this.Player2.SetDefaultValues();
		this.Winner.SetDefaultValues();
		this.Inv.SetDefaultValues();
		this.ID = 0;
		this.Race_Type = 0;
		this.Race_Time_Type = 0;
		this.Race_Points = 0;
		this.Race_Style = 0;
		this.Race_Time = 0.0;
		this.RaceStatus = 0;
	}

	//GETTERS
	int GetID() {
		return this.ID;
  	}

	int GetRaceStatus() {
		return this.RaceStatus;
	}

	float GetRaceTime() {
		return this.Race_Time;	
	}

	int GetRaceType() {
		return this.Race_Type;	
	}

	int GetRaceStyle() {
		return this.Race_Style;	
	}

	Racer GetRacer(int racer_nr) {
		if (racer_nr == 1)
    		return this.Player1;
		else
			return this.Player2;
  	}

	Racer GetOpponent() {
		return this.Player2;
  	}

	Racer GetWinner() {
		return this.Winner;
  	}

	//SETTERS
	void SetRaceType(int type){
		this.Race_Type = type;
	}

	void SetRaceTimeType(int type){
		this.Race_Time_Type = type;
	}

	void SetRaceTime(int minutes){
		this.Race_Time = minutes * 60.0;
	}

	void SetNextStyleValue(){
		if(this.Race_Style != 7)
			this.Race_Style++;
		else
			this.Race_Style = 0;
	}

	void SetNextPointsValue(){
		if(this.Race_Points != 5)
			this.Race_Points++;
		else
			this.Race_Points = 0;
	}

	void SetRacer(Racer racer, int racerID) {
		if (racerID == 1) {
			this.Player2 = racer;
		}
		else {
			this.Player2 = racer;
		}
  	}

	void SetRaceStatus(int value) {
		this.RaceStatus = value;
	}

	void SetWinner(Racer winner) {
		this.Winner = winner;
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
#include "mc-forwards.sp"

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

	Stopwatch_Handle = CreateHudSynchronizer();
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

	//CREATE BUFFERS FOR STOPWATCHES
	BUFFER_Stopwatches = new ArrayList(sizeof Stopwatch);

	//RACE TIMERS
	CreateTimer(5.0, Check_RaceInvitations, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(5.0, Cleaner_RaceInvitations, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(5.0, Cleaner_Races, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(5.0, Stopwatches, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{   
    if (!IsValidClient(client))
		return;

    GetClientAuthId(client, AuthId_Steam2, g_szSteamID[client], MAX_NAME_LENGTH, true);
}