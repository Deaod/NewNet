class Blue_RingExplosion extends Effects;

var bool bExtraEffectsSpawned;

simulated function Tick( float DeltaTime )
{
	if ( Level.NetMode != NM_DedicatedServer )
	{
		if ( !bExtraEffectsSpawned )
			SpawnExtraEffects();
		ScaleGlow = (Lifespan/Default.Lifespan)*0.7;
		AmbientGlow = ScaleGlow * 255;		
	}
}

simulated function PostBeginPlay()
{
	if ( Level.NetMode != NM_DedicatedServer )
	{
		PlayAnim( 'Explo', 0.35, 0.0 );
		SpawnEffects();
	}	
	if ( Instigator != None )
		MakeNoise(0.5);
}

simulated function SpawnEffects()
{
	 Spawn(class'shockexplo');
}

simulated function SpawnExtraEffects()
{
	bExtraEffectsSpawned = true;
}

defaultproperties
{
     bExtraEffectsSpawned=True
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=0.800000
     AnimSequence=Explo
     MultiSkins(0)=Texture'UltimateNewnetv0_6_DataBase.TeamShock.Bluer'
     DrawType=DT_Mesh
     Style=STY_None
     Mesh=LodMesh'Botpack.UTRingex'
     DrawScale=0.700000
     ScaleGlow=1.100000
     AmbientGlow=255
     bUnlit=True
}