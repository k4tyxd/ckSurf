#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>
#include <cstrike>
#include <entity>
#include <setname>
#include <smlib>
#include <geoip>
#include <basecomm>
#include <colors>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <dhooks>
#include <hgr>
#include <mapchooser>
#include <ckSurf>

#define VERSION "1.18"
#define PLUGIN_VERSION 118
#define MYSQL 0
#define SQLITE 1

#define WHITE 0x01
#define DARKRED 0x02
#define PURPLE 0x03
#define GREEN 0x04
#define MOSSGREEN 0x05
#define LIMEGREEN 0x06
#define RED 0x07
#define GRAY 0x08
#define YELLOW 0x09
#define DARKGREY 0x0A
#define BLUE 0x0B
#define DARKBLUE 0x0C
#define LIGHTBLUE 0x0D
#define PINK 0x0E
#define LIGHTRED 0x0F

#define BEAMLIFE 2.0

#define RGB_GREEN {0, 255, 0, 255}
#define RGB_RED {255, 0, 0, 255}
#define RGB_DARKRED {139, 0, 0, 255}
#define RGB_BLUE {0, 0, 255, 255}
#define RGB_LIGHTBLUE {178, 223, 238, 255}
#define RGB_DARKBLUE {0, 0, 139, 255}
#define RBG_YELLOW {255, 255, 0, 255}
#define RGB_GREENYELLOW {173, 255, 47, 255}
#define RGB_PURPLE {128, 0, 128, 255}
#define RGB_MAGENTA {255, 0, 255, 255}
#define RGB_PINK {238, 162, 173, 255}
#define RGB_WHITE {248, 248, 255, 255}
#define RGB_CYAN {0, 255, 255, 255}
#define RGB_SPRINGGREEN {0, 255, 127, 255}
#define RGB_OLIVE {192, 255, 62, 255}
#define RGB_ORANGE {238, 154, 0, 255}
#define RGB_GREY {145, 145, 145, 255}
#define RGB_DARKGREY {69, 69, 69, 255}
int RGB_COLORS[][] = {RGB_GREEN, RGB_RED, RGB_DARKRED, RGB_BLUE, RGB_LIGHTBLUE, RGB_DARKBLUE, RBG_YELLOW, RGB_GREENYELLOW, RGB_PURPLE, RGB_MAGENTA, RGB_PINK, RGB_WHITE, RGB_CYAN, RGB_SPRINGGREEN, RGB_OLIVE, RGB_ORANGE, RGB_GREY, RGB_DARKGREY}
char RGB_COLOR_NAMES[][] = {"Green", "Red", "Darkred", "Blue", "Lightblue", "Darkblue", "Yellow", "Greenyellow", "Purple", "Magenta", "Pink", "White", "Cyan", "Springgreen", "Olive", "Orange", "Grey", "Darkgrey"};

#define QUOTE 0x22
#define PERCENT 0x25

#define CPLIMIT 35
#define ZONEAMOUNT 9
#define MAXZONEGROUPS 11
#define MAXZONES 128
#define MAX_PR_PLAYERS 1066

#define HIDE_RADAR (1 << 12)
#define HIDE_CHAT ( 1<<7 )
#define CK_BUTTON_DONTMOVE (1<<0)		
#define CK_BUTTON_TOUCH_ACTIVATES (1<<8)	
#define CK_DOOR_PTOUCH (1<<10)

#define BM_MAGIC 0xBAADF00D
#define BINARY_FORMAT_VERSION 0x01
#define ADDITIONAL_FIELD_TELEPORTED_ORIGIN (1<<0)
#define ADDITIONAL_FIELD_TELEPORTED_ANGLES (1<<1)
#define ADDITIONAL_FIELD_TELEPORTED_VELOCITY (1<<2)
#define FRAME_INFO_SIZE 15
#define FRAME_INFO_SIZE_V1 14
#define AT_SIZE 10
#define ORIGIN_SNAPSHOT_INTERVAL 150
#define FILE_HEADER_LENGTH 74
#define TITLE_COUNT 23

#define BONUS_BOT_TRAIL_COLOR {255, 255, 0, 255}
#define RECORD_BOT_TRAIl_COLOR {0, 0, 255, 255}

enum FrameInfo 
{
	playerButtons = 0,
	playerImpulse,
	Float:actualVelocity[3],
	Float:predictedVelocity[3],
	Float:predictedAngles[2], 
	CSWeaponID:newWeapon,
	playerSubtype,
	playerSeed,
	additionalFields, 
	pause, 
}

enum AdditionalTeleport 
{
	Float:atOrigin[3],
	Float:atAngles[3],
	Float:atVelocity[3],
	atFlags
}

enum FileHeader 
{
	FH_binaryFormatVersion = 0,
	String:FH_Time[32],
	String:FH_Playername[32],
	FH_Checkpoints,
	FH_tickCount,
	Float:FH_initialPosition[3],
	Float:FH_initialAngles[3],
	Handle:FH_frames
}

enum EJoinTeamReason
{
	k_OneTeamChange=0,
	k_TeamsFull=1,
	k_TTeamFull=2,
	k_CTTeamFull=3
}

enum MapZone
{
    zoneId,			// ID within the map
    zoneType,		// Types: Start(1), End(2), BonusStart(3), BonusEnd(4), Stage(5), Checkpoint(6), Speed(7), TeleToStart(8), Validator(9), Chekcer(10), Stop(0)
    zoneTypeId,		// ID of the same type eg. Start-1, Start-2, Start-3...
	Float:PointA[3],
    Float:PointB[3],
	String:zoneName[128],
	zoneGroup,
	Vis,
	Team,
}

///////////////////
//Stage Variables//
///////////////////
int g_Stage[MAXZONEGROUPS][MAXPLAYERS+1];
bool g_bhasStages;

/////////////////////////
//// Spawn Locations ////
/////////////////////////
float g_fSpawnLocation[MAXZONEGROUPS][3];
float g_fSpawnAngle[MAXZONEGROUPS][3];
bool g_bGotSpawnLocation[MAXZONEGROUPS];

///////////////////////
//// Player titles ////
///////////////////////
bool g_bflagTitles[MAXPLAYERS+1][TITLE_COUNT];
bool g_bAdminFlagTitlesTemp[MAXPLAYERS+1][TITLE_COUNT];
bool g_bflagTitles_orig[MAXPLAYERS+1][TITLE_COUNT];
bool g_bAdminSelectedHasFlag[MAXPLAYERS+1];
bool g_bHasTitle[MAXPLAYERS+1];
char g_szflagTitle_Colored[TITLE_COUNT][128];
char g_szflagTitle[TITLE_COUNT][128];
char g_szAdminSelectedSteamID[MAXPLAYERS+1][32];
int g_iAdminSelectedClient[MAXPLAYERS+1];
int g_iAdminEditingType[MAXPLAYERS+1];
int g_iTitleInUse[MAXPLAYERS+1];
int g_iCustomTitleCount;

///////////////////////
//// VIP Variables ////
///////////////////////
bool g_bTrailOn[MAXPLAYERS+1];
bool g_bClientStopped[MAXPLAYERS+1];
bool g_bRefreshTrail[MAXPLAYERS+1];
int g_iTrailColor[MAXPLAYERS+1];
float g_fLastTrailTime[MAXPLAYERS+1];
float g_fClientLastMovement[MAXPLAYERS+1];
//Handle g_hTrailTimer[MAXPLAYERS+1] = {null, ...};

//////////////////////////
//// Replay Variables ////
//////////////////////////
bool g_bReplayAtEnd[MAXPLAYERS+1];
float g_fReplayRestarted[MAXPLAYERS+1];


///////////////////
//Bonus Variables//
///////////////////
//bool g_bBonusTimer[MAXPLAYERS+1];									// True if client is using the bonus timer
char g_szBonusFastest[MAXZONEGROUPS][MAX_NAME_LENGTH];				// Name of the #1 in the current maps bonus
char g_szBonusFastestTime[MAXZONEGROUPS][54];						// Fastest bonus time in 00:00:00:00 format
float g_fPersonalRecordBonus[MAXZONEGROUPS][MAXPLAYERS+1]; 			// Clients personal bonus record in the current map
char g_szPersonalRecordBonus[MAXZONEGROUPS][MAXPLAYERS+1][64];
float g_fBonusFastest[MAXZONEGROUPS];								// Fastest bonus time in the current map
float g_fOldBonusRecordTime[MAXZONEGROUPS];							// Old record time, for prints + counting
int g_MapRankBonus[MAXZONEGROUPS][MAXPLAYERS+1]; 						// Clients personal bonus rank in the current map
int g_OldMapRankBonus[MAXZONEGROUPS][MAXPLAYERS+1];						// Old rank in bonus
int g_bMissedBonusBest[MAXPLAYERS+1];									// Has the client mbissed his best bonus time
int g_tmpBonusCount[MAXZONEGROUPS];
int g_iBonusCount[MAXZONEGROUPS];			 							// Amount of players that have passed the bonus in current map
int g_totalBonusCount;													// How many total bonuses there are
//int g_inZoneGroup[MAXPLAYERS+1];										// In which bonus the player is currently in. 0 = normal map
bool g_bhasBonus;
int g_clientFinishedBonuses[MAX_PR_PLAYERS];
int g_ClientFinishedBonusesRowCount[MAX_PR_PLAYERS];
bool g_bBonusFirstRecord[MAXPLAYERS+1];
bool g_bBonusPBRecord[MAXPLAYERS+1];
bool g_bBonusSRVRecord[MAXPLAYERS+1];
char g_szBonusTimeDifference[MAXPLAYERS+1];

////////////////////////
//Checkpoint Variables//
////////////////////////
float g_fCheckpointTimesRecord[MAXZONEGROUPS][MAXPLAYERS+1][CPLIMIT];	// Clients best run's times
float g_fCheckpointTimesNew[MAXZONEGROUPS][MAXPLAYERS+1][CPLIMIT];		// Clients current runs times
float g_fCheckpointServerRecord[MAXZONEGROUPS][CPLIMIT];
char g_szLastSRDifference[MAXPLAYERS+1][64];
char g_szLastPBDifference[MAXPLAYERS+1][64];
float g_fLastDifferenceTime[MAXPLAYERS+1];
float tmpDiff[MAXPLAYERS+1];
int lastCheckpoint[MAXZONEGROUPS][MAXPLAYERS+1];
bool g_bCheckpointsEnabled[MAXPLAYERS+1];
bool g_borg_CheckpointsEnabled[MAXPLAYERS+1];
bool g_bCheckpointsFound[MAXZONEGROUPS][MAXPLAYERS+1];
bool g_bActivateCheckpointsOnStart[MAXPLAYERS+1];
bool g_bCheckpointRecordFound[MAXZONEGROUPS];


///////////////////
//Advert Variable//
///////////////////
int g_Advert;										// Defines which advert to play

/////////////////////
//MapTier Bariables//
/////////////////////
char g_sTierString[MAXZONEGROUPS][512];
bool g_bTierEntryFound;
bool g_bTierFound[MAXZONEGROUPS];
Handle AnnounceTimer[MAXPLAYERS+1];

//////////////////
//Zone Variables//
//////////////////
float g_fZonePositions[MAXZONES][3];
Handle g_hZoneDisplayType = null;
int g_zoneDisplayType;
Handle g_hZonesToDisplay = null;
int g_zonesToDisplay;
Handle g_hChecker;
float g_fChecker;


Handle g_hZoneTimer = INVALID_HANDLE;
bool g_bEditZoneType[MAXPLAYERS+1];
char g_CurrentZoneName[MAXPLAYERS+1][64];
float g_Positions[MAXPLAYERS+1][2][3];
float g_fBonusStartPos[MAXPLAYERS+1][2][3];
float g_fBonusEndPos[MAXPLAYERS+1][2][3];
float g_AvaliableScales[5]={1.0, 5.0, 10.0, 50.0, 100.0};
int beamColorT[] = {255, 0, 0, 255};
int beamColorCT[] = {0, 0, 255, 255};
int beamColorN[] = {255, 255, 0, 255};
int beamColorM[] = {0, 255, 0, 255};

int g_zoneStartColor[4];
Handle g_hzoneStartColor = null;
char g_szzoneStartColor[24];

int g_zoneEndColor[4];
Handle g_hzoneEndColor = null;
char g_szzoneEndColor[24];

int g_zoneBonusStartColor[4];
Handle g_hzoneBonusStartColor = null;
char g_szzoneBonusStartColor[24];


int g_zoneBonusEndColor[4];
Handle g_hzoneBonusEndColor = null;
char g_szzoneBonusEndColor[24];


int g_zoneStageColor[4];
Handle g_hzoneStageColor = null;
char g_szzoneStageColor[24];


int g_zoneCheckpointColor[4];
Handle g_hzoneCheckpointColor = null;
char g_szzoneCheckpointColor[24];


int g_zoneSpeedColor[4];
Handle g_hzoneSpeedColor = null;
char g_szzoneSpeedColor[24];


int g_zoneTeleToStartColor[4];
Handle g_hzoneTeleToStartColor = null;
char g_szzoneTeleToStartColor[24];


int g_zoneValidatorColor[4];
Handle g_hzoneValidatorColor = null;
char g_szzoneValidatorColor[24];


int g_zoneCheckerColor[4];
Handle g_hzoneCheckerColor = null;
char g_szzoneCheckerColor[24];


int g_zoneStopColor[4];
Handle g_hzoneStopColor = null;
char g_szzoneStopColor[24];
char g_szZoneDefaultNames[ZONEAMOUNT][128] = {"Stop", "Start", "End", "Stage", "Checkpoint", "SpeedStart", "TeleToStart", "Validator", "Checker"};

