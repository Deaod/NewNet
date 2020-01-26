class UT_BlueRingExplosion2 extends UT_RingExplosion2;

simulated function SpawnEffects()
{
	 Spawn(class'BlueShockExplo');
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
		a = Spawn(class'UT_BlueRingExplosion3');
		a.RemoteRole = ROLE_None;
	}
}

defaultproperties
{
    Skin=Texture'Bluer'
    MultiSkins(0)=Texture'Bluer'
	MultiSkins(1)=Texture'Bluer'
    bExtraEffectsSpawned=False
}
