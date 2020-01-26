class Green_RingExplosion extends UT_RingExplosion5;

simulated function SpawnExtraEffects()
{
	 Spawn(class'EnergyImpact');
	 bExtraEffectsSpawned = true;
}

defaultproperties
{
	MultiSkins(0)=Texture'UltimateNewnetv0_6_Database.TeamShock.Greenr'
    bExtraEffectsSpawned=False
}