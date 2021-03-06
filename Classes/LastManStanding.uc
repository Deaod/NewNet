class LastManStanding extends DeathMatchPlus;

var config bool bHighDetailGhosts;
var() int Lives;
var int TotalKills, NumGhosts;
var localized string AltStartupMessage;
var PlayerPawn LocalPlayer;
//Custom variables of the new gametype
var config bool bDynamicBots;
var config int NumberDynamicBots;
var config string StartWeapon;
var PlayerReplicationInfo Ordered[32];
var int PlayerCount; //count number of players humans + bots if DynamicBots are disabled.
var int WorstPlayerNumberLives; //the worst player number of lives (min = 0)
var int BestPlayerNumberLives; //the best player number of lives (min = 0)
var bool bGameAlreadyStarted;


event InitGame( string Options, out string Error )
{
    local string InOpt;
	
	if(bDynamicBots)
		MinPlayers=0; //if we are the first to enter		
    Super.InitGame(Options, Error);

    if ( FragLimit == 0 || FragLimit == 1 ){
		log("LMS doesn't support"@FragLimit@"live only, starting the game with 10 lives...");
		FragLimit=10;
	}

	Lives = Fraglimit;
		
	WorstPlayerNumberLives=Lives; // This should fix the random spectator bug, at the begin of a new game
	BestPlayerNumberLives=Lives;
}

function float GameThreatAdd(Bot aBot, Pawn Other)
{
    if ( !Other.bIsPlayer ) 
        return 0;
    else
        return 0.1 * Other.PlayerReplicationInfo.Score;
}

event playerpawn Login
(
    string Portal,
    string Options,
    out string Error,
    class<playerpawn> SpawnClass
)
{
    local playerpawn NewPlayer;

    // Players can't join if there is/was a player (this include bots, if bDynamicBots=False) with less than 2 lives.
    if (NumPlayers!=0 && WorstPlayerNumberLives < 2)
    {
        bDisallowOverride = true;
        SpawnClass = class'CHSpectator';
        if ( (NumSpectators >= MaxSpectators)
            && ((Level.NetMode != NM_ListenServer) || (NumPlayers > 0)) )
        {
            MaxSpectators++;
        }
    }
    NewPlayer = Super.Login(Portal, Options, Error, SpawnClass);

	if ((NewPlayer != None) && !NewPlayer.IsA('Spectator') && !NewPlayer.IsA('Commander')){
	
		if(WorstPlayerNumberLives!=BestPlayerNumberLives || WorstPlayerNumberLives==Lives)
			NewPlayer.PlayerReplicationInfo.Score = WorstPlayerNumberLives;
		else
			NewPlayer.PlayerReplicationInfo.Score = WorstPlayerNumberLives-1; //If the worst player have the same lives of the best, let's think
																			//two playing with 7 lives, the the entering will start with -1, 6 lives
	}
	
	return NewPlayer;
}

event PostLogin( playerpawn NewPlayer )
{
	if (NewPlayer==None) return;
	
	if(bDynamicBots && NewPlayer.PlayerReplicationInfo.Deaths == 0){
		//log("Player entered");
		if (TournamentPlayer(NewPlayer)!=None){
			ShouldWeAddBots(); //Can be the first player (if so we add the dynamic bots)
		}
	}
	
    if( NewPlayer.Player != None && Viewport(NewPlayer.Player) != None)
        LocalPlayer = NewPlayer;

    if ( (TotalKills > 0.15 * (NumPlayers + NumBots) * Lives) && NewPlayer.IsA('CHSpectator') )
        GameName = AltStartupMessage;   
    Super.PostLogin(NewPlayer);
    GameName = Default.GameName;
	
	if(NumPlayers!=0 && WorstPlayerNumberLives < 2) //if player can't enter in the current game, let's say him to wait until next match
		NewPlayer.SetProgressMessage("The current match is locked, please wait until this match finishes to join.", 0);
}

function Timer()
{
    local Pawn P;
	
	//
	if (NumPlayers>1 && WorstPlayerNumberLives>1 || !bDynamicBots && NumBots>0 && WorstPlayerNumberLives>1){ //Don't do unnecessary checks.
		LoadScores();
		
		//If(Ordered[0]!=None) //should not be necessary with the player check number
			if (Ordered[0].Score<WorstPlayerNumberLives || Ordered[PlayerCount-1].Score<BestPlayerNumberLives){ 
			// this is in case of a player left the game and re-enter don't start with worst player
			//lives (since he probably was 0 lives when left)
			
				WorstPlayerNumberLives=Ordered[0].Score; //Let's update the worst live of the current game
				BestPlayerNumberLives=Ordered[PlayerCount-1].Score; //Let's update the best live of the current game
		
			}
	}
	//

    Super.Timer();
    For ( P=Level.PawnList; P!=None; P=P.NextPawn ){
        if ( P.IsInState('FeigningDeath') )
            P.GibbedBy(P);
	}
	
}
 
