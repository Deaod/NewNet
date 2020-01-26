class UT_GoldRingExplosion2 extends UT_RingExplosion2;

simulated function SpawnEffects()
{
	 Spawn(class'GoldShockExplo');
}

simulated function SpawnExtraEffects()
{
	local actor a;

	bExtraEffectsSpawned = true;
	a = Spawn(class'EnergyImpact');
	a.RemoteRole = ROLE_None;

	Spawn(class'EnergyImpact');

	if ( Level.bHighDetailMode && !Level.bDropDetail )
	{
		a = Spawn(class'UT_GoldRingExplosion3');
		a.RemoteRole = ROLE_None;
	}
}

defaultproperties
{
    Skin=Texture'Goldr'
    MultiSkins(0)=Texture'Goldr'
	MultiSkins(1)=Texture'Goldr'
    bExtraEffectsSpawned=False
}
