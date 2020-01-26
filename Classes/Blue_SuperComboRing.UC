class Blue_SuperComboRing extends UT_ComboRing;

simulated function SpawnEffects()
{
	local actor a;

	if ( Level.bHighDetailMode && !Level.bDropDetail )
	{
		a = Spawn(class'Blue_RingExplosion',self);
		a.RemoteRole = ROLE_None;
	}

	Spawn(class'BigEnergyImpact',,,,rot(16384,0,0));

	a = Spawn(class'BlueShockExplo');
	a.RemoteRole = ROLE_None;

	a =	Spawn(class'Blue_SuperShockrifleWave');	
	a.RemoteRole = ROLE_None;
}
	
defaultproperties
{
	Skin=Texture'Bluer'
	MultiSkins(0)=Texture'Bluer'
	MultiSkins(1)=Texture'Bluer'
	DrawScale=12.000000
}