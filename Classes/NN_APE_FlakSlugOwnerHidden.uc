class NN_APE_FlakSlugOwnerHidden extends ST_APE_FlakSlug;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime)
{
	if ( Owner == None )
		return;
	
	if (!bAlreadyHidden)
	{	
		if (Level.NetMode == NM_Client && bNetOwner)
		{
			SpawnSound = None;
			ImpactSound = None;
			Mesh = None;
			ExplosionDecal = None;
			AmbientSound = None;
			AmbientGlow = 0;
			LightType = LT_None;
			SetCollisionSize(0, 0);
			Destroy();
		}
		else if ( !Region.Zone.bWaterZone && (Level.NetMode != NM_DedicatedServer) )
			Trail = Spawn(class'ChunkTrail',self);
			
		bAlreadyHidden = True;
	}
}

simulated function PostBeginPlay()
{
	Velocity = Vector(Rotation) * Speed;     
	initialDir = Velocity;
	Velocity.z += 200; 
	initialDir = Velocity;
	if ( Level.bHighDetailMode  && !Level.bDropDetail ) 
		SetTimer(0.04,True);
	else 
		SetTimer(0.25,True);
}

function ProcessTouch (Actor Other, vector HitLocation)
{
	if (bDeleteMe || Other == None || Other.bDeleteMe)
		return;
	if ( Other != instigator/*  && Other.Owner != Owner  */) 
		NewExplode(HitLocation,Normal(HitLocation-Other.Location), Other.IsA('Pawn'));
}

function NewExplode(vector HitLocation, vector HitNormal, bool bDirect)
{
	local vector start;
	local bbPlayer bbP;
	local int ProjIndex;
	local rotator aRot;
	local NN_FlakSlugOwnerHidden Proj1;
	local NN_APE_FlakSlugOwnerHidden Proj2;
	
	bbP = bbPlayer(Owner);

	if (bbP == None || !bbP.bNewNet)
		HurtRadius(damage, 170, 'FlakDeath', MomentumTransfer, HitLocation);
	start = Location + 12 * HitNormal;
	Spawn( class'NN_ut_FlameExplosionOwnerHidden',Owner,,Start);
	aRot = rotator( vector(rotation)*2 + hitnormal);

	if ( bLast )
	{
		Spawn( class 'NN_FlakSlugOwnerHidden',Owner, '', Start, aRot);
		Destroy();
	}
	else if ( FRand() > 0.05 )
	{
		Spawn( class 'NN_APE_FlakSlugOwnerHidden',Owner, '', Start, aRot).bLast = True;
		Destroy();
	}
 	Destroy();
}

function Explode(vector HitLocation, vector HitNormal)
{
	if (bDeleteMe)
		return;
	NewExplode(HitLocation, HitNormal, False);
}

simulated function Landed( vector HitNormal )
{
	local DirectionalBlast D;

	if ( Level.NetMode != NM_DedicatedServer && !bNetOwner )
	{
		D = Spawn(class'NN_DirectionalBlastOwnerHidden',Owner);
		if ( D != None )
			D.DirectionalAttach(initialDir, HitNormal);
	}
	Explode(Location,HitNormal);
}

simulated function HitWall (vector HitNormal, actor Wall)
{
	local DirectionalBlast D;

	if ( Level.NetMode != NM_DedicatedServer && !bNetOwner )
	{
		D = Spawn(class'NN_DirectionalBlastOwnerHidden',Owner);
		if ( D != None )
			D.DirectionalAttach(initialDir, HitNormal);
	}
	
	if ( Role == ROLE_Authority )
	{
		if ( (Mover(Wall) != None) && Mover(Wall).bDamageTriggered )
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), '');

		MakeNoise(1.0);
	}
	Explode(Location + ExploWallOut * HitNormal, HitNormal);
	if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer) && !bNetOwner )
		Spawn(ExplosionDecal,self,,Location, rotator(HitNormal));
}

simulated function Timer()
{
	local ut_SpriteSmokePuff s;

	initialDir = Velocity;
	if (Level.NetMode!=NM_DedicatedServer && !bNetOwner) 
	{
		s = Spawn(class'NN_UT_SpriteSmokePuffOwnerHidden');
		s.RemoteRole = ROLE_None;
	}	
	if ( Level.bDropDetail )
		SetTimer(0.25,True);
	else if ( Level.bHighDetailMode )
		SetTimer(0.04,True);
}

defaultproperties
{
     bOwnerNoSee=True
}