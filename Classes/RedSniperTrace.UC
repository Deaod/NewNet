class RedSniperTrace extends Effects;

var vector MoveAmount;
var int NumPuffs;

replication
{
	reliable if( Role==ROLE_Authority )
		MoveAmount, NumPuffs;
}

simulated function PostBeginPlay()
{
	if ( Level.NetMode != NM_DedicatedServer )
	{
		SetTimer(0.01, false);
		//PlayAnim('getbig', 1/Default.LifeSpan, 0);
	}
}

simulated function Tick( float DeltaTime )
{
	if ( Level.NetMode != NM_DedicatedServer )
		ScaleGlow = 2 * (Lifespan/Default.Lifespan);
}

simulated function Timer()
{
	local RedSniperTrace r;
	local int i;
	local float scaler, lastscaler;
	local vector CurLoc;

	MoveAmount /= 10000;

	CurLoc = Location;
	lastscaler = 1.0;
	
	for (i = 1; i <= NumPuffs; i++)
	{
		scaler = 1.0 - (float(i)/(float(NumPuffs)*3.0));
		CurLoc = CurLoc + (MoveAmount * ((180 * DrawScale) * lastscaler));
		r = Spawn(class'RedSniperTrace',,, CurLoc);
		r.RemoteRole = ROLE_None;
		r.DrawScale = scaler * DrawScale;
		lastscaler = scaler;
	}
}

defaultproperties
{
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=0.500000
     DrawType=DT_Mesh
     DrawScale=1.00
     Style=STY_Translucent
     LODBias=200.00
     Mesh=LodMesh'UltimateNewnetv0_6_Database.railtrail'
     MultiSkins(0)=Texture'UltimateNewnetv0_6_Database.TeamShock2.RedSw'
     MultiSkins(1)=Texture'UltimateNewnetv0_6_Database.TeamShock2.RedSw'
     bUnlit=True
}