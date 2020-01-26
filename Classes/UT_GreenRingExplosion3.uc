class UT_GreenRingExplosion3 extends UT_GreenRingExplosion2;

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