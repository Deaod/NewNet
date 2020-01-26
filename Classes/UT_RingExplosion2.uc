class UT_RingExplosion2 extends UT_RingExplosion;

simulated function SpawnExtraEffects()
{
	local actor a;

	bExtraEffectsSpawned = true;
	a = Spawn(class'EnergyImpact');
	a.RemoteRole = ROLE_None;

	Spawn(class'EnergyImpact');

	if ( Level.bHighDetailMode && !Level.bDropDetail )
	{
		a = Spawn(class'UT_RingExplosion1');
		a.RemoteRole = ROLE_None;
	}
}

defaultproperties
{
     bExtraEffectsSpawned=False
}
