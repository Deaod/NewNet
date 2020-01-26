class KillCountLMSPRI expands ReplicationInfo;

var int KillCounter;
//var int RealRemainingTime;

replication{
	reliable if ( Role == ROLE_Authority )
	KillCounter /*, RealRemainingTime*/;
}

function PostBeginPlay(){
	Timer();
	SetTimer(2.0, true);
}

function Timer(){
	if (Owner == None){
		Destroy();
		return;
	}
	KillCounter =  Pawn(Owner.Owner).KillCount;
}
