class UT_BlueRingExplosion3 extends UT_BlueRingExplosion2;

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