function bool NeedPlayers()
{
    if ( bGameEnded || (TotalKills > 0.15 * (NumPlayers + NumBots) * Lives) )
        return false;
    return (NumPlayers + NumBots < MinPlayers);
}

function bool IsRelevant(actor Other) 
{
    local Mutator M;
    local bool bArenaMutator;

    for (M = BaseMutator; M != None; M = M.NextMutator)
    {
        if (M.IsA('Arena'))
            bArenaMutator = True;
    }

    if ( bArenaMutator )
    {
        if ( Other.IsA('Inventory') && (Inventory(Other).MyMarker != None) && !Other.IsA('UT_Jumpboots') && !Other.IsA('Ammo'))
        {
            Inventory(Other).MyMarker.markedItem = None;
            return false;
        }
    } else {
        if ( Other.IsA('Inventory') && (Inventory(Other).MyMarker != None) && !Other.IsA('UT_Jumpboots'))
        {
            Inventory(Other).MyMarker.markedItem = None;
            return false;
        }
    }

    return Super.IsRelevant(Other);
}

function bool RestartPlayer( pawn aPlayer ) 
{
    local NavigationPoint startSpot;
    local bool foundStart;
    local Pawn P;
    local bool bResult;

    if( bRestartLevel && Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer )
        return true;

	if ( aPlayer.PlayerReplicationInfo.Score < 1 )
	{
		BroadcastLocalizedMessage(class'LMSOutMessage', 0, aPlayer.PlayerReplicationInfo);
		aPlayer.bHidden = true;
		if(aPlayer.IsA('bbPlayer'))
		{
			aPlayer.PlayerRestartState = 'PlayerSpectating';
			aPlayer.GotoState('PlayerSpectating');
		}
		else if(aPlayer.IsA('TournamentPlayer'))
		{
			aPlayer.PlayerRestartState = 'PlayerSpectating';
			aPlayer.GotoState('PlayerSpectating');
		}
		For ( P=Level.PawnList; P!=None; P=P.NextPawn )
			if ( P.bIsPlayer && (P.PlayerReplicationInfo.Score >= 1) )
				P.PlayerReplicationInfo.Score += 0.00001;
		if ( aPlayer.IsA('Bot') )
		{
			aPlayer.PlayerReplicationInfo.bIsSpectator = true;
			aPlayer.PlayerReplicationInfo.bWaitingPlayer = true;
			aPlayer.GotoState('GameEnded');
			return false; // bots don't respawn when ghosts
		}
	}
	else if(aPlayer.PlayerReplicationInfo.Score > 0)
	{
		bResult = Super.RestartPlayer(aPlayer);
		if ( (aPlayer.IsA('TournamentPlayer')) || (aPlayer.IsA('bbPlayer')) )
			TournamentPlayer(aPlayer).StartSpot = LastStartSpot;
	}
    return bResult;
}

function Logout( pawn Exiting )
{

    Super.Logout(Exiting);

    // Don't run endgame if it's the local player leaving
    // - stats saveconfig messes up saved defaults
    if( LocalPlayer == None || Exiting != LocalPlayer )
        CheckEndGame();
	
}

function Killed( pawn killer, pawn Other, name damageType )
{
    local int OldFragLimit;
	
    OldFragLimit = FragLimit;
    FragLimit = 0;

    if ( Other.bIsPlayer )
        TotalKills++;
            
    Super.Killed(Killer, Other, damageType);    

    FragLimit = OldFragLimit;

    CheckEndGame();
}

