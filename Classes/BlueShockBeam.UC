class BlueShockBeam extends ShockBeam;

simulated function Timer()
{
	local BlueShockBeam r;
	
	if (NumPuffs>0)
	{
		r = Spawn(class'BlueShockbeam',,,Location+MoveAmount);
		r.RemoteRole = ROLE_None;
		r.NumPuffs = NumPuffs -1;
		r.MoveAmount = MoveAmount;
	}
}

defaultproperties
{
     Texture=Texture'BlueS'
}