int g_CurrentZoneGroup[MAXPLAYERS+1];
int g_CurrentZoneTeam[MAXPLAYERS+1];
int g_CurrentZoneVis[MAXPLAYERS+1];
int g_CurrentZoneType[MAXPLAYERS+1];
int g_Editing[MAXPLAYERS+1];
int g_ClientSelectedZone[MAXPLAYERS+1]={-1,...};
int g_BeamSprite;
int g_HaloSprite;
int g_mapZonesTypeCount[MAXZONEGROUPS][ZONEAMOUNT];
char g_szZoneGroupName[MAXZONEGROUPS][128];
int g_mapZones[MAXZONES][MapZone];
int g_mapZonesCount;
int g_mapZoneCountinGroup[MAXZONEGROUPS];
int g_mapZoneGroupCount;
int g_ClientSelectedScale[MAXPLAYERS+1];
int g_ClientSelectedPoint[MAXPLAYERS+1];
int g_CurrentZoneTypeId[MAXPLAYERS+1];
bool g_ClientRenamingZone[MAXPLAYERS+1];


// PushFix by Mev, George, & Blacky
// https://forums.alliedmods.net/showthread.php?t=267131
ConVar g_hTriggerPushFixEnable;
bool   g_bTriggerPushFixEnable;

// Slope Boost Fix by Mev, & Blacky
// https://forums.alliedmods.net/showthread.php?t=266888
float g_vCurrent[MAXPLAYERS + 1][3];
float g_vLast[MAXPLAYERS + 1][3];

bool g_bOnGroundFix[MAXPLAYERS + 1];
bool g_bLastOnGround[MAXPLAYERS + 1];

ConVar g_hSlopeFixEnable;
bool   g_bSlopeFixEnable;

//////////////////////
// ckSurf Variables///
//////////////////////
// Forwards
Handle g_MapFinishForward;
Handle g_BonusFinishForward;
Handle g_PracticeFinishForward;

char szWHITE[12], szDARKRED[12], szPURPLE[12], szGREEN[12], szMOSSGREEN[12], szLIMEGREEN[12], szRED[12], szGRAY[12], szYELLOW[12], szDARKGREY[12], szBLUE[12], szDARKBLUE[12], szLIGHTBLUE[12], szPINK[12], szLIGHTRED[12];


int g_successfulTransactions;
int g_failedTransactions[5];

bool g_bInTransactionChain = false;
float g_flastClientUsp[MAXPLAYERS+1];
bool g_insertingInformation;
bool g_bValidRun[MAXPLAYERS+1];
bool g_bNewRecordBot;
bool g_bNewBonusBot;
bool g_bHideChat[MAXPLAYERS+1];
bool g_borg_HideChat[MAXPLAYERS+1];
bool g_bViewModel[MAXPLAYERS+1];
bool g_borg_ViewModel[MAXPLAYERS+1];
int g_DbType;
float g_fMaxPercCompleted[MAXPLAYERS+1];
Handle g_hTeleport = null;
Handle g_hMainMenu = null;
Handle g_hAdminMenu = null;
Handle g_MapList = null;
Handle g_hDb = null;
Handle g_hLangMenu = null;
Handle g_hCookie = null;
Handle g_OnLangChanged = null;
Handle g_hRecording[MAXPLAYERS+1];
Handle g_hLoadedRecordsAdditionalTeleport = null;
Handle g_hBotMimicsRecord[MAXPLAYERS+1] = {null,...};
Handle g_hP2PRed[MAXPLAYERS+1] = { null,... };
Handle g_hP2PGreen[MAXPLAYERS+1] = { null,... };
Handle g_hRecordingAdditionalTeleport[MAXPLAYERS+1];
Handle g_hTopJumpersMenu[MAXPLAYERS+1] = null;
Handle g_hWelcomeMsg = null;
char g_sWelcomeMsg[512];  
Handle g_hReplayBotPlayerModel = null;
char g_sReplayBotPlayerModel[256];  
Handle g_hReplayBotArmModel = null;
char g_sReplayBotArmModel[256];  
char g_sReplayBotPlayerModel2[256];  
char g_sReplayBotArmModel2[256];  
Handle g_hPlayerModel = null;
char g_sPlayerModel[256];  
Handle g_hArmModel = null;
char g_sArmModel[256];  
Handle g_hcvarRestore = null;
bool g_bRestore;
Handle g_hNoClipS = null;
bool g_bNoClipS;
Handle g_hReplayBot = null;
bool g_bReplayBot;
Handle g_hBonusBot = null;
bool g_bBonusBot;
Handle g_hColoredNames = null;
bool g_bColoredNames;
Handle g_hPauseServerside = null;
bool g_bPauseServerside;
Handle g_hChallengePoints = null;
bool g_bChallengePoints;
Handle g_hAutoBhopConVar = null;
bool g_bAutoBhopConVar;
bool g_bAutoBhop;
Handle g_hDynamicTimelimit = null;
bool g_bDynamicTimelimit;
Handle g_hAdminClantag = null;
bool g_bAdminClantag;
Handle g_hConnectMsg = null;
bool g_bConnectMsg;
Handle g_hDisconnectMsg = null;
bool g_bDisconnectMsg;
Handle g_hRadioCommands = null;
bool g_bRadioCommands;
Handle g_hInfoBot = null;
bool g_bInfoBot;
Handle g_hAttackSpamProtection = null;
bool g_bAttackSpamProtection;
Handle g_hGoToServer = null;
bool g_bGoToServer;
Handle g_hAllowRoundEndCvar = null;
bool g_bAllowRoundEndCvar;
Handle g_hPlayerSkinChange = null;
bool g_bPlayerSkinChange;
Handle g_hCountry = null;
bool g_bCountry;
Handle g_hAutoRespawn = null;
bool g_bAutoRespawn;
Handle g_hcvarNoBlock = null;
bool g_bNoBlock;
Handle g_hPointSystem = null;
bool g_bPointSystem;
Handle g_hCleanWeapons = null;
bool g_bCleanWeapons;
Handle g_hcvargodmode = null;
bool g_bAutoTimer;
Handle g_hAutoTimer = null;
bool g_bgodmode;
Handle g_hMapEnd = null;
bool g_bMapEnd;
Handle g_hAutohealing_Hp = null;
int g_Autohealing_Hp;
Handle g_hExtraPoints = null;
int g_ExtraPoints;
Handle g_hExtraPoints2 = null;
int g_ExtraPoints2;

// Bot Colors & effects:
Handle g_hReplayBotColor = null;
int g_ReplayBotColor[3];
Handle g_hBonusBotColor = null;
int g_BonusBotColor[3];

Handle g_hBonusBotTrail = null;
bool g_bBonusBotTrailEnabled;

Handle g_hRecordBotTrail = null;
bool g_bRecordBotTrailEnabled;

Handle g_hReplayBotTrailColor = null;
int g_ReplayBotTrailColor[4];
Handle g_hBonusBotTrailColor = null;
int g_BonusBotTrailColor[4];

float g_fMapStartTime;
float g_fvMeasurePos[MAXPLAYERS+1][2][3];
float g_fStartTime[MAXPLAYERS+1];
float g_fFinalTime[MAXPLAYERS+1];
float g_fPauseTime[MAXPLAYERS+1];
float g_fLastTimeNoClipUsed[MAXPLAYERS+1];
float g_fLastOverlay[MAXPLAYERS+1];
float g_fStartPauseTime[MAXPLAYERS+1];
float g_fPlayerCordsLastPosition[MAXPLAYERS+1][3];
float g_fPlayerLastTime[MAXPLAYERS+1];
float g_fPlayerAnglesLastPosition[MAXPLAYERS+1][3];
float g_fPlayerCordsRestart[MAXPLAYERS+1][3]; 
float g_fPlayerAnglesRestart[MAXPLAYERS+1][3]; 
float g_fPlayerCordsRestore[MAXPLAYERS+1][3];
float g_fPlayerAnglesRestore[MAXPLAYERS+1][3];
float g_fPersonalRecord[MAXPLAYERS+1];
char g_szPersonalRecord[MAXPLAYERS+1][64];
float g_fCurrentRunTime[MAXPLAYERS+1];
float g_fLastTimeButtonSound[MAXPLAYERS+1];
float g_fPlayerConnectedTime[MAXPLAYERS+1];
float g_fStartCommandUsed_LastTime[MAXPLAYERS+1];
float g_fProfileMenuLastQuery[MAXPLAYERS+1];
float g_favg_maptime;
float g_fAvg_BonusTime[MAXZONEGROUPS];
float g_fSpawnpointOrigin[3];
float g_fSpawnpointAngle[3];
float g_fLastSpeed[MAXPLAYERS+1];
float g_fInitialPosition[MAXPLAYERS+1][3];
float g_fInitialAngles[MAXPLAYERS+1][3];
float g_fChallenge_RequestTime[MAXPLAYERS+1];
float g_fSpawnPosition[MAXPLAYERS+1][3]; 
float g_fLastPosition[MAXPLAYERS+1][3];
float g_fLastAngles[MAXPLAYERS+1][3];
float g_fRecordMapTime;
char g_szRecordMapTime[64];
float g_pr_finishedmaps_perc[MAX_PR_PLAYERS]; 
bool g_bRenaming = false;
bool g_bLateLoaded = false;
bool g_bRoundEnd;
bool g_bMapReplay;
bool g_bMapBonusReplay;
bool g_pr_RankingRecalc_InProgress;
bool g_bHookMod;
bool g_bMapChooser;
bool g_bUseCPrefs;
bool g_bLoaded[MAXPLAYERS+1];
bool g_bFirstButtonTouch[MAXPLAYERS+1];
bool g_bClientOwnReason[MAXPLAYERS + 1];
bool g_pr_Calculating[MAXPLAYERS+1];
bool g_bChallenge_Checkpoints[MAXPLAYERS+1];
bool g_bNoClipUsed[MAXPLAYERS+1];
bool g_bPause[MAXPLAYERS+1];
bool g_bPauseWasActivated[MAXPLAYERS+1];
bool g_bOverlay[MAXPLAYERS+1];
bool g_bSpectate[MAXPLAYERS+1];
bool g_bTimeractivated[MAXPLAYERS+1];
bool g_bFirstTeamJoin[MAXPLAYERS+1];
bool g_bFirstSpawn[MAXPLAYERS+1];
bool g_bTop100Refresh;
bool g_bMissedMapBest[MAXPLAYERS+1];
bool g_bRestorePosition[MAXPLAYERS+1]; 
bool g_bRestorePositionMsg[MAXPLAYERS+1]; 
bool g_bNoClip[MAXPLAYERS+1];
bool g_bMapFinished[MAXPLAYERS+1]; 
bool g_bRespawnPosition[MAXPLAYERS+1]; 
bool g_bProfileRecalc[MAX_PR_PLAYERS];
bool g_bProfileSelected[MAXPLAYERS+1]; 
bool g_bManualRecalc; 
bool g_bSelectProfile[MAXPLAYERS+1]; 
bool g_bChallenge_Abort[MAXPLAYERS+1];
bool g_bValidTeleportCall[MAXPLAYERS+1];
bool g_bMapRankToChat[MAXPLAYERS+1];
bool g_bChallenge[MAXPLAYERS+1];
bool g_bChallenge_Request[MAXPLAYERS+1];
bool g_pr_showmsg[MAXPLAYERS+1];
bool g_bRecalcRankInProgess[MAXPLAYERS+1];
bool g_bLanguageSelected[MAXPLAYERS+1];
bool g_bNewReplay[MAXPLAYERS+1];
bool g_bNewBonus[MAXPLAYERS+1];
bool g_bPositionRestored[MAXPLAYERS+1];
bool g_bInfoPanel[MAXPLAYERS+1];
bool g_bEnableQuakeSounds[MAXPLAYERS+1];
bool g_bShowNames[MAXPLAYERS+1]; 
bool g_bStartWithUsp[MAXPLAYERS+1];
bool g_bShowTime[MAXPLAYERS+1]; 
bool g_bHide[MAXPLAYERS+1];   
bool g_bShowSpecs[MAXPLAYERS+1]; 
bool g_bGoToClient[MAXPLAYERS+1]; 
bool g_bMeasurePosSet[MAXPLAYERS+1][2];
bool g_bAutoBhopClient[MAXPLAYERS+1];
bool g_borg_StartWithUsp[MAXPLAYERS+1];
bool g_borg_InfoPanel[MAXPLAYERS+1];
bool g_borg_EnableQuakeSounds[MAXPLAYERS+1];
bool g_borg_ShowNames[MAXPLAYERS+1]; 
bool g_borg_GoToClient[MAXPLAYERS+1]; 
bool g_borg_ShowTime[MAXPLAYERS+1]; 
bool g_borg_Hide[MAXPLAYERS+1]; 
bool g_borg_ShowSpecs[MAXPLAYERS+1]; 
bool g_borg_AutoBhopClient[MAXPLAYERS+1];
bool g_bBeam[MAXPLAYERS+1];
bool g_bOnGround[MAXPLAYERS+1];
bool g_specToStage[MAXPLAYERS+1];
float g_fLastTimeMoved[MAXPLAYERS+1];
bool g_bMoving[MAXPLAYERS+1];
float g_fTeleLocation[MAXPLAYERS+1][3];
float g_fCurVelVec[MAXPLAYERS+1][3];