function CheckEndGame()
{
    local Pawn PawnLink;
    local int StillPlaying;
    local bool bStillHuman;
    local bot B, D;

    if ( bGameEnded )
        return;

    // Check to see if everyone is a ghost.
    NumGhosts = 0;
    for ( PawnLink=Level.PawnList; PawnLink!=None; PawnLink=PawnLink.nextPawn )
        if ( PawnLink.bIsPlayer )
        {
            if ( PawnLink.PlayerReplicationInfo.Score < 1 )
                NumGhosts++;
            else
            {
                if ( PawnLink.IsA('PlayerPawn') )
                    bStillHuman = true;
                StillPlaying++;
            }
        }

    // End the game if there is only one man standing.
    if ( StillPlaying < 2 )
        EndGame("lastmanstanding");
    else if ( !bStillHuman )
    {
        // no humans left - get bots to be more aggressive and finish up
        for ( PawnLink=Level.PawnList; PawnLink!=None; PawnLink=PawnLink.NextPawn )
        {
            B = Bot(PawnLink);
            if ( B != None )
            {
                B.CampingRate = 0;
                B.Aggressiveness += 5.0;
                if ( D == None )
                    D = B;
                else if ( B.Enemy == None )
                    B.SetEnemy(D);
            }
        }
    }       
}

function ScoreKill(pawn Killer, pawn Other)
{
    Other.DieCount++;
    if (Other.PlayerReplicationInfo.Score > 0)
        Other.PlayerReplicationInfo.Score -= 1;
    if( (killer != Other) && (killer != None) )
        killer.killCount++;
    BaseMutator.ScoreKill(Killer, Other);
}   

function bool PickupQuery( Pawn Other, Inventory item )
{
    if ( Other.PlayerReplicationInfo.Score < 1 )
        return false;
    
    return Super.PickupQuery( Other, item );
}

/*
AssessBotAttitude returns a value that translates to an attitude
        0 = ATTITUDE_Fear;
        1 = return ATTITUDE_Hate;
        2 = return ATTITUDE_Ignore;
        3 = return ATTITUDE_Friendly;
*/  
function byte AssessBotAttitude(Bot aBot, Pawn Other)
{
    local float Adjust;

    if ( aBot.bNovice )
        Adjust = -0.2;
    else
        Adjust = -0.2 - 0.1 * aBot.Skill;
    if ( Other.bIsPlayer && (Other.PlayerReplicationInfo.Score < 1) )
        return 2; //bots ignore ghosts
    else if ( aBot.bKamikaze )
        return 1;
    else if ( Other.IsA('TeamCannon')
        || (aBot.RelativeStrength(Other) > aBot.Aggressiveness - Adjust) )
        return 0;
    else
        return 1;
}

function AddDefaultInventory( pawn PlayerPawn )
{
    local Weapon weap;
    local int i;
    local inventory Inv;
    local float F;
	local string PreFix;
	
	// Weapons strings
	local String s_ShockRifle;
	local String s_BioRifle;
	local String s_Ripper;
	local String s_FlakCannon;
	local String s_SniperRifle;
	local String s_PulseGun;
	local String s_Minigun2;
	local String s_Eightball;
	
	PreFix = "UN"$class'UTPure'.default.ThisVer$".";
	
	// Set botpack weapons strings
	s_ShockRifle    = "Botpack.ShockRifle";
	s_BioRifle      = "Botpack.UT_BioRifle";
	s_Ripper        = "Botpack.Ripper";
	s_FlakCannon    = "Botpack.UT_FlakCannon";
	s_SniperRifle   = "Botpack.SniperRifle";
	s_PulseGun      = "Botpack.PulseGun";
	s_Minigun2      = "Botpack.Minigun2";
	s_Eightball     = "Botpack.UT_Eightball";
	
	// Fix newnet nw weapons
	s_ShockRifle    = PreFix$"ST_ShockRifle";
	s_BioRifle      = PreFix$"ST_UT_BioRifle";
	s_Ripper        = PreFix$"ST_Ripper";
	s_FlakCannon    = PreFix$"ST_UT_FlakCannon";
	s_SniperRifle   = PreFix$"ST_SniperRifle";
	s_PulseGun      = PreFix$"ST_PulseGun";
	s_Minigun2      = PreFix$"ST_Minigun2";
	s_Eightball     = PreFix$"ST_UT_Eightball";

    if ( PlayerPawn.IsA('Spectator') || (bRequireReady && (CountDown > 0)) )
        return;
    Super.AddDefaultInventory(PlayerPawn);

	GiveWeapon(PlayerPawn, s_ShockRifle);
	GiveWeapon(PlayerPawn, s_BioRifle);
    GiveWeapon(PlayerPawn, s_Ripper);
    GiveWeapon(PlayerPawn, s_FlakCannon);

    if ( PlayerPawn.IsA('PlayerPawn') )
    {
		GiveWeapon(PlayerPawn, s_SniperRifle);
        GiveWeapon(PlayerPawn, s_PulseGun);
        GiveWeapon(PlayerPawn, s_Minigun2);
        GiveWeapon(PlayerPawn, s_Eightball);
		PlayerPawn.SwitchToBestWeapon();
    }
    else
    {
        // randomize order for bots so they don't always use the same weapon
        F = FRand();
        if ( F < 0.7 ) 
        {
		
			GiveWeapon(PlayerPawn, s_SniperRifle);
            GiveWeapon(PlayerPawn, s_PulseGun);
            if ( F < 0.4 )
            {
                GiveWeapon(PlayerPawn, s_Minigun2);
                GiveWeapon(PlayerPawn, s_Eightball);
            }
            else
            {
                GiveWeapon(PlayerPawn, s_Eightball);
                GiveWeapon(PlayerPawn, s_Minigun2);
            }
        }
        else
        {
            GiveWeapon(PlayerPawn, s_Minigun2);
            GiveWeapon(PlayerPawn, s_Eightball);
            if ( F < 0.88 )
            {
				GiveWeapon(PlayerPawn, s_SniperRifle);
                GiveWeapon(PlayerPawn, s_PulseGun);
            }
            else
            {
                GiveWeapon(PlayerPawn, s_PulseGun);
				GiveWeapon(PlayerPawn, s_SniperRifle);
            }
        }
    }
                
    for ( inv=PlayerPawn.inventory; inv!=None; inv=inv.inventory )
    {
        weap = Weapon(inv);
        if ( (weap != None) && (weap.AmmoType != None) ){
            weap.AmmoType.AmmoAmount = weap.AmmoType.MaxAmmo;
			
		//we put it inside of this if, so we are sure that the current weapon is != None
		if ( String(weap.Class)==StartWeapon &&  TournamentPlayer(PlayerPawn)!=None){ //There's a specified weapon to start with?	
			PlayerPawn(PlayerPawn).GetWeapon(weap.Class);
		}
		
		}
    }

    inv = Spawn(class'Armor2');
    if( inv != None )
    {
        inv.bHeldItem = true;
        inv.RespawnTime = 0.0;
        inv.GiveTo(PlayerPawn);
    }
}   

