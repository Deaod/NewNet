class UT_RedRingExplosion2 extends UT_RingExplosion2;

simulated function SpawnEffects()
{
	 Spawn(class'RedShockExplo');
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
		a = Spawn(class'UT_RedRingExplosion3');
		a.RemoteRole = ROLE_None;
	}
}

defaultproperties
{
    Skin=Texture'Redr'
    MultiSkins(0)=Texture'Redr'
	MultiSkins(1)=Texture'Redr'
    bExtraEffectsSpawned=False
}
