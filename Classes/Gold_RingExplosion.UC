class Gold_RingExplosion extends UT_RingExplosion5;

simulated function SpawnExtraEffects()
{
	 Spawn(class'EnergyImpact');
	 bExtraEffectsSpawned = true;
}

defaultproperties
{
	MultiSkins(0)=Texture'UltimateNewnetv0_6_DataBase.TeamShock.Goldr'
    bExtraEffectsSpawned=False
}