function ModifyBehaviour(Bot NewBot)
{
    // Set the Bot's Lives
    NewBot.PlayerReplicationInfo.Score = Lives;

    NewBot.CampingRate += FRand();
}

function bool OneOnOne()
{
    return ( NumPlayers + NumBots - NumGhosts == 2 );
}

/*
//
//
//
// Or Custom fuctions start here!
//
//
//
*/

/*
	Fuction that allow kill all bots in the game
*/
function killBots(){

	local Pawn temp;
	
	for (temp = Level.PawnList; temp != None; temp = temp.NextPawn) //Delete all bots
		if(temp.isA('Bot'))
			temp.destroy();
}

function ShouldWeAddBots()
{
	local Pawn temp;
	local Weapon aux;
	
		if(NumPlayers == 1 && NumBots != 0){ //Clean time of bots (we don't want big times in scoreboard like 56246 minutes)
			RemainingTime=TimeLimit*60; //Restore Time Left because bot could be camping alone for a while / just to see a '1' time standing
			ElapsedTime=0; //Lets restore too also elapsedtime :)
			for (temp = Level.PawnList; temp != None; temp = temp.NextPawn)
				temp.PlayerReplicationInfo.StartTime = 0; //pawn set bots and player time to 0
		}
		else if(NumPlayers == 1 && NumBots == 0 && !bGameEnded){ //we don't want to add bots if the game was already finished
			//MinPlayers=0; //To the engine don't add more bots auto
			//killBots(); // this is to fix a weird potencial number of bots bug
			MinPlayers=NumberDynamicBots+1; //To the game dont end, when some players left, resting only one player
			AddBots(NumberDynamicBots); //Add the number of bots defined
			MinPlayers=NumberDynamicBots+1; //Because when we add a bot it will increment the min players, this is to restore the default value
		}
		else if(NumPlayers==2 && !bGameEnded && NumBots !=0 ){ //possible problem? Code executed if for example were playing 8 players and 6 leave? 
		//edit\ This isn't possible since this functions is only called when a new player enter, also when there's 1 player the game or ends or the code is executed correctly
		
			MinPlayers=0; //To the engine don't add more bots auto
			killBots(); //Delete all bots
			
			if(bGameAlreadyStarted){ //we only need to run this code if the game was already started because it may be redundant/unnecessary
				//let's clean all weapons dropped before
				foreach Level.AllActors(Class'Weapon',aux){
					if(!aux.bHeldItem) 
						aux.bHideWeapon=true; //seems if we don't hide it first before destroying, it stills gets visible for some seconds.
						aux.Destroy();
				}
				
				//let's play a different sound so the player that was playing with bots get warned about the new human player.
				for (temp = Level.PawnList; temp != None; temp = temp.NextPawn)
					if(temp.isA('TournamentPlayer')) 
						TournamentPlayer(temp).ClientPlaySound(Sound'UnrealShare.Generic.Beep');
				
				RestorePlayerStuff();
			}
		}
		
}

