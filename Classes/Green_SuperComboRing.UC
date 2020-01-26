class Green_SuperComboRing extends UT_ComboRing;

simulated function SpawnEffects()
{
	local actor a;

	/*if ( Level.bHighDetailMode && !Level.bDropDetail )
	{
		a = Spawn(class'Green_RingExplosion',self);
		a.RemoteRole = ROLE_None;
	}*/

	Spawn(class'BigEnergyImpact',,,,rot(16384,0,0));

	a = Spawn(class'GreenShockExplo');
	a.RemoteRole = ROLE_None;

	a =	Spawn(class'Green_SuperShockrifleWave');	
	a.RemoteRole = ROLE_None;
}
	
defaultproperties
{
	MultiSkins(0)=Texture'Greenr'
	MultiSkins(1)=Texture'Greenr'
    DrawScale=12.000000
}