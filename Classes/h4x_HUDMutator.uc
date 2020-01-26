class h4x_HUDMutator expands Mutator;

var PlayerPawn HUDOwner;

simulated event PostRender( canvas Canvas )
{
	if (HUDOwner != None && HUDOwner.Weapon != None)
	{
		HUDOwner.Weapon.PostRender(Canvas);
	}
}

defaultproperties
{
}
