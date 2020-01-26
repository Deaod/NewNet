class GreenShockBeam extends ShockBeam;

simulated function Timer()
{
	local GreenShockBeam r;
	
	if (NumPuffs>0)
	{
		r = Spawn(class'GreenShockbeam',,,Location+MoveAmount);
		r.RemoteRole = ROLE_None;
		r.NumPuffs = NumPuffs -1;
		r.MoveAmount = MoveAmount;
	}
}

defaultproperties
{
     Texture=Texture'GreenS'
}