// Player checkpoints
float g_fCheckpointVelocity_undo[MAXPLAYERS+1][3];
float g_fCheckpointVelocity[MAXPLAYERS+1][3];
float g_fCheckpointLocation[MAXPLAYERS+1][3];
float g_fCheckpointLocation_undo[MAXPLAYERS+1][3];
float g_fCheckpointAngle[MAXPLAYERS+1][3];
float g_fCheckpointAngle_undo[MAXPLAYERS+1][3];
float g_fLastPlayerCheckpoint[MAXPLAYERS+1];

bool g_bCreatedTeleport[MAXPLAYERS+1];
bool g_bPracticeMode[MAXPLAYERS+1];

int g_unfinishedMaps[MAXPLAYERS+1];
int g_unfinishedBonuses[MAXPLAYERS+1];
int g_Beam[3];
int g_TSpawns=-1;
int g_CTSpawns=-1;
int g_ownerOffset;
int g_ragdolls = -1;
int g_Server_Tickrate;
int g_MapTimesCount;
int g_RecordBot=-1;
int g_BonusBot=-1;
int g_InfoBot=-1;
int g_pr_Recalc_ClientID = 0;
int g_pr_Recalc_AdminID=-1; 
int g_pr_AllPlayers;
int g_pr_RankedPlayers;
int g_pr_MapCount;
int g_pr_rank_Percentage[9];
int g_pr_PointUnit;
int g_pr_TableRowCount;
int g_pr_points[MAX_PR_PLAYERS];
int g_pr_maprecords_row_counter[MAX_PR_PLAYERS];
int g_pr_maprecords_row_count[MAX_PR_PLAYERS];
int g_pr_oldpoints[MAX_PR_PLAYERS];  
int g_pr_multiplier[MAX_PR_PLAYERS]; 
int g_pr_finishedmaps[MAX_PR_PLAYERS];
int g_PlayerRank[MAXPLAYERS+1];
int g_SelectedTeam[MAXPLAYERS+1];
int g_BotMimicRecordTickCount[MAXPLAYERS+1] = {0,...};
int g_BotActiveWeapon[MAXPLAYERS+1] = {-1,...};
int g_CurrentAdditionalTeleportIndex[MAXPLAYERS+1];
int g_RecordedTicks[MAXPLAYERS+1];
int g_RecordPreviousWeapon[MAXPLAYERS+1];
int g_OriginSnapshotInterval[MAXPLAYERS+1];
int g_BotMimicTick[MAXPLAYERS+1] = {0,...};
int g_AttackCounter[MAXPLAYERS + 1];
int g_MenuLevel[MAXPLAYERS+1];
int g_Challenge_Bet[MAXPLAYERS+1];
int g_MapRank[MAXPLAYERS+1];
int g_OldMapRank[MAXPLAYERS+1];
int g_Time_Type[MAXPLAYERS+1];
int g_Sound_Type[MAXPLAYERS+1];
int g_MapRecordCount[MAXPLAYERS+1];
bool g_bnewRecord[MAXPLAYERS+1];
int g_Challenge_WinRatio[MAX_PR_PLAYERS];
int g_CountdownTime[MAXPLAYERS+1];
int g_Challenge_PointsRatio[MAX_PR_PLAYERS];
int g_SpecTarget[MAXPLAYERS+1];
int g_LastButton[MAXPLAYERS + 1];
int g_CurrentButton[MAXPLAYERS+1];
int g_MVPStars[MAXPLAYERS+1];
int g_AdminMenuLastPage[MAXPLAYERS+1];
int g_OptionsMenuLastPage[MAXPLAYERS+1];
int g_PlayerChatRank[MAXPLAYERS+1];
char g_pr_chat_coloredrank[MAXPLAYERS+1][128];
char g_pr_rankname[MAXPLAYERS+1][128];  
char g_pr_szrank[MAXPLAYERS+1][512];  
char g_pr_szName[MAX_PR_PLAYERS][64];  
char g_pr_szSteamID[MAX_PR_PLAYERS][32]; 
char g_szMapPrefix[2][32]; 
char g_szReplayName[128];  
char g_szReplayTime[128]; 
char g_szBonusName[128];
char g_szBonusTime[128];
char g_szChallenge_OpponentID[MAXPLAYERS+1][32]; 
char g_szTimeDifference[MAXPLAYERS+1][32]; 
char g_szFinalTime[MAXPLAYERS+1][32];
char g_szMapName[128];
char g_szMapTopName[MAXPLAYERS+1][128];
//char g_szTimerTitle[MAXPLAYERS+1][255];
char g_szRecordPlayer[MAX_NAME_LENGTH];
char g_szProfileName[MAXPLAYERS+1][MAX_NAME_LENGTH];
char g_szPlayerPanelText[MAXPLAYERS+1][512];
char g_szProfileSteamId[MAXPLAYERS+1][32];
char g_szCountry[MAXPLAYERS+1][100];
char g_szCountryCode[MAXPLAYERS+1][16]; 
char g_szSteamID[MAXPLAYERS+1][32];  
char g_szSkillGroups[9][32];
char g_szServerName[64];  
char g_szServerIp[32];
char g_szServerCountry[100]; 
char g_szServerCountryCode[32]; 
char EntityList[][] = {"logic_timer", "team_round_timer", "logic_relay", "trigger_hurt", "/weapon_.*/"};
char CK_REPLAY_PATH[] = "data/cKreplays/";
char BLOCKED_LIST_PATH[] = "configs/ckSurf/hidden_chat_commands.txt";
char CUSTOM_TITLE_PATH[] = "configs/ckSurf/custom_chat_titles.txt";
char PRO_FULL_SOUND_PATH[] = "sound/quake/holyshit.mp3";
char PRO_RELATIVE_SOUND_PATH[] = "*quake/holyshit.mp3";
char CP_FULL_SOUND_PATH[] = "sound/quake/wickedsick.mp3";
char CP_RELATIVE_SOUND_PATH[] = "*quake/wickedsick.mp3";
char UNSTOPPABLE_SOUND_PATH[] = "sound/quake/unstoppable.mp3";
char UNSTOPPABLE_RELATIVE_SOUND_PATH[] = "*quake/unstoppable.mp3";
char g_sModel[] = "models/props/de_train/barrel.mdl";
char RadioCMDS[][] = {"coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog",
	"getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin",
	"getout", "negative","enemydown","cheer","thanks","nice","compliment"};
char g_BlockedChatText[256][256];
char g_szReplay_PlayerName[MAXPLAYERS+1][64];

// Speed Cap Variables
Handle g_hStartPreSpeed = null; 
float g_fStartPreSpeed; 
Handle g_hSpeedPreSpeed = null; 
float g_fSpeedPreSpeed; 
Handle g_hBonusPreSpeed = null; 
float g_fBonusPreSpeed; 

bool g_bIgnoreZone[MAXPLAYERS+1];

int g_iClientInZone[MAXPLAYERS+1][4];

Handle g_hSoundEnabled = null; 
bool bSoundEnabled; 

Handle g_hSoundPath = null; 
char sSoundPath[64]; 

//////////////////////
// CVARS//////////////
//////////////////////

// Teleport on spawn to start zone (or speed zone) stuff 
Handle g_hSpawnToStartZone = null; 
bool bSpawnToStartZone; 

// Min rank to announce in chat
Handle g_hAnnounceRank = null;
int g_AnnounceRank;
// Force players CT
Handle g_hForceCT = null;
bool g_bForceCT;

// Chat spam limiter
Handle g_hChatSpamFilter = null;
float g_fChatSpamFilter;
float g_fLastChatMessage[MAXPLAYERS+1];
int g_messages[MAXPLAYERS+1];

// Is chat processing enabled
Handle g_henableChatProcessing = null;
bool g_benableChatProcessing;

#include "ckSurf/misc.sp"
#include "ckSurf/admin.sp"
#include "ckSurf/commands.sp"
#include "ckSurf/hooks.sp"
#include "ckSurf/buttonpress.sp"
#include "ckSurf/sql.sp"
#include "ckSurf/timer.sp"
#include "ckSurf/replay.sp"
#include "ckSurf/surfzones.sp"

public OnLibraryAdded(const String:name[])
{
	if (StrEqual("hookgrabrope", name))
		g_bHookMod = true;
	Handle tmp = FindPluginByFile("mapchooser_extended.smx");
	if ((StrEqual("mapchooser", name)) ||(tmp != null && GetPluginStatus(tmp) == Plugin_Running))
		g_bMapChooser = true;
	if (tmp != null)
		CloseHandle(tmp);
	
	//botmimic 2
	if(StrEqual(name, "dhooks") && g_hTeleport == null)
	{
		// Optionally setup a hook on CBaseEntity::Teleport to keep track of sudden place changes
		Handle hGameData = LoadGameConfigFile("sdktools.games");
		if(hGameData == null)
			return;
		int iOffset = GameConfGetOffset(hGameData, "Teleport");
		CloseHandle(hGameData);
		if(iOffset == -1)
			return;
		
		g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
		if(g_hTeleport == null)
			return;
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		if(GetEngineVersion() == Engine_CSGO)
			DHookAddParam(g_hTeleport, HookParamType_Bool);
		
		for(int i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i))
				OnClientPutInServer(i);
		}
	}
}

public OnClientPostAdminCheck(int client)
{
	g_ClientSelectedZone[client]=-1;
	g_Editing[client]=0;
}

public OnPluginEnd()
{
	//remove clan tags
	for (int x = 1; x <= MaxClients; x++)
	{
		if (IsValidClient(x))
		{
			SetEntPropEnt(x, Prop_Send, "m_bSpotted", 1);
			SetEntProp(x, Prop_Send, "m_iHideHUD", 0);
			SetEntProp(x, Prop_Send, "m_iAccount", 1);			
			CS_SetClientClanTag(x, "");
			OnClientDisconnect(x);
		}
 	}


	//set server convars back to default
	ServerCommand("sm_cvar sv_enablebunnyhopping 0;sv_friction 5.2;sv_accelerate 5.5;sv_airaccelerate 10;sv_maxvelocity 2000;sv_staminajumpcost .08;sv_staminalandcost .050");
	ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0;mp_respawnwavetime_ct 10.0;mp_respawnwavetime_t 10.0;bot_zombie 0;mp_ignore_round_win_conditions 0");
	ServerCommand("sv_infinite_ammo 0;mp_endmatch_votenextmap 1;mp_do_warmup_period 1;mp_warmuptime 60;mp_match_can_clinch 1;mp_match_end_changelevel 0");
	ServerCommand("mp_match_restart_delay 15;mp_endmatch_votenextleveltime 20;mp_endmatch_votenextmap 1;mp_halftime 0;mp_do_warmup_period 1;mp_maxrounds 0;bot_quota 0");		
	ServerCommand("mp_startmoney 800; mp_playercashawards 1; mp_teamcashawards 1");
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		g_hAdminMenu = null;
	if(StrEqual(name, "dhooks"))
		g_hTeleport = null;
	if (StrEqual("hookgrabrope", name))
		g_bHookMod = false;
}

public OnAllPluginsLoaded()
{
	if (LibraryExists("hookgrabrope"))
		g_bHookMod = true;
}

