class Gold_SuperComboRing extends UT_ComboRing;

simulated function SpawnEffects()
{
	local actor a;

	/*if ( Level.bHighDetailMode && !Level.bDropDetail )
	{
		a = Spawn(class'Gold_RingExplosion',self);
		a.RemoteRole = ROLE_None;
	}*/

	Spawn(class'BigEnergyImpact',,,,rot(16384,0,0));

	a = Spawn(class'shockexplo');
	a.RemoteRole = ROLE_None;

	a =	Spawn(class'Gold_SuperShockrifleWave');	
	a.RemoteRole = ROLE_None;
}
	
defaultproperties
{
	MultiSkins(0)=Texture'UltimateNewnetv0_6_Database.TeamShock.Goldr'
	MultiSkins(1)=Texture'UltimateNewnetv0_6_Database.TeamShock.Goldr'
    DrawScale=12.000000
}