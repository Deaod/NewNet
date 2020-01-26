class Red_SuperComboRing extends UT_ComboRing;

simulated function SpawnEffects()
{
	local actor a;

	/*if ( Level.bHighDetailMode && !Level.bDropDetail )
	{
		a = Spawn(class'Red_RingExplosion',self);
		a.RemoteRole = ROLE_None;
	}*/

	Spawn(class'BigEnergyImpact',,,,rot(16384,0,0));

	a = Spawn(class'RedShockExplo');
	a.RemoteRole = ROLE_None;

	a =	Spawn(class'Red_SuperShockrifleWave');	
	a.RemoteRole = ROLE_None;
}
	
defaultproperties
{
	MultiSkins(0)=Texture'Redr'
	MultiSkins(1)=Texture'Redr'
    DrawScale=12.000000
}