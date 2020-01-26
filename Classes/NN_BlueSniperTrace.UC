class NN_BlueSniperTrace extends BlueSniperTrace;

simulated function Timer()
{
	local BlueSniperTrace r;
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
		r = Spawn(class,,, CurLoc);
		r.RemoteRole = ROLE_None;
		r.DrawScale = scaler * DrawScale;
		lastscaler = scaler;
	}
}

simulated function PostBeginPlay()
{
	if ( Level.NetMode != NM_DedicatedServer )
		SetTimer(0.01, false);
}

defaultproperties
{
}