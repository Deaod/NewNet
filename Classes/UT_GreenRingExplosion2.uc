class UT_GreenRingExplosion2 extends UT_RingExplosion2;

simulated function SpawnEffects()
{
	 Spawn(class'GreenShockExplo');
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
		a = Spawn(class'UT_GreenRingExplosion3');
		a.RemoteRole = ROLE_None;
	}
}

defaultproperties
{
    Skin=Texture'Greenr'
    MultiSkins(0)=Texture'Greenr'
	MultiSkins(1)=Texture'Greenr'
    bExtraEffectsSpawned=False
}
