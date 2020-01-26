class RedShockBeam extends ShockBeam;

simulated function Timer()
{
	local RedShockBeam r;
	
	if (NumPuffs>0)
	{
		r = Spawn(class'RedShockbeam',,,Location+MoveAmount);
		r.RemoteRole = ROLE_None;
		r.NumPuffs = NumPuffs -1;
		r.MoveAmount = MoveAmount;
	}
}

defaultproperties
{
     Texture=Texture'RedS'
}