function RestorePlayerStuff()
{
local Pawn NetPlayer;
local Inventory aux;
local KillCountLMSPRI MPRI;
local ReplicationInfo SDM;

		//log("RemainingTime="$RemainingTime@"TimeLimit="$TimeLimit@"startTimeLevel="$Level.Game.StartTime);
		RemainingTime=TimeLimit*60; //Restore Time Left ,*60 is because the time limit is in minutes, while remainingTime is in seconds, so we must convert the mintutes to seconds. :)
		ElapsedTime=0; 

		for (NetPlayer = Level.PawnList; NetPlayer != None; NetPlayer = NetPlayer.NextPawn){ //Restore Player Lives
			if(NetPlayer.isA('TournamentPlayer')){
		
				aux=NetPlayer.FindInventoryType(class'Armor2');
				if (aux!=None) aux.Destroy(); //If we don't destroy the current armor it will add the charge with the new
				
					AddDefaultInventory(NetPlayer);
					NetPlayer.Health = 100;
					NetPlayer.KillCount = 0;
					NetPlayer.PlayerReplicationInfo.Score = Lives;
					NetPlayer.PlayerReplicationInfo.Deaths = 0;
					NetPlayer.Spree = 0;
					//NetPlayer.PlayerReplicationInfo.StartTime = 0; //restore also player time in game
					TournamentPlayer(NetPlayer).GameReplicationInfo.RemainingTime=RemainingTime;
					
					foreach NetPlayer.PlayerReplicationInfo.ChildActors(Class'KillCountLMSPRI',MPRI)
						MPRI.KillCounter=0; //restore kills
					
			}
		}
		
		//Compatibility layer with SmartDM - Reset SmartDM stats if them exist
		foreach Level.Game.AllActors(Class'ReplicationInfo',SDM){
					
			if(SDM.isA('SmartDMPlayerReplicationInfo')){
				SDM.PostBeginPlay();
			}
							
		}
}

function AddBots(int N){ //Thanks Feralidragon!
    local int i;

    for ( i=0; i<N; i++ )
        Level.Game.ForceAddBot();
		
}

function LoadScores() {
    local int i;
	local Pawn Player;
	
    // Wipe everything.
    for ( i=0; i<ArrayCount(Ordered); i++ )
        Ordered[i] = None;
		
		PlayerCount=0;
   
	for (Player = Level.PawnList; Player != None; Player = Player.NextPawn){ //Create a list with the players
		if(Player.isA('TournamentPlayer') || Player.isA('Bot') && !bDynamicBots){ //if dynamic bots are disable we also count with them lives...
			Ordered[PlayerCount]=Player.PlayerReplicationInfo;
			PlayerCount++;
			if ( PlayerCount == ArrayCount(Ordered) ) break;
		}
	}
	
    SortScores(PlayerCount);
}

function SortScores(int N) {
    local int I, J, Min;
    local PlayerReplicationInfo TempPRI;
    
    for ( I=0; I<N-1; I++ )
    {
        Min = I;
        for ( J=I+1; J<N; J++ )
        {
            if ( Ordered[J].Score < Ordered[Min].Score )
                Min = J;
        }
        TempPRI = Ordered[Min];
        Ordered[Min] = Ordered[I];
        Ordered[I] = TempPRI;
    }
}

function InitGameReplicationInfo()
{
    Super.InitGameReplicationInfo();
	Spawn(class'SpawnKillCount'); //This class will add the KillCount feature to the players
}

function StartMatch()
{
	Super.StartMatch();
	bGameAlreadyStarted=true;
}

defaultproperties
{
	//bDynamicBots=true
	//NumberDynamicBots=5
	FragLimit=30
	TimeLimit=0
	InitialBots=0
	bAlwaysForceRespawn=True
	StartUpMessage="Last Man Standing. How long can you live?"
	ScoreBoardType=Class'lmsppScoreBoard'
	RulesMenuType="UTMenu.UTLMSRulesSC"
	BeaconName="LMS"
	GameName="Last Man Standing"
}