class Red_RingExplosion extends UT_RingExplosion5;

simulated function SpawnExtraEffects()
{
	 Spawn(class'EnergyImpact');
	 bExtraEffectsSpawned = true;
}

defaultproperties
{
	MultiSkins(0)=Texture'UltimateNewnetv0_6_DataBase.TeamShock.Redr'
    bExtraEffectsSpawned=False
    LightBrightness=255
   	LightHue=21
    LightSaturation=64
    LightRadius=6
    LightEffect=LE_Cylinder
}