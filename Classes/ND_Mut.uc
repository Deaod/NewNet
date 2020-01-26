/************************************************************
 * ND_Mut
 ************************************************************/
class ND_Mut expands Mutator config(UltimateNewNet);

var NDgencli Check[128];
var PlayerReplicationInfo yyPRI;
var config int MessageTimer;
var config bool bNotifyKeyBind;

struct PlayerInfo
{
	var string PRI_Name;
	var int PRI_ID;
	var PlayerPawn PRI_PP;
};
var PlayerInfo PI[128];

function PostBeginPlay()
{
	SaveConfig();
	log("");
	log(" :==========================================>>");
	log(" : Grapple Key Bind Notify has Initialized!");
	log(" :");
	log(" :            ***  SETTINGS  ***");
	log(" :            MessageTimer = "$MessageTimer);
	log(" :            bNotifyKeyBind = "$bNotifyKeyBind);
	log(" :==========================================>>");
	log("");
}
simulated function tick(float DeltaTime)
{
	local PlayerPawn PP;
	local int PID;
	local Pawn P;
	local NDgencli xxCheck;

    //Stand in line
	super.tick(DeltaTime);

	P = Level.PawnList;

JL0005:
	if((P != None) && (P.IsA('PlayerPawn')) && (!P.PlayerReplicationInfo.bIsABot))
	{
		PP = PlayerPawn(P);
		PID = PP.PlayerReplicationInfo.PlayerID % 128;

		if((PI[PID].PRI_Name != PP.PlayerReplicationInfo.PlayerName)
			&& (PP.PlayerReplicationInfo.PlayerName != "Player"))
		{
			//Bind--ID
			PI[PID].PRI_ID = PP.PlayerReplicationInfo.PlayerID;
			//Bind--Name
			PI[PID].PRI_Name = PP.PlayerReplicationInfo.PlayerName;
			//Bind--PlayerPawn
			PI[PID].PRI_PP = PP;
			//Spawn class
			xxCheck = spawn(class'NDgencli',PP,,PP.Location);
			//Bind class
			Check[PID] = xxCheck;
			//Bind variables
			xxCheck.MessageTimer = MessageTimer;
			xxCheck.bNotifyKeyBind = bNotifyKeyBind;
		}
		P = P.nextPawn;
		goto JL0005;
	}
}

simulated function Mutate(string MutateString, PlayerPawn Sender)
{
	local string KeyName;
	local int PID;

    //Stand in line
	super.Mutate(MutateString, Sender);
	//Player replication Info
	yyPRI = Sender.PlayerReplicationInfo;
	//Player ID
	PID = yyPRI.PlayerID % 128;
	//Name of Key to bind
	KeyName = Mid(MutateString,8);

	if(left(MutateString,8) ~= "OFFHAND ")
	{
        //Validate Sender
		if(PI[PID].PRI_PP == Sender)
			Check[PID].SetKeyBind(PID,KeyName);
	}
}

defaultproperties
{
     MessageTimer=30
     bNotifyKeyBind=True
}