public OnMapStart()
{
	//get mapname
	GetCurrentMap(g_szMapName, 128);

	CreateSpawns();

	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_HaloSprite = PrecacheModel("materials/sprites/halo.vmt", true);
	PrecacheModel(g_sModel);

	checkZoneTypeIds();

	//workshop fix
	char mapPieces[6][128];
	int lastPiece = ExplodeString(g_szMapName, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[])); 
	Format(g_szMapName, sizeof(g_szMapName), "%s", mapPieces[lastPiece-1]); 
	
	//get map tag
	ExplodeString(g_szMapName, "_", g_szMapPrefix, 2, 32);

	//sv_pure 1 could lead to problems with the ckSurf models
	ServerCommand("sv_pure 0");
			
	//reload language files
	LoadTranslations("ckSurf.phrases");	

	loadHiddenChatCommands();
	
	loadCustomTitles();

	// TODO: Load config that disables push fix on certain maps.

	g_insertingInformation = false;
	g_bTierEntryFound = false;
	g_fMapStartTime = GetGameTime();
	g_fRecordMapTime=9999999.0;
	g_fSpawnpointOrigin = Float:{-999999.9,-999999.9,-999999.9};
	g_fSpawnpointAngle = Float:{-999999.9,-999999.9,-999999.9};
	g_MapTimesCount = 0;
	g_RecordBot = -1;
	g_BonusBot = -1;
	g_InfoBot = -1;
	g_bAutoBhop = false;
	g_bRoundEnd = false;
	CheatFlag("bot_zombie", false, true);
	for (int i = 0; i<MAXZONEGROUPS; i++)
	{
		g_bTierFound[i] = false;
		g_fBonusFastest[i]=9999999.0;
		g_bCheckpointRecordFound[i] = false;
	}

	InitZoneVariables();
	OnConfigsExecuted();

	//precache
	InitPrecache();	
	SetCashState();

	//sql queries
	if (!g_bRenaming && !g_bInTransactionChain)
	{
		db_GetMapRecord_Pro();
		db_CalculatePlayerCount();
		db_viewMapProRankCount();
		db_ClearLatestRecords();
		db_GetDynamicTimelimit();
	}

	//timers
	CreateTimer(0.1, CKTimer1, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(1.0, CKTimer2, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(60.0, AttackTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(600.0, PlayerRanksTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	g_hZoneTimer = CreateTimer(g_fChecker, BeamBoxAll, _, TIMER_REPEAT);

	
	if (g_bAutoRespawn)
		ServerCommand("mp_respawn_on_death_ct 1;mp_respawn_on_death_t 1;mp_respawnwavetime_ct 3.0;mp_respawnwavetime_t 3.0");
	else
		ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0");
	ServerCommand("sv_infinite_ammo 2;mp_endmatch_votenextmap 0;mp_do_warmup_period 0;mp_warmuptime 0;mp_match_can_clinch 0;mp_match_end_changelevel 1;mp_match_restart_delay 10;mp_endmatch_votenextleveltime 10;mp_endmatch_votenextmap 0;mp_halftime 0;	bot_zombie 1;mp_do_warmup_period 0;mp_maxrounds 1");	

	//AutoBhop?
	if (g_bAutoBhopConVar)
		g_bAutoBhop=true;		

	//main cfg
	CreateTimer(1.0, DelayedStuff, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);

	//server infos
	GetServerInfo();
	
	if (g_bLateLoaded)
	{
		OnAutoConfigsBuffered();
	}

	g_Advert = 0;
	CreateTimer(180.0, AdvertTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);

	int iEnt;
	for(int i = 0; i < sizeof(EntityList); i++)
	{
		while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
		{
			AcceptEntityInput(iEnt, "Disable");
			AcceptEntityInput(iEnt, "Kill");
		}
	}

	// PushFix by Mev, George, & Blacky
	// https://forums.alliedmods.net/showthread.php?t=267131
	iEnt = -1;
	while((iEnt = FindEntityByClassname(iEnt, "trigger_push")) != -1)
	{
		SDKHook(iEnt, SDKHook_Touch, OnTouchPushTrigger);
	}
}

public OnMapEnd()
{
	for (int i = 0; i < MAXZONEGROUPS; i++)
		Format(g_sTierString[i], 512,  "");

	g_RecordBot = -1;
	g_BonusBot = -1;
	db_Cleanup();

	Format(g_szMapName, sizeof(g_szMapName), "");
}

public OnConfigsExecuted()
{
	char map[128];
	char map2[128];
	int mapListSerial = -1;
	g_pr_MapCount=0;
	if (ReadMapList(g_MapList, 
			mapListSerial, 
			"mapcyclefile", 
			MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT)
		== null)
	{
		if (mapListSerial == -1)
		{
			SetFailState("<ckSurf> Mapcycle.txt is empty or does not exists.");
		}
	}
	for (int i = 0; i < GetArraySize(g_MapList); i++)
	{
		GetArrayString(g_MapList, i, map, sizeof(map));
		if (!StrEqual(map, "", false))
		{
			//fix workshop map name			
			char mapPieces[6][128];
			int lastPiece = ExplodeString(map, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[])); 
			Format(map2, sizeof(map2), "%s", mapPieces[lastPiece-1]); 
			SetArrayString(g_MapList, i, map2);
			g_pr_MapCount++;
		}
	}	

	// Count the amount of bonuses and then set skillgroups
	db_selectBonusCount();	
		
	ServerCommand("sv_pure 0");
}


public OnAutoConfigsBuffered() 
{
	//just to be sure that it's not empty
	decl String:szMap[128];  
	decl String:szPrefix[2][32];  
	GetCurrentMap(szMap, 128);
	decl String:mapPieces[6][128];
	int lastPiece = ExplodeString(szMap, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[])); 
	Format(szMap, sizeof(szMap), "%s", mapPieces[lastPiece-1]); 
 	ExplodeString(szMap, "_", szPrefix, 2, 32);

	
	//map config
	decl String:szPath[256];
	Format(szPath, sizeof(szPath), "sourcemod/ckSurf/map_types/%s_.cfg",szPrefix[0]);
	decl String:szPath2[256];
	Format(szPath2, sizeof(szPath2), "cfg/%s",szPath);
	if (FileExists(szPath2))
		ServerCommand("exec %s", szPath);
	else
		SetFailState("<ckSurf> %s not found.", szPath2);
	
	SetServerTags();
}

public OnClientConnected(int client)
	g_SelectedTeam[client]=0;

public OnClientPutInServer(int client)
{
	if (!IsValidClient(client))
		return;
		
	//SDKHooks/Dhooks
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost); 
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);	
	SDKHook(client, SDKHook_PreThink, OnPlayerThink);
	SDKHook(client, SDKHook_PreThinkPost, OnPlayerThink);
	SDKHook(client, SDKHook_Think, OnPlayerThink);
	SDKHook(client, SDKHook_PostThink, OnPlayerThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPlayerThink);

	if (IsFakeClient(client))
	{
		g_hRecordingAdditionalTeleport[client] = CreateArray(_:AdditionalTeleport);
		CS_SetMVPCount(client,1);	
		return;
	}	
	else
		g_MVPStars[client] = 0;	
			
	//defaults
	SetClientDefaults(client);
	
	//client country
	GetCountry(client);		

	//client language
	if (g_bUseCPrefs && !IsFakeClient(client))
		if (AreClientCookiesCached(client) && !g_bLoaded[client])
			LoadCookies(client);
			

	if(LibraryExists("dhooks"))
		DHookEntity(g_hTeleport, false, client);	
			
	//get client data
	GetClientAuthId(client, AuthId_Steam2, g_szSteamID[client], MAX_NAME_LENGTH, true)
	//GetClientAuthString(client, g_szSteamID[client], 32);

	// ' char fix
	FixPlayerName(client);
	
	//position restoring
	if(g_bRestore && !g_bRenaming)
		db_selectLastRun(client);		
			
	//console info
	PrintConsoleInfo(client);
	
	if (g_bLateLoaded && IsPlayerAlive(client))
		PlayerSpawn(client);

	if (g_bTierFound[0])
		AnnounceTimer[client] = CreateTimer(20.0, AnnounceMap, client, TIMER_FLAG_NO_MAPCHANGE);

	if (!g_bRenaming)
	{
		db_viewPlayerPoints(client);
		db_viewPlayerOptions(client, g_szSteamID[client]);	
		db_viewPersonalFlags(client, g_szSteamID[client]);

		for (int i = 0; i < g_mapZoneGroupCount; i++) 
			db_viewCheckpoints(client, g_szSteamID[client], g_szMapName, i);

	 	db_viewPersonalRecords(client,g_szSteamID[client],g_szMapName);	
		db_viewPersonalBonusRecords(client, g_szSteamID[client]);
	}
}

public OnClientAuthorized(client)
{
	if (g_bConnectMsg && !IsFakeClient(client))
	{
		decl String:s_Country[32];
		decl String:s_clientName[32];
		decl String:s_address[32];		
		GetClientIP(client, s_address, 32);
		GetClientName(client, s_clientName, 32);
		Format(s_Country, 100, "Unknown");
		GeoipCountry(s_address, s_Country, 100);     
		if(!strcmp(s_Country, NULL_STRING))
			Format( s_Country, 100, "Unknown", s_Country );
		else				
			if( StrContains( s_Country, "United", false ) != -1 || 
				StrContains( s_Country, "Republic", false ) != -1 || 
				StrContains( s_Country, "Federation", false ) != -1 || 
				StrContains( s_Country, "Island", false ) != -1 || 
				StrContains( s_Country, "Netherlands", false ) != -1 || 
				StrContains( s_Country, "Isle", false ) != -1 || 
				StrContains( s_Country, "Bahamas", false ) != -1 || 
				StrContains( s_Country, "Maldives", false ) != -1 || 
				StrContains( s_Country, "Philippines", false ) != -1 || 
				StrContains( s_Country, "Vatican", false ) != -1 )
			{
				Format( s_Country, 100, "The %s", s_Country );
			}				
					
		if (StrEqual(s_Country, "Unknown",false) || StrEqual(s_Country, "Localhost",false))
		{	
			for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != client)
				PrintToChat(i, "%t", "Connected1", WHITE,MOSSGREEN, s_clientName, WHITE);
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i) && i != client)
					PrintToChat(i, "%t", "Connected2", WHITE, MOSSGREEN,s_clientName, WHITE,GREEN,s_Country);
		}
	}
}

public OnClientDisconnect(int client)
{
	if (IsFakeClient(client) && g_hRecordingAdditionalTeleport[client] != null)
		CloseHandle(g_hRecordingAdditionalTeleport[client]);

	g_fPlayerLastTime[client] = -1.0;
	if(g_fStartTime[client] != -1.0 && g_bTimeractivated[client])
	{
		if (g_bPause[client])
		{
			g_fPauseTime[client] = GetGameTime() - g_fStartPauseTime[client];
			g_fPlayerLastTime[client] = GetGameTime() - g_fStartTime[client] - g_fPauseTime[client];	
		}
		else
			g_fPlayerLastTime[client] = g_fCurrentRunTime[client];
	}
		
	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost); 
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);	
	SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
	SDKUnhook(client, SDKHook_PreThinkPost, OnPlayerThink);
	SDKUnhook(client, SDKHook_Think, OnPlayerThink);
	SDKUnhook(client, SDKHook_PostThink, OnPlayerThink);
	SDKUnhook(client, SDKHook_PostThinkPost, OnPlayerThink);
	
	if (client == g_RecordBot)
	{
		StopPlayerMimic(client);
		g_RecordBot = -1;
		return;
	}
	if (client == g_BonusBot)
	{
		StopPlayerMimic(client)
		g_BonusBot = -1;
		return;
	}

	// Stop trail
	g_bTrailOn[client] = false;


	//Database	
	if (IsValidClient(client) && !g_bRenaming)
	{
		if (!g_bIgnoreZone[client] && !g_bPracticeMode[client])
			db_insertLastPosition(client, g_szMapName, g_Stage[g_iClientInZone[client][2]][client], g_iClientInZone[client][2]);
		
		db_updatePlayerOptions(client);
	}
	
	// Stop recording
	if(g_hRecording[client] != null)
		StopRecording(client);

	//language
	g_bLoaded[client] = false;
}

public OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{	
	if(convar == g_hGoToServer)
	{
		if(newValue[0] == '1')
			g_bGoToServer = true;
		else
			g_bGoToServer = false;
	}		
	else if(convar == g_hChallengePoints)
	{
		if(newValue[0] == '1')
			g_bChallengePoints = true;
		else
			g_bChallengePoints = false;
	}
	else if(convar == g_hNoClipS)
	{
		if(newValue[0] == '1')
			g_bNoClipS = true;
		else
			g_bNoClipS = false;
	}		
	else if(convar == g_hReplayBot)
	{
		if(newValue[0] == '1')
		{
			g_bReplayBot = true;
			LoadReplays();
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))	
				{
					if (i == g_RecordBot)
					{
						StopPlayerMimic(i);
						KickClient(i);
						g_bTrailOn[i] = false;
					}
					else 
					{
						if (!g_bBonusBot) // if both bots are off, no need to record
							if(g_hRecording[i] != null)
								StopRecording(i);
					}				
				}
			if (g_bInfoBot && g_bBonusBot)
				ServerCommand("bot_quota 2");
			else
				if (g_bInfoBot ||g_bBonusBot)
					ServerCommand("bot_quota 1");
				else
					ServerCommand("bot_quota 0");
			g_bReplayBot = false;	
		}
	}
	else if(convar == g_hBonusBot)
	{
		if (newValue[0] == '1')
		{
			g_bBonusBot = true;
			LoadReplays();
		}
		else
		{
			for(int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))
				{
					if (i == g_BonusBot)
					{
						StopPlayerMimic(i);
						KickClient(i);
						g_bTrailOn[i] = false;
					}
					else
					{
						if (!g_bReplayBot) // if both bots are off
							if(g_hRecording[i] != null)
								StopRecording(i);
					}
				}
			if (g_bInfoBot && g_bReplayBot)
				ServerCommand("bot_quota 2");
			else
				if (g_bInfoBot ||g_bReplayBot)
					ServerCommand("bot_quota 1");
				else
					ServerCommand("bot_quota 0");
			g_bBonusBot = false;	
		}
	}
	else if(convar == g_hAdminClantag)
	{
		if(newValue[0] == '1')
		{
			g_bAdminClantag = true;
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))	
					CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);						
		}
		else
		{
			g_bAdminClantag = false;
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))	
					CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);		
		}
	}	
	else if(convar == g_hAutoTimer)
	{
		if(newValue[0] == '1')
			g_bAutoTimer = true;
		else
			g_bAutoTimer = false;
	}
	else if(convar == g_hColoredNames)
	{
		if(newValue[0] == '1')
			g_bColoredNames = true;
		else
			g_bColoredNames = false;
	}
	else if(convar == g_hPauseServerside)
	{
		if(newValue[0] == '1')
			g_bPauseServerside = true;
		else
			g_bPauseServerside = false;
	}
	else if(convar == g_hDynamicTimelimit)
	{
		if(newValue[0] == '1')
			g_bDynamicTimelimit = true;
		else
			g_bDynamicTimelimit = false;
	}	
	else if(convar == g_hAutohealing_Hp)
		g_Autohealing_Hp = StringToInt(newValue[0]);	
	
	else if(convar == g_hAutoRespawn)
	{
		if(newValue[0] == '1')
		{
			ServerCommand("mp_respawn_on_death_ct 1;mp_respawn_on_death_t 1;mp_respawnwavetime_ct 3.0;mp_respawnwavetime_t 3.0");
			g_bAutoRespawn = true;
		}
		else
		{
			ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0");
			g_bAutoRespawn = false;
		}
	}	
	else if(convar == g_hRadioCommands)
	{
		if(newValue[0] == '1')
			g_bRadioCommands = true;
		else
			g_bRadioCommands = false;
	}	
	else if(convar == g_hcvarRestore)
	{
		if(newValue[0] == '1')
			g_bRestore = true;			
		else
			g_bRestore = false;
	}
	else if(convar == g_hMapEnd)
	{
		if(newValue[0] == '1')
			g_bMapEnd = true;			
		else
			g_bMapEnd = false;
	}
	else if(convar == g_hConnectMsg)
	{
		if(newValue[0] == '1')
			g_bConnectMsg = true;			
		else
			g_bConnectMsg = false;
	}
	else if(convar == g_hDisconnectMsg)
	{
		if(newValue[0] == '1')
			g_bDisconnectMsg = true;			
		else
			g_bDisconnectMsg = false;
	}
	else if(convar == g_hPlayerSkinChange)
	{
		if(newValue[0] == '1')
		{
			g_bPlayerSkinChange = true;
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))	
				{					
					if (i == g_RecordBot)
					{
						SetEntPropString(i, Prop_Send, "m_szArmsModel", g_sReplayBotPlayerModel);
						SetEntityModel(i,  g_sReplayBotPlayerModel);
					}
					else
					{
						SetEntPropString(i, Prop_Send, "m_szArmsModel", g_sArmModel);
						SetEntityModel(i,  g_sPlayerModel);
					}
				}
		}
		else
			g_bPlayerSkinChange = false;
	}	
	else if(convar == g_hPointSystem)
	{
		if(newValue[0] == '1')
		{
			g_bPointSystem = true;		
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))				
					CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);					
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))
				{
					Format(g_pr_rankname[i], 32, "");
					CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);
				}
			g_bPointSystem = false;
		}
	}
	else if(convar == g_hcvarNoBlock)
	{
		if(newValue[0] == '1')
		{
			g_bNoBlock = true;
			for(int client = 1; client <= MAXPLAYERS; client++)
				if (IsValidEntity(client))
					SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
					
		}
		else
		{	
			g_bNoBlock = false;
			for(int client = 1; client <= MAXPLAYERS; client++)
				if (IsValidEntity(client))
					SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 5, 4, true);
		}
	}	
	else if(convar == g_hAttackSpamProtection)
	{
		if(newValue[0] == '1')
		{
			g_bAttackSpamProtection = true;
		}
		else
		{	
			g_bAttackSpamProtection = false;
		}
	}		
	else if(convar == g_hCleanWeapons)
	{
		if(newValue[0] == '1')
		{
			decl String:szclass[32];
			g_bCleanWeapons = true;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsPlayerAlive(i))
				{
					for(int j = 0; j < 4; j++)
					{
						int weapon = GetPlayerWeaponSlot(i, j);
						if(weapon != -1 && j != 2)
						{
							GetEdictClassname(weapon, szclass, sizeof(szclass));
							RemovePlayerItem(i, weapon);
							RemoveEdict(weapon);							
							int equipweapon = GetPlayerWeaponSlot(i, 2);
							if (equipweapon != -1)
								EquipPlayerWeapon(i, equipweapon); 
						}
					}
				}
			}
			
		}
		else
			g_bCleanWeapons = false;
	}			
	else if(convar == g_hAutoBhopConVar)
	{
		if(newValue[0] == '1')		
		{		
			g_bAutoBhopConVar = true;		
			g_bAutoBhop = true;
		}
		else
		{
			g_bAutoBhopConVar = false;
			g_bAutoBhop = false;
		}
	}		
	else if(convar == g_hCountry)
	{
		if(newValue[0] == '1')
		{
			g_bCountry = true;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					GetCountry(i);
					if (g_bPointSystem)
						CreateTimer(0.5, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		else
		{
			g_bCountry = false;
			if (g_bPointSystem)
				for (int i = 1; i <= MaxClients; i++)
					if (IsValidClient(i))				
						CreateTimer(0.5, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);		
		}
	}		
	else if(convar == g_hExtraPoints)
		g_ExtraPoints = StringToInt(newValue[0]);	
	else if(convar == g_hExtraPoints2)
		g_ExtraPoints2 = StringToInt(newValue[0]);
		
	
	else if(convar == g_hcvargodmode)
	{
		if(newValue[0] == '1')
			g_bgodmode = true;
		else
			g_bgodmode = false;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{	
				if (g_bgodmode)
					SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
				else
					SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			}
		}
	}	
	else if(convar == g_hInfoBot)
	{
		if(newValue[0] == '1')		
		{
			g_bInfoBot = true;
			LoadInfoBot();
		}
		else
		{
			g_bInfoBot = false;
			for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && IsFakeClient(i))	
			{
				if (i == g_InfoBot)
				{
					int count = 0;
					g_InfoBot = -1;
					KickClient(i);		
					decl String:szBuffer[64];
					if(g_bMapReplay)
						count++;
					if(g_bMapBonusReplay)
						count++;
					Format(szBuffer, sizeof(szBuffer), "bot_quota %i", count); 	
					ServerCommand(szBuffer);							
				}
			}
		}
	}	
	else if(convar == g_hReplayBotPlayerModel)
	{
		Format(g_sReplayBotPlayerModel,256,"%s", newValue[0]);
		PrecacheModel(newValue[0],true);
		AddFileToDownloadsTable(g_sReplayBotPlayerModel);
		if (g_RecordBot != -1)
			SetEntityModel(g_RecordBot,  newValue[0]);	
	}
	else if(convar == g_hReplayBotArmModel)
	{
		Format(g_sReplayBotArmModel,256,"%s", newValue[0]);
		PrecacheModel(newValue[0],true);		
		AddFileToDownloadsTable(g_sReplayBotArmModel);
		if (g_RecordBot != -1)
				SetEntPropString(g_RecordBot, Prop_Send, "m_szArmsModel", newValue[0]);	
	}
	else if(convar == g_hPlayerModel)
	{
		Format(g_sPlayerModel,256,"%s", newValue[0]);
		PrecacheModel(newValue[0],true);	
		AddFileToDownloadsTable(g_sPlayerModel);
		if (!g_bPlayerSkinChange)
			return;
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != g_RecordBot)	
				SetEntityModel(i,  newValue[0]);
	}
	else if(convar == g_hArmModel)
	{
		Format(g_sArmModel,256,"%s", newValue[0]);
		PrecacheModel(newValue[0],true);		
		AddFileToDownloadsTable(g_sArmModel);
		if (!g_bPlayerSkinChange)
			return;
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != g_RecordBot)	
				SetEntPropString(i, Prop_Send, "m_szArmsModel", newValue[0]);
	}	
	else if(convar == g_hWelcomeMsg)
		Format(g_sWelcomeMsg,512,"%s", newValue[0]);

	else if(convar == g_hReplayBotColor)
	{
		decl String:color[256];
		Format(color,256,"%s", newValue[0]);
		GetRGBColor(0,color);
	}
	else if (convar == g_hBonusBotColor)
	{
		decl String:color[256];
		Format(color, 256, "%s", newValue[0]);
		GetRGBColor(1, color);
	}
	else if (convar == g_hReplayBotTrailColor)
	{
		decl String:color[24];
		Format(color, 24, "%s", newValue);
		StringRGBtoInt(color, g_ReplayBotTrailColor);
	}
	else if (convar == g_hBonusBotTrailColor)
	{
		decl String:color[24];
		Format(color, 24, "%s", newValue);
		StringRGBtoInt(color, g_BonusBotTrailColor);
	}
	else if(convar == g_hAllowRoundEndCvar)
	{
		if(newValue[0] == '1')		
		{
			ServerCommand("mp_ignore_round_win_conditions 0");
			g_bAllowRoundEndCvar = true;
		}
		else
		{
			ServerCommand("mp_ignore_round_win_conditions 1;mp_maxrounds 1");
			g_bAllowRoundEndCvar = false;
		}
	}
	else if(convar == g_hChecker)
	{
		g_fChecker = StringToFloat(newValue[0]);
	}
	else if(convar == g_hZoneDisplayType)
	{
		g_zoneDisplayType = StringToInt(newValue[0]);
	}
	else if(convar == g_hZonesToDisplay)
	{
		g_zonesToDisplay = StringToInt(newValue[0]);
	}
	else if(convar == g_hzoneStartColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneStartColor);
	}
	else if(convar == g_hzoneEndColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneEndColor);
	}
	else if(convar == g_hzoneCheckerColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneCheckerColor);
	}
	else if(convar == g_hzoneBonusStartColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneBonusStartColor);
	}
	else if(convar == g_hzoneBonusEndColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneBonusEndColor);
	}
	else if(convar == g_hzoneStageColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneStageColor);
	}
	else if(convar == g_hzoneCheckpointColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneCheckpointColor);
	}
	else if(convar == g_hzoneSpeedColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneSpeedColor);
	}
	else if(convar == g_hzoneTeleToStartColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneTeleToStartColor);
	}
	else if(convar == g_hzoneValidatorColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneValidatorColor);
	}
	else if(convar == g_hzoneStopColor)
	{
		decl String:color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_zoneStopColor);
	}
	else if (convar == g_hStartPreSpeed) {
		g_fStartPreSpeed = StringToFloat(newValue[0]);
	}
	else if (convar == g_hSpeedPreSpeed) {
		g_fSpeedPreSpeed = StringToFloat(newValue[0]);
	}
	else if (convar == g_hBonusPreSpeed){
		g_fBonusPreSpeed = StringToFloat(newValue[0]);
	}
	else if (convar == g_hSpawnToStartZone) {
		if (newValue[0] == '1') {
			bSpawnToStartZone = true;
		} else {
			bSpawnToStartZone = false;
		}
	}
	else if (convar == g_hSoundEnabled) {
		if (newValue[0] == '1') {
			bSoundEnabled = true;
		} else {
			bSoundEnabled = false;
		}
	}
	else if (convar == g_hSoundPath) {
		strcopy(sSoundPath, sizeof(sSoundPath), newValue);
	}
	else if (convar == g_hAnnounceRank) {
		g_AnnounceRank = StringToInt(newValue[0]);
	}
	else if (convar == g_hForceCT) {
		g_bForceCT = bool:StringToInt(newValue[0]);
	}
	else if (convar == g_hChatSpamFilter) {
		g_fChatSpamFilter = StringToFloat(newValue[0]);
	}
	else if (convar == g_henableChatProcessing) {
		g_benableChatProcessing = bool:StringToInt(newValue[0]);
	}
	else if (convar == g_hRecordBotTrail) {
		g_bRecordBotTrailEnabled = bool:StringToInt(newValue[0]);			
	}
	else if (convar == g_hBonusBotTrail) {
		g_bBonusBotTrailEnabled = bool:StringToInt(newValue[0]);
	}
	else if (convar == g_hTriggerPushFixEnable){
		g_bTriggerPushFixEnable = bool:StringToInt(newValue);
	}
	else if (convar ==  g_hSlopeFixEnable) {
		g_bSlopeFixEnable = bool:StringToInt(newValue);
	}
	

	if(g_hZoneTimer != INVALID_HANDLE)
	{
		KillTimer(g_hZoneTimer);
		g_hZoneTimer = INVALID_HANDLE;
	}
	

	g_hZoneTimer = CreateTimer(g_fChecker, BeamBoxAll, _, TIMER_REPEAT);

}

public Native_GetTimerStatus(Handle plugin, numParams)
	return g_bTimeractivated[GetNativeCell(1)];

public Native_StopTimer(Handle plugin, numParams)
	Client_Stop(GetNativeCell(1),0);

public Native_GetCurrentTime(Handle plugin, numParams)
	return _:g_fCurrentRunTime[GetNativeCell(1)];
	
public Native_EmulateStartButtonPress(Handle plugin, numParams)
{
	CL_OnStartTimerPress(GetNativeCell(1));
}
	
public Native_EmulateStopButtonPress(Handle plugin, numParams)
{
	CL_OnEndTimerPress(GetNativeCell(1));
}		

public Plugin:myinfo =
{
	name = "ckSurf",
	author = "Elzi",
	description = "#clan.kikkeli's Surf Plugin",
	version = VERSION,
	url = ""
};

