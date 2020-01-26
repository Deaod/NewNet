class Red_ComboRing extends UT_RingExplosion;

simulated function PostBeginPlay()
{
	if ( Level.NetMode != NM_DedicatedServer )
	{
		PlayAnim( 'Explo', 0.1, 0.0 );
		SpawnEffects();
	}	
	if ( Instigator != None )
		MakeNoise(0.5);
}

simulated function SpawnEffects()
{
	local actor a;

	if ( Level.bHighDetailMode && !Level.bDropDetail )
	{
		a = Spawn(class'Red_RingExplosion',self);
		a.RemoteRole = ROLE_None;
	}

	Spawn(class'BigEnergyImpact',,,,rot(16384,0,0));

	a = Spawn(class'RedShockExplo');
	a.RemoteRole = ROLE_None;

	a =	Spawn(class'Red_shockrifleWave');	
	a.RemoteRole = ROLE_None;
}

defaultproperties
{
    LifeSpan=0.900000
    Skin=Texture'Redr'
    MultiSkins(0)=Texture'Redr'
	MultiSkins(1)=Texture'Redr'
    DrawScale=4.000000
}