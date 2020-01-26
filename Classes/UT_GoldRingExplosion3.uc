class UT_GoldRingExplosion3 extends UT_GoldRingExplosion2;

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