public APLRes:AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("ckSurf");
	CreateNative("ckSurf_GetTimerStatus", Native_GetTimerStatus);
	CreateNative("ckSurf_StopTimer", Native_StopTimer);
	CreateNative("ckSurf_EmulateStartButtonPress", Native_EmulateStartButtonPress);
	CreateNative("ckSurf_EmulateStopButtonPress", Native_EmulateStopButtonPress);
	CreateNative("ckSurf_GetCurrentTime", Native_GetCurrentTime);

	MarkNativeAsOptional("HGR_IsHooking");
	MarkNativeAsOptional("HGR_IsGrabbing");
	MarkNativeAsOptional("HGR_IsBeingGrabbed");
	MarkNativeAsOptional("HGR_IsRoping");
	MarkNativeAsOptional("HGR_IsPushing");
	g_OnLangChanged = CreateGlobalForward("GeoLang_OnLanguageChanged", ET_Ignore, Param_Cell, Param_Cell);
	g_bLateLoaded = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	//Get Server Tickate
	float fltickrate = 1.0 / GetTickInterval( );
	if (fltickrate > 65)
		if (fltickrate < 103)
			g_Server_Tickrate = 102;
		else
			g_Server_Tickrate = 128;
	else
		g_Server_Tickrate= 64;
	
	//language file
	LoadTranslations("ckSurf.phrases");	
	
	// https://forums.alliedmods.net/showthread.php?p=1436866
	// GeoIP Language Selection by GoD-Tony
	Init_GeoLang();
	if (LibraryExists("clientprefs"))
	{
		g_hCookie = RegClientCookie("GeoLanguage", "The client's preferred language.", CookieAccess_Protected);
		SetCookieMenuItem(CookieMenu_GeoLanguage, 0, "Language");
		g_bUseCPrefs = true;
	}
	
	CreateConVar("ckSurf_version", VERSION, "ckSurf Version.", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hConnectMsg = CreateConVar("ck_connect_msg", "1", "on/off - Enables a player connect message with country", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bConnectMsg     = GetConVarBool(g_hConnectMsg);
	HookConVarChange(g_hConnectMsg, OnSettingChanged);

	g_hAllowRoundEndCvar = CreateConVar("ck_round_end", "0", "on/off - Allows to end the current round", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAllowRoundEndCvar     = GetConVarBool(g_hAllowRoundEndCvar);
	HookConVarChange(g_hAllowRoundEndCvar, OnSettingChanged);

	g_hDisconnectMsg = CreateConVar("ck_disconnect_msg", "1", "on/off - Enables a player disconnect message in chat", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bDisconnectMsg = GetConVarBool(g_hDisconnectMsg);
	HookConVarChange(g_hDisconnectMsg, OnSettingChanged);	

	g_hMapEnd = CreateConVar("ck_map_end", "1", "on/off - Allows map changes after the timelimit has run out (mp_timelimit must be greater than 0)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bMapEnd     = GetConVarBool(g_hMapEnd);
	HookConVarChange(g_hMapEnd, OnSettingChanged);
	
	g_hColoredNames = CreateConVar("ck_colored_chatnames", "0", "on/off Colors players names based on their rank in chat.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bColoredNames = GetConVarBool(g_hColoredNames);
	HookConVarChange(g_hColoredNames, OnSettingChanged);

	g_hReplayBot = CreateConVar("ck_replay_bot", "1", "on/off - Bots mimic the local map record", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bReplayBot     = GetConVarBool(g_hReplayBot);
	HookConVarChange(g_hReplayBot, OnSettingChanged);	

	g_hBonusBot = CreateConVar("ck_bonus_bot", "1", "on/off - Bots mimic the local bonus record", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bBonusBot		= GetConVarBool(g_hBonusBot);
	HookConVarChange(g_hBonusBot, OnSettingChanged);

	g_hInfoBot	  = CreateConVar("ck_info_bot", "0", "on/off - provides information about nextmap and timeleft in his player name", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bInfoBot     = GetConVarBool(g_hInfoBot);
	HookConVarChange(g_hInfoBot, OnSettingChanged);		
	
	g_hNoClipS = CreateConVar("ck_noclip", "1", "on/off - Allows players to use noclip when they have finished the map", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bNoClipS     = GetConVarBool(g_hNoClipS);
	HookConVarChange(g_hNoClipS, OnSettingChanged);	

	g_hAdminClantag = 	CreateConVar("ck_admin_clantag", "1", "on/off - Admin clan tag (necessary flag: b - z)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAdminClantag     = GetConVarBool(g_hAdminClantag);
	HookConVarChange(g_hAdminClantag, OnSettingChanged);	
	
	g_hAutoTimer = CreateConVar("ck_auto_timer", "0", "on/off - Timer automatically starts when a player joins a team, dies or uses !start/!r", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAutoTimer     = GetConVarBool(g_hAutoTimer);
	HookConVarChange(g_hAutoTimer, OnSettingChanged);

	g_hGoToServer = CreateConVar("ck_goto", "1", "on/off - Allows players to use the !goto command", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bGoToServer     = GetConVarBool(g_hGoToServer);
	HookConVarChange(g_hGoToServer, OnSettingChanged);	
	
	g_hcvargodmode = CreateConVar("ck_godmode", "1", "on/off - unlimited hp", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bgodmode     = GetConVarBool(g_hcvargodmode);
	HookConVarChange(g_hcvargodmode, OnSettingChanged);

	g_hPauseServerside    = CreateConVar("ck_pause", "1", "on/off - Allows players to use the !pause command", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bPauseServerside    = GetConVarBool(g_hPauseServerside);
	HookConVarChange(g_hPauseServerside, OnSettingChanged);
	
	g_hcvarRestore    = CreateConVar("ck_restore", "1", "on/off - Restoring of time and last position after reconnect", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bRestore        = GetConVarBool(g_hcvarRestore);
	HookConVarChange(g_hcvarRestore, OnSettingChanged);
	
	g_hcvarNoBlock    = CreateConVar("ck_noblock", "1", "on/off - Player no blocking", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bNoBlock        = GetConVarBool(g_hcvarNoBlock);
	HookConVarChange(g_hcvarNoBlock, OnSettingChanged);

	g_hAttackSpamProtection    = CreateConVar("ck_attack_spam_protection", "1", "on/off - max 40 shots; +5 new/extra shots per minute; 1 he/flash counts like 9 shots", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAttackSpamProtection       = GetConVarBool(g_hAttackSpamProtection);
	HookConVarChange(g_hAttackSpamProtection, OnSettingChanged);
	
	g_hAutoRespawn = CreateConVar("ck_autorespawn", "1", "on/off - Auto respawn", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAutoRespawn     = GetConVarBool(g_hAutoRespawn);
	HookConVarChange(g_hAutoRespawn, OnSettingChanged);	

	g_hRadioCommands = CreateConVar("ck_use_radio", "0", "on/off - Allows players to use radio commands", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bRadioCommands     = GetConVarBool(g_hRadioCommands);
	HookConVarChange(g_hRadioCommands, OnSettingChanged);	
	
	g_hAutohealing_Hp 	= CreateConVar("ck_autoheal", "50", "Sets HP amount for autohealing (requires ck_godmode 0)", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_Autohealing_Hp     = GetConVarInt(g_hAutohealing_Hp);
	HookConVarChange(g_hAutohealing_Hp, OnSettingChanged);	
	
	g_hCleanWeapons 	= CreateConVar("ck_clean_weapons", "1", "on/off - Removes all weapons on the ground", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bCleanWeapons     = GetConVarBool(g_hCleanWeapons);
	HookConVarChange(g_hCleanWeapons, OnSettingChanged);
	
	g_hCountry 	= CreateConVar("ck_country_tag", "1", "on/off - Country clan tag", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bCountry     = GetConVarBool(g_hCountry);
	HookConVarChange(g_hCountry, OnSettingChanged);
	
	g_hChallengePoints 	= CreateConVar("ck_challenge_points", "1", "on/off - Allows players to bet points on their challenges", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bChallengePoints     = GetConVarBool(g_hChallengePoints);
	HookConVarChange(g_hChallengePoints, OnSettingChanged);
		
	g_hAutoBhopConVar 	= CreateConVar("ck_auto_bhop", "1", "on/off - AutoBhop on surf_ maps", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bAutoBhopConVar     = GetConVarBool(g_hAutoBhopConVar);
	HookConVarChange(g_hAutoBhopConVar, OnSettingChanged);
	
	g_hDynamicTimelimit 	= CreateConVar("ck_dynamic_timelimit", "0", "on/off - Sets a suitable timelimit by calculating the average run time (This method requires ck_map_end 1, greater than 5 map times and a default timelimit in your server config for maps with less than 5 times", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bDynamicTimelimit     = GetConVarBool(g_hDynamicTimelimit);
	HookConVarChange(g_hDynamicTimelimit, OnSettingChanged);	

	g_hExtraPoints   = CreateConVar("ck_ranking_extra_points_improvements", "15.0", "Gives players x extra points for improving their time.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_ExtraPoints    = GetConVarInt(g_hExtraPoints);
	HookConVarChange(g_hExtraPoints, OnSettingChanged);	

	g_hExtraPoints2   = CreateConVar("ck_ranking_extra_points_firsttime", "50.0", "Gives players x extra points for finishing a map for the first time.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_ExtraPoints2    = GetConVarInt(g_hExtraPoints2);
	HookConVarChange(g_hExtraPoints2, OnSettingChanged);	
	
	g_hPointSystem    = CreateConVar("ck_point_system", "1", "on/off - Player point system", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bPointSystem    = GetConVarBool(g_hPointSystem);
	HookConVarChange(g_hPointSystem, OnSettingChanged);
	
	g_hPlayerSkinChange 	= CreateConVar("ck_custom_models", "1", "on/off - Allows ckSurf to change the models of players and bots", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bPlayerSkinChange     = GetConVarBool(g_hPlayerSkinChange);
	HookConVarChange(g_hPlayerSkinChange, OnSettingChanged);

	g_hReplayBotPlayerModel   = CreateConVar("ck_replay_bot_skin", "models/player/tm_professional_var1.mdl", "Replay pro bot skin", FCVAR_NOTIFY);
	GetConVarString(g_hReplayBotPlayerModel,g_sReplayBotPlayerModel,256);
	HookConVarChange(g_hReplayBotPlayerModel, OnSettingChanged);	
	
	g_hReplayBotArmModel   = CreateConVar("ck_replay_bot_arm_skin", "models/weapons/t_arms_professional.mdl", "Replay pro bot arm skin", FCVAR_NOTIFY);
	GetConVarString(g_hReplayBotArmModel,g_sReplayBotArmModel,256);
	HookConVarChange(g_hReplayBotArmModel, OnSettingChanged);	
	
	g_hPlayerModel   = CreateConVar("ck_player_skin", "models/player/ctm_sas_varianta.mdl", "Player skin", FCVAR_NOTIFY);
	GetConVarString(g_hPlayerModel,g_sPlayerModel,256);
	HookConVarChange(g_hPlayerModel, OnSettingChanged);	
	
	g_hArmModel   = CreateConVar("ck_player_arm_skin", "models/weapons/ct_arms_sas.mdl", "Player arm skin", FCVAR_NOTIFY);
	GetConVarString(g_hArmModel,g_sArmModel,256);
	HookConVarChange(g_hArmModel, OnSettingChanged);

	
	g_hWelcomeMsg   = CreateConVar("ck_welcome_msg", " {yellow}>>{default} {grey}Welcome! This server is using {lime}ckSurf","Welcome message (supported color tags: {default}, {darkred}, {green}, {lightgreen}, {blue} {olive}, {lime}, {red}, {purple}, {grey}, {yellow}, {lightblue}, {steelblue}, {darkblue}, {pink}, {lightred})", FCVAR_NOTIFY);
	GetConVarString(g_hWelcomeMsg,g_sWelcomeMsg,512);
	HookConVarChange(g_hWelcomeMsg, OnSettingChanged);

	g_hReplayBotColor   = CreateConVar("ck_replay_bot_color", "52 91 248","The default replay bot color - Format: \"red green blue\" from 0 - 255.", FCVAR_NOTIFY);
	HookConVarChange(g_hReplayBotColor, OnSettingChanged);	
	decl String:szRBotColor[256];
	GetConVarString(g_hReplayBotColor,szRBotColor,256);
	GetRGBColor(0,szRBotColor);

	g_hBonusBotColor   = CreateConVar("ck_bonus_bot_color", "255 255 20","The bonus replay bot color - Format: \"red green blue\" from 0 - 255.", FCVAR_NOTIFY);
	HookConVarChange(g_hBonusBotColor, OnSettingChanged);	
	szRBotColor = "";
	GetConVarString(g_hBonusBotColor,szRBotColor,256);
	GetRGBColor(1,szRBotColor);

	g_hReplayBotTrailColor   = CreateConVar("ck_replay_bot_trail_color", "52 91 248","The trail color for the replay bot - Format: \"red green blue\" from 0 - 255.", FCVAR_NOTIFY);
	HookConVarChange(g_hReplayBotTrailColor, OnSettingChanged);	
	decl String:szTrailColor[24];
	GetConVarString(g_hReplayBotTrailColor,szTrailColor,24);
	StringRGBtoInt(szTrailColor,g_ReplayBotTrailColor);

	g_hBonusBotTrailColor   = CreateConVar("ck_bonus_bot_trail_color", "255 255 20","The trail color for the bonus bot - Format: \"red green blue\" from 0 - 255.", FCVAR_NOTIFY);
	HookConVarChange(g_hBonusBotTrailColor, OnSettingChanged);	
	szTrailColor = "";
	GetConVarString(g_hBonusBotTrailColor,szTrailColor,24);
	StringRGBtoInt(szTrailColor,g_BonusBotTrailColor);

	g_hChecker = CreateConVar("ck_zone_checker", "5.0", "The duration in seconds when the beams around zones are refreshed.", FCVAR_NOTIFY);
	g_fChecker = GetConVarFloat(g_hChecker);
	HookConVarChange(g_hChecker, OnSettingChanged);

	g_hZoneDisplayType = CreateConVar("ck_zone_drawstyle", "1", "0 = Do not display zones, 1 = display the lower edges of zones, 2 = display whole zones", FCVAR_NOTIFY);
	g_zoneDisplayType = GetConVarInt(g_hZoneDisplayType);
	HookConVarChange(g_hZoneDisplayType, OnSettingChanged);

	g_hZonesToDisplay = CreateConVar("ck_zone_drawzones", "1", "Which zones are visible for players. 1 = draw start & end zones, 2 = draw start, end, stage and bonus zones, 3 = draw all zones.", FCVAR_NOTIFY);
	g_zonesToDisplay = GetConVarInt(g_hZonesToDisplay);
	HookConVarChange(g_hZonesToDisplay, OnSettingChanged);

	g_hzoneStartColor = CreateConVar("ck_zone_startcolor", "000 255 000", "The color of START zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneStartColor, g_szzoneStartColor, 24);
	StringRGBtoInt(g_szzoneStartColor, g_zoneStartColor);
	HookConVarChange(g_hzoneStartColor, OnSettingChanged);

	g_hzoneEndColor = CreateConVar("ck_zone_endcolor", "255 000 000", "The color of END zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneEndColor, g_szzoneEndColor, 24);
	StringRGBtoInt(g_szzoneEndColor, g_zoneEndColor);
	HookConVarChange(g_hzoneEndColor, OnSettingChanged);

	g_hzoneCheckerColor = CreateConVar("ck_zone_checkercolor", "255 255 000", "The color of CHECKER zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneCheckerColor, g_szzoneCheckerColor, 24);
	StringRGBtoInt(g_szzoneCheckerColor, g_zoneCheckerColor);
	HookConVarChange(g_hzoneCheckerColor, OnSettingChanged);

	g_hzoneBonusStartColor = CreateConVar("ck_zone_bonusstartcolor", "000 255 255", "The color of BONUS START zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneBonusStartColor, g_szzoneBonusStartColor, 24);
	StringRGBtoInt(g_szzoneBonusStartColor, g_zoneBonusStartColor);
	HookConVarChange(g_hzoneBonusStartColor, OnSettingChanged);

	g_hzoneBonusEndColor = CreateConVar("ck_zone_bonusendcolor", "255 000 255", "The color of BONUS END zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneBonusEndColor, g_szzoneBonusEndColor, 24);
	StringRGBtoInt(g_szzoneBonusEndColor, g_zoneBonusEndColor);
	HookConVarChange(g_hzoneBonusEndColor, OnSettingChanged);

	g_hzoneStageColor = CreateConVar("ck_zone_stagecolor", "000 000 255", "The color of STAGE zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneStageColor, g_szzoneStageColor, 24);
	StringRGBtoInt(g_szzoneStageColor, g_zoneStageColor);
	HookConVarChange(g_hzoneStageColor, OnSettingChanged);

	g_hzoneCheckpointColor = CreateConVar("ck_zone_checkpointcolor", "000 000 255", "The color of CHECKPOINT zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneCheckpointColor, g_szzoneCheckpointColor, 24);
	StringRGBtoInt(g_szzoneCheckpointColor, g_zoneCheckpointColor);
	HookConVarChange(g_hzoneCheckpointColor, OnSettingChanged);

	g_hzoneSpeedColor = CreateConVar("ck_zone_speedcolor", "255 000 000", "The color of SPEED zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneSpeedColor, g_szzoneSpeedColor, 24);
	StringRGBtoInt(g_szzoneSpeedColor, g_zoneSpeedColor);
	HookConVarChange(g_hzoneSpeedColor, OnSettingChanged);

	g_hzoneTeleToStartColor = CreateConVar("ck_zone_teletostartcolor", "255 255 000", "The color of TELETOSTART zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneTeleToStartColor, g_szzoneTeleToStartColor, 24);
	StringRGBtoInt(g_szzoneTeleToStartColor, g_zoneTeleToStartColor);
	HookConVarChange(g_hzoneTeleToStartColor, OnSettingChanged);

	g_hzoneValidatorColor = CreateConVar("ck_zone_validatorcolor", "255 255 255", "The color of VALIDATOR zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneValidatorColor, g_szzoneValidatorColor, 24);
	StringRGBtoInt(g_szzoneValidatorColor, g_zoneValidatorColor);
	HookConVarChange(g_hzoneValidatorColor, OnSettingChanged);

	g_hzoneStopColor = CreateConVar("ck_zone_stopcolor", "000 000 000", "The color of CHECKER zones \"red green blue\" from 0 - 255", FCVAR_NOTIFY);
	GetConVarString(g_hzoneStopColor, g_szzoneStopColor, 24);
	StringRGBtoInt(g_szzoneStopColor, g_zoneStopColor);
	HookConVarChange(g_hzoneStopColor, OnSettingChanged);

	g_hStartPreSpeed = CreateConVar("ck_pre_start_speed", "320.0", "The maximum prespeed for start zones. 0.0 = No cap", FCVAR_NOTIFY, true, 0.0, true, 3500.0);
	g_fStartPreSpeed = GetConVarFloat(g_hStartPreSpeed);
	HookConVarChange(g_hStartPreSpeed, OnSettingChanged);
	
	g_hSpeedPreSpeed = CreateConVar("ck_pre_speed_speed", "3000.0", "The maximum prespeed for speed start zones. 0.0 = No cap", FCVAR_NOTIFY, true, 0.0, true, 3500.0);
	g_fSpeedPreSpeed = GetConVarFloat(g_hSpeedPreSpeed);
	HookConVarChange(g_hSpeedPreSpeed, OnSettingChanged);

	g_hBonusPreSpeed = CreateConVar("ck_pre_bonus_speed", "320.0", "The maximum prespeed for bonus start zones. 0.0 = No cap", FCVAR_NOTIFY, true, 0.0, true, 3500.0);
	g_fBonusPreSpeed = GetConVarFloat(g_hBonusPreSpeed);
	HookConVarChange(g_hBonusPreSpeed, OnSettingChanged);
	
	g_hSpawnToStartZone = CreateConVar("ck_spawn_to_start_zone", "1.0", "1 = Automatically spawn to the start zone when the client joins the team.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	bSpawnToStartZone = GetConVarBool(g_hSpawnToStartZone);
	HookConVarChange(g_hSpawnToStartZone, OnSettingChanged);	
	
	g_hSoundEnabled = CreateConVar("ck_startzone_sound_enabled", "1.0", "Enable the sound after leaving the start zone.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	bSoundEnabled = GetConVarBool(g_hSoundEnabled);
	HookConVarChange(g_hSoundEnabled, OnSettingChanged);	
	
	g_hSoundPath = CreateConVar("ck_startzone_sound_path", "buttons/button3.wav", "The path to the sound file that plays after the client leaves the start zone..", FCVAR_NOTIFY);
	GetConVarString(g_hSoundPath, sSoundPath, sizeof(sSoundPath));
	HookConVarChange(g_hSoundPath, OnSettingChanged);

	g_hAnnounceRank = CreateConVar("ck_min_rank_announce", "0.0", "Higher ranks than this won't be announced to the everyone on the server. 0 = Announce all records.", FCVAR_NOTIFY, true, 0.0);
	g_AnnounceRank = GetConVarInt(g_hAnnounceRank);
	HookConVarChange(g_hAnnounceRank, OnSettingChanged);

	g_hForceCT = CreateConVar("ck_force_players_ct", "0.0", "Forces all players to join the CT team.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bForceCT = GetConVarBool(g_hForceCT);
	HookConVarChange(g_hForceCT, OnSettingChanged);

	g_hChatSpamFilter = CreateConVar("ck_chat_spamprotection_time", "1.0", "The frequency in seconds that players are allowed to send chat messages. 0.0 = No chat cap.", FCVAR_NOTIFY, true, 0.0);
	g_fChatSpamFilter = GetConVarFloat(g_hChatSpamFilter);
	HookConVarChange(g_hChatSpamFilter, OnSettingChanged);

	g_henableChatProcessing = CreateConVar("ck_chat_enable", "1", "(1 / 0) Enable or disable ckSurfs chat processing.", FCVAR_NOTIFY);
	g_benableChatProcessing = GetConVarBool(g_henableChatProcessing);
	HookConVarChange(g_henableChatProcessing, OnSettingChanged);


	g_hBonusBotTrail = CreateConVar("ck_bonus_bot_trail", "1", "(1 / 0) Enables a trail on the bonus bot.", FCVAR_NOTIFY);
	g_bBonusBotTrailEnabled = GetConVarBool(g_hBonusBotTrail);
	HookConVarChange(g_hBonusBotTrail, OnSettingChanged);

	g_hRecordBotTrail = CreateConVar("ck_record_bot_trail", "1", "(1 / 0) Enables a trail on the record bot.", FCVAR_NOTIFY);
	g_bRecordBotTrailEnabled = GetConVarBool(g_hRecordBotTrail);
	HookConVarChange(g_hRecordBotTrail, OnSettingChanged);
	
	g_hTriggerPushFixEnable = CreateConVar("ck_triggerpushfix_enable", "1", "Enables trigger push fix.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bTriggerPushFixEnable = GetConVarBool(g_hTriggerPushFixEnable);
	HookConVarChange(g_hTriggerPushFixEnable, OnSettingChanged);
	
	g_hSlopeFixEnable = CreateConVar("ck_slopefix_enable", "1", "Enables slope fix.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bSlopeFixEnable = GetConVarBool(g_hSlopeFixEnable);
	HookConVarChange(g_hSlopeFixEnable, OnSettingChanged);

	db_setupDatabase();
	
	//client commands
	RegConsoleCmd("sm_usp", Client_Usp, "[ckSurf] spawns a usp silencer");
	RegConsoleCmd("sm_avg", Client_Avg, "[ckSurf] prints in chat the average time of the current map");
	RegConsoleCmd("sm_accept", Client_Accept, "[ckSurf] allows you to accept a challenge request");
	RegConsoleCmd("sm_hidechat", Client_HideChat, "[ckSurf] hides your ingame chat");
	RegConsoleCmd("sm_hideweapon", Client_HideWeapon, "[ckSurf] hides your weapon model");
	RegConsoleCmd("sm_disarm", Client_HideWeapon, "[ckSurf] hides your weapon model");
	RegConsoleCmd("sm_goto", Client_GoTo, "[ckSurf] teleports you to a selected player");
	RegConsoleCmd("sm_language", Client_Language, "[ckSurf] select your language");
	RegConsoleCmd("sm_sound", Client_QuakeSounds,"[ckSurf] on/off quake sounds");
	RegConsoleCmd("sm_surrender", Client_Surrender, "[ckSurf] surrender your current challenge");
	RegConsoleCmd("sm_bhop", Client_AutoBhop,"[ckSurf] on/off autobhop");
	RegConsoleCmd("sm_help2", Client_RankingSystem,"[ckSurf] Explanation of the ckSurf ranking system");
	RegConsoleCmd("sm_flashlight", Client_Flashlight,"[ckSurf] on/off flashlight");
	RegConsoleCmd("sm_maptop", Client_MapTop,"[ckSurf] displays local map top for a given map");
	RegConsoleCmd("sm_hidespecs", Client_HideSpecs, "[ckSurf] hides spectators from menu/panel");
	RegConsoleCmd("sm_compare", Client_Compare, "[ckSurf] compare your challenge results");
	RegConsoleCmd("sm_wr", Client_Wr, "[ckSurf] prints records in chat");
	RegConsoleCmd("sm_measure",Command_Menu, "[ckSurf] allows you to measure the distance between 2 points");
	RegConsoleCmd("sm_abort", Client_Abort, "[ckSurf] abort your current challenge");
	RegConsoleCmd("sm_spec", Client_Spec, "[ckSurf] chooses a player who you want to spectate and switch you to spectators");
	RegConsoleCmd("sm_watch", Client_Spec, "[ckSurf] chooses a player who you want to spectate and switch you to spectators");
	RegConsoleCmd("sm_spectate", Client_Spec, "[ckSurf] chooses a player who you want to spectate and switch you to spectators");
	RegConsoleCmd("sm_challenge", Client_Challenge, "[ckSurf] allows you to start a race against others");
	RegConsoleCmd("sm_helpmenu", Client_Help, "[ckSurf] help menu which displays all ckSurf commands");
	RegConsoleCmd("sm_help", Client_Help, "[ckSurf] help menu which displays all ckSurf commands");
	RegConsoleCmd("sm_profile", Client_Profile, "[ckSurf] opens a player profile");
	RegConsoleCmd("sm_rank", Client_Profile, "[ckSurf] opens a player profile");
	RegConsoleCmd("sm_options", Client_OptionMenu, "[ckSurf] opens options menu");
	RegConsoleCmd("sm_top", Client_Top, "[ckSurf] displays top rankings (Top 100 Players, Top 50 overall)");
	RegConsoleCmd("sm_topSurfers", Client_Top, "[ckSurf] displays top rankings (Top 100 Players, Top 50 overall)");
	RegConsoleCmd("sm_bonustop", Client_BonusTop, "[ckSurf] displays top rankings of the bonus");
	RegConsoleCmd("sm_btop", Client_BonusTop, "[ckSurf] displays top rankings of the bonus");
	RegConsoleCmd("sm_stop", Client_Stop, "[ckSurf] stops your timer");
	RegConsoleCmd("sm_ranks", Client_Ranks, "[ckSurf] prints in chat the available player ranks");
	RegConsoleCmd("sm_pause", Client_Pause,"[ckSurf] on/off pause (timer on hold and movement frozen)");
	RegConsoleCmd("sm_showsettings", Client_Showsettings,"[ckSurf] shows ckSurf server settings");
	RegConsoleCmd("sm_latest", Client_Latest,"[ckSurf] shows latest map records");
	RegConsoleCmd("sm_showtime", Client_Showtime,"[ckSurf] on/off - timer text in panel/menu");	
	RegConsoleCmd("sm_hide", Client_Hide, "[ckSurf] on/off - hides other players");
	RegConsoleCmd("sm_togglecheckpoints", ToggleCheckpoints, "[ckSurf] on/off - Enable player checkpoints");
	RegConsoleCmd("+noclip", NoClip, "[ckSurf] Player noclip on");
	RegConsoleCmd("-noclip", UnNoClip, "[ckSurf] Player noclip off");

	// Teleportation commands
	RegConsoleCmd("sm_stages", Command_SelectStage, "[ckSurf] Opens up the stage selector");
	RegConsoleCmd("sm_r", Command_Restart, "[ckSurf] Teleports player back to the start");
	RegConsoleCmd("sm_restart", Command_Restart, "[ckSurf] Teleports player back to the start");
	RegConsoleCmd("sm_start", Command_Restart, "[ckSurf] Teleports player back to the start");
	RegConsoleCmd("sm_b", Command_ToBonus, "[ckSurf] Teleports player back to the start");
	RegConsoleCmd("sm_bonus", Command_ToBonus, "[ckSurf] Teleports player back to the start");
	RegConsoleCmd("sm_bonuses", Command_ListBonuses, "[ckSurf] Displays a list of bonuses in current map");
	RegConsoleCmd("sm_s", Command_ToStage, "[ckSurf] Teleports player to the selected stage");
	RegConsoleCmd("sm_stage", Command_ToStage, "[ckSurf] Teleports player to the selected stage");
	RegConsoleCmd("sm_end", Command_ToEnd, "[ckSurf] Teleports player to the end zone");
	
	// Titles
	RegConsoleCmd("sm_title", Command_SetTitle, "[ckSurf] Displays player's titles");
	RegConsoleCmd("sm_titles", Command_SetTitle, "[ckSurf] Displays player's titles");
	RegConsoleCmd("sm_vip", Command_Vip, "[ckSurf] VIP's commands and effects.");
	RegConsoleCmd("sm_effects", Command_Vip, "[ckSurf] VIP's commands and effects.");
	RegConsoleCmd("sm_effect", Command_Vip, "[ckSurf] VIP's commands and effects.");

	// MISC
	RegConsoleCmd("sm_tier", Command_Tier, "[ckSurf] Prints information on the current map");
	RegConsoleCmd("sm_maptier", Command_Tier, "[ckSurf] Prints information on the current map");
	RegConsoleCmd("sm_mapinfo", Command_Tier, "[ckSurf] Prints information on the current map");
	RegConsoleCmd("sm_mi", Command_Tier, "[ckSurf] Prints information on the current map");
	RegConsoleCmd("sm_m", Command_Tier, "[ckSurf] Prints information on the current map");
	RegConsoleCmd("sm_difficulty", Command_Tier, "[ckSurf] Prints information on the current map");
	RegConsoleCmd("sm_btier", Command_bTier, "[ckSurf] Prints tier information on current map's bonuses");
	RegConsoleCmd("sm_bonusinfo", Command_bTier, "[ckSurf] Prints tier information on current map's bonuses");
	RegConsoleCmd("sm_bi", Command_bTier, "[ckSurf] Prints tier information on current map's bonuses");
	RegConsoleCmd("sm_howto", Command_HowTo, "[ckSurf] Displays a youtube video on how to surf");

	// Teleport to the start of the stage
	RegConsoleCmd("sm_stuck", Command_Teleport, "[ckSurf] Teleports player back to the start of the stage");
	RegConsoleCmd("sm_back", Command_Teleport, "[ckSurf] Teleports player back to the start of the stage");
	RegConsoleCmd("sm_rs", Command_Teleport, "[ckSurf] Teleports player back to the start of the stage");
	RegConsoleCmd("sm_play", Command_Teleport, "[ckSurf] Teleports player back to the start");
	RegConsoleCmd("sm_spawn", Command_Teleport, "[ckSurf] Teleports player back to the start");

	// Player Checkpoints
	RegConsoleCmd("sm_teleport", Command_goToPlayerCheckpoint, "[ckSurf] Teleports player to his last checkpoint");
	RegConsoleCmd("sm_tele", Command_goToPlayerCheckpoint, "[ckSurf] Teleports player to his last checkpoint");
	RegConsoleCmd("sm_prac", Command_goToPlayerCheckpoint, "[ckSurf] Teleports player to his last checkpoint");
	RegConsoleCmd("sm_practice", Command_goToPlayerCheckpoint, "[ckSurf] Teleports player to his last checkpoint");

	RegConsoleCmd("sm_cp", Command_createPlayerCheckpoint, "[ckSurf] Creates a checkpoint, where the player can teleport back to");
	RegConsoleCmd("sm_checkpoint", Command_createPlayerCheckpoint, "[ckSurf] Creates a eckpoint, where the player can teleport back to");
	RegConsoleCmd("sm_undo", Command_undoPlayerCheckpoint, "[ckSurf] Undoes the players lchast checkpoint.");
	RegConsoleCmd("sm_normal", Command_normalMode, "[ckSurf] Switches player back to normal mode.")
	RegConsoleCmd("sm_n", Command_normalMode, "[ckSurf] Switches player back to normal mode.")

	RegAdminCmd("sm_ckadmin", Admin_ckPanel, ADMFLAG_UNBAN, "[ckSurf] Displays the ckSurf menu panel");
	RegAdminCmd("sm_refreshprofile", Admin_RefreshProfile, ADMFLAG_UNBAN, "[ckSurf] Recalculates player profile for given steam id");
	RegAdminCmd("sm_resetchallenges", Admin_DropChallenges, ADMFLAG_ROOT, "[ckSurf] Resets all player challenges (drops table challenges) - requires z flag");
	RegAdminCmd("sm_resettimes", Admin_DropAllMapRecords, ADMFLAG_ROOT, "[ckSurf] Resets all player times (drops table playertimes) - requires z flag");
	RegAdminCmd("sm_resetranks", Admin_DropPlayerRanks, ADMFLAG_ROOT, "[ckSurf] Resets the all player points  (drops table playerrank - requires z flag)");
	RegAdminCmd("sm_resetmaptimes", Admin_ResetMapRecords, ADMFLAG_ROOT, "[ckSurf] Resets player times for given map - requires z flag");
	RegAdminCmd("sm_resetplayerchallenges", Admin_ResetChallenges, ADMFLAG_ROOT, "[ckSurf] Resets (won) challenges for given steamid - requires z flag");
	RegAdminCmd("sm_resetplayertimes", Admin_ResetRecords, ADMFLAG_ROOT, "[ckSurf] Resets pro map times (+extrapoints) for given steamid with or without given map - requires z flag");
	RegAdminCmd("sm_resetplayermaptime", Admin_ResetMapRecord, ADMFLAG_ROOT, "[ckSurf] Resets pro map time for given steamid and map - requires z flag");
	RegAdminCmd("sm_deleteproreplay", Admin_DeleteMapReplay, ADMFLAG_ROOT, "[ckSurf] Deletes pro replay for a given map - requires z flag");
	RegAdminCmd("sm_resetextrapoints", Admin_ResetExtraPoints, ADMFLAG_ROOT, "[ckSurf] Resets given extra points for all players with or without given steamid");	
	RegAdminCmd("sm_deletecheckpoints", Admin_DeleteCheckpoints, ADMFLAG_ROOT, "[ckSurf] Reset checkpoints on the current map");
	RegAdminCmd("sm_insertmaptiers", Admin_InsertMapTiers, ADMFLAG_ROOT, "[ckSurf] Insert premade maptier information into the database (ONLY RUN THIS ONCE)");
	RegAdminCmd("sm_insertmapzones", Admin_InsertMapZones, ADMFLAG_ROOT, "[ckSurf] Insert premade map zones into the database (ONLY RUN THIS ONCE)");
	RegAdminCmd("sm_zones", Command_Zones, ADMFLAG_ROOT, "[ckSurf] Opens up the zone creation menu.");
	RegAdminCmd("sm_admintitles", Admin_giveTitle, ADMFLAG_ROOT, "[ckSurf] Gives a player a title");
	RegAdminCmd("sm_admintitle", Admin_giveTitle, ADMFLAG_ROOT, "[ckSurf] Gives a player a title");
	RegAdminCmd("sm_givetitle", Admin_giveTitle, ADMFLAG_ROOT, "[ckSurf] Gives a player a title");
	RegAdminCmd("sm_removetitles", Admin_deleteTitles, ADMFLAG_ROOT, "[ckSurf] Removes player's all titles");
	RegAdminCmd("sm_removetitle", Admin_deleteTitle, ADMFLAG_ROOT, "[ckSurf] Removes specific title from a player");

	RegAdminCmd("sm_addmaptier", Admin_insertMapTier, ADMFLAG_UNBAN, "[ckSurf] Changes maps tier");
	RegAdminCmd("sm_amt", Admin_insertMapTier, ADMFLAG_UNBAN, "[ckSurf] Changes maps tier");
	RegAdminCmd("sm_addspawn", Admin_insertSpawnLocation, ADMFLAG_UNBAN, "[ckSurf] Changes the position !r takes players to");
	RegAdminCmd("sm_delspawn", Admin_deleteSpawnLocation, ADMFLAG_UNBAN, "[ckSurf] Removes custom !r position");
	RegAdminCmd("sm_clearassists", Admin_ClearAssists, ADMFLAG_UNBAN, "[ckSurf] Clears assist points (map progress) from all players");


	//chat command listener
	AddCommandListener(Say_Hook, "say");
	AddCommandListener(Say_Hook, "say_team");

	//exec ckSurf.cfg
	AutoExecConfig(true, "ckSurf");
	
	//mic
	g_ownerOffset = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");
	g_ragdolls = FindSendPropInfo("CCSPlayer","m_hRagdoll");
		
	//Credits: Measure by DaFox
	//https://forums.alliedmods.net/showthread.php?t=88830
	g_hMainMenu = CreateMenu(Handler_MainMenu);
	SetMenuTitle(g_hMainMenu,"ckSurf - Measure");
	AddMenuItem(g_hMainMenu,"","Point 1 (Red)");
	AddMenuItem(g_hMainMenu,"","Point 2 (Green)");
	AddMenuItem(g_hMainMenu,"","Find Distance");
	AddMenuItem(g_hMainMenu,"","Reset");
	
	//add to admin menu
	Handle tpMenu;
	if (LibraryExists("adminmenu") && ((tpMenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(tpMenu);

	//hooks
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_start", Event_OnRoundStart,EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_hurt", Event_OnPlayerHurt);
	HookEvent("player_jump", Event_OnJump, EventHookMode_Pre);
	HookEvent("weapon_fire",  Event_OnFire, EventHookMode_Pre);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Post);
	HookEvent("jointeam_failed", Event_JoinTeamFailed, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre); 

	//mapcycle array
	int arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
	g_MapList = CreateArray(arraySize);	
		
	//add command listeners	
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_ext_Menu, "radio1");
	AddCommandListener(Command_ext_Menu, "radio2");
	AddCommandListener(Command_ext_Menu, "radio3");
	AddCommandListener(Command_ext_Menu, "sm_nominate");
	AddCommandListener(Command_ext_Menu, "sm_admin");
	AddCommandListener(Command_ext_Menu, "sm_votekick");
	AddCommandListener(Command_ext_Menu, "sm_voteban");
	AddCommandListener(Command_ext_Menu, "sm_votemenu");
	AddCommandListener(Command_ext_Menu, "sm_revote");

	//hook radio commands
	for(int g; g < sizeof(RadioCMDS); g++)
		AddCommandListener(BlockRadio, RadioCMDS[g]);

	//button sound hook
	//AddNormalSoundHook(NormalSHook_callback);

	//nav files
	CreateNavFiles();
	
	// Botmimic 2
	// https://forums.alliedmods.net/showthread.php?t=180114
	// Optionally setup a hook on CBaseEntity::Teleport to keep track of sudden place changes
	CheatFlag("bot_zombie", false, true);
	CheatFlag("bot_mimic", false, true);
	g_hLoadedRecordsAdditionalTeleport = CreateTrie();
	Handle hGameData = LoadGameConfigFile("sdktools.games");
	if(hGameData == null) 
	{
		SetFailState("GameConfigFile sdkhooks.games was not found.");
		return;
	}
	int iOffset = GameConfGetOffset(hGameData, "Teleport");
	CloseHandle(hGameData);
	if(iOffset == -1)
		return;
	
	if(LibraryExists("dhooks"))
	{
		g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
		if(g_hTeleport == null)
			return;
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_Bool);
	}

	// Forwards
	g_MapFinishForward = CreateGlobalForward("ckSurf_OnMapFinished", ET_Event, Param_Cell, Param_Float, Param_String, Param_Cell, Param_Cell);
	g_BonusFinishForward = CreateGlobalForward("ckSurf_OnBonusFinished", ET_Event, Param_Cell, Param_Float, Param_String, Param_Cell, Param_Cell, Param_Cell);
	g_PracticeFinishForward = CreateGlobalForward("ckSurf_OnPracticeFinished", ET_Event, Param_Cell, Param_Float, Param_String);
	
	if(g_bLateLoaded) 
	{ 
		CreateTimer(3.0, LoadPlayerSettings, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}

	Format(szWHITE, 12, "%c", WHITE);
	Format(szDARKRED, 12, "%c", DARKRED);
	Format(szPURPLE, 12, "%c", PURPLE);
	Format(szGREEN, 12, "%c", GREEN);
	Format(szMOSSGREEN, 12, "%c", MOSSGREEN);
	Format(szLIMEGREEN, 12, "%c", LIMEGREEN);
	Format(szRED, 12, "%c", RED);
	Format(szGRAY, 12, "%c", GRAY);
	Format(szYELLOW, 12, "%c", YELLOW);
	Format(szDARKGREY, 12, "%c", DARKGREY);
	Format(szBLUE, 12, "%c", BLUE);
	Format(szDARKBLUE, 12, "%c", DARKBLUE);
	Format(szLIGHTBLUE, 12, "%c", LIGHTBLUE);
	Format(szPINK, 12, "%c", PINK);
	Format(szLIGHTRED, 12, "%c", LIGHTRED);
}