class UT_RedRingExplosion3 extends UT_RedRingExplosion2;

simulated function SpawnExtraEffects()
{
	bExtraEffectsSpawned = true;
}

simulated function SpawnEffects()
{
}

defaultproperties
{
     bExtraEffectsSpawned=True
}