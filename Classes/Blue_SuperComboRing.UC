class Blue_SuperComboRing extends UT_ComboRing;

simulated function SpawnEffects()
{
	local actor a;

	/*if ( Level.bHighDetailMode && !Level.bDropDetail )
	{
		a = Spawn(class'Blue_RingExplosion',self);
		a.RemoteRole = ROLE_None;
	}*/

	Spawn(class'BigEnergyImpact',,,,rot(16384,0,0));

	a = Spawn(class'shockexplo');
	a.RemoteRole = ROLE_None;

	a =	Spawn(class'Blue_SuperShockrifleWave');	
	a.RemoteRole = ROLE_None;
}
	
defaultproperties
{
	MultiSkins(0)=Texture'UltimateNewnetv0_6_Database.TeamShock.Bluer'
	MultiSkins(1)=Texture'UltimateNewnetv0_6_Database.TeamShock.Bluer'
    DrawScale=12.000000
}