class GoldShockBeam extends ShockBeam;

simulated function Timer()
{
	local GoldShockBeam r;
	
	if (NumPuffs>0)
	{
		r = Spawn(class'GoldShockbeam',,,Location+MoveAmount);
		r.RemoteRole = ROLE_None;
		r.NumPuffs = NumPuffs -1;
		r.MoveAmount = MoveAmount;
	}
}

defaultproperties
{
     Texture=Texture'GoldS'
}