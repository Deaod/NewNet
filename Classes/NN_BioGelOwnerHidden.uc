class NN_BioGelOwnerHidden extends ST_BioGel;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime) {
	
	if ( Owner == None )
		return;
	
	if (Level.NetMode == NM_Client && !bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None)
	{
		LightType = LT_None;
		Mesh = None;
		SetCollisionSize(0, 0);
		bAlreadyHidden = True;
	}
}

function Timer()
{
	DoPuff(PlayerPawn(Owner));
	PlayOwnedSound (MiscSound,,3.0*DrawScale);	
	if ( (Mover(Base) != None) && Mover(Base).bDamageTriggered )
		Base.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
	
	if (bbPlayer(Owner) != None && !bbPlayer(Owner).bNewNet)
		HurtRadius(damage * Drawscale, DrawScale * 120, MyDamageType, MomentumTransfer * Drawscale, Location);
	else
		HurtRadius(damage * Drawscale, DrawScale * 120, MyDamageType, MomentumTransfer * Drawscale, Location);
	Destroy();	
}

simulated function DoPuff(PlayerPawn Pwner)
{
	local GreenGelPuff f;
	local PlayerPawn P;

	if (RemoteRole < ROLE_Authority)
	{
		ForEach AllActors(class'PlayerPawn', P)
			if (P != Pwner)
			{
				f = spawn(class'GreenGelPuff',P,,Location + SurfaceNormal*8); 
				f.numBlobs = numBio;
				f.bOnlyOwnerSee = True;
				if ( numBio > 0 )
					f.SurfaceNormal = SurfaceNormal;
			}
	}
}

auto state Flying
{
	simulated function ProcessTouch (Actor Other, vector HitLocation) 
	{ 
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( ( Other != Owner && Other.Owner != Owner && Pawn(Other)!=Instigator || bOnGround) && (!Other.IsA('ST_BioGel') || Other.Owner != Owner) )
		{
			bDirect = Other.IsA('Pawn') && !bOnGround;
			Global.Timer(); 
		}
	}
	
	function HitWall( vector HitNormal, actor Wall )
	{
		local PlayerPawn P;

		SetPhysics(PHYS_None);		
		MakeNoise(0.3);	
		bOnGround = True;
		PlayOwnedSound(ImpactSound);
		SetWall(HitNormal, Wall);
		PlayAnim('Hit');
		GoToState('OnSurface');
	}
	
	function Explode( vector HitLocation, vector HitNormal )
	{
		local GreenGelPuff f;

		if (bDeleteMe)
			return;
		f = spawn(class'GreenGelPuff',,,Location + SurfaceNormal*8); 
		f.numBlobs = numBio;
		if ( numBio > 0 )
			f.SurfaceNormal = SurfaceNormal;	
		PlaySound (MiscSound,,3.0*DrawScale);	
		if ( (Mover(Base) != None) && Mover(Base).bDamageTriggered )
			Base.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);

		if (bbPlayer(Owner) != None && !bbPlayer(Owner).bNewNet)
			HurtRadius(damage * Drawscale, DrawScale * 120, MyDamageType, MomentumTransfer * Drawscale, Location);
		NN_Momentum(DrawScale * 120, MomentumTransfer * Drawscale, Location);
		Destroy();	
	}
}

state OnSurface
{
	simulated function ProcessTouch (Actor Other, vector HitLocation)
	{
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if (Other.IsA('ST_BioGel') && Other.Owner == Owner)
			return;
			
		Super.ProcessTouch(Other, HitLocation);
	}
}

simulated function SetWall(vector HitNormal, Actor Wall)
{
	local vector TraceNorm, TraceLoc, Extent;
	local actor HitActor;
	local rotator RandRot;

	SurfaceNormal = HitNormal;
	if ( Level.NetMode != NM_DedicatedServer )
		spawn(class'NN_BioMarkOwnerHidden',Owner,,Location, rotator(SurfaceNormal));
	RandRot = rotator(HitNormal);
	RandRot.Roll += 32768;
	SetRotation(RandRot);	
	if ( Mover(Wall) != None )
		SetBase(Wall);
}

defaultproperties
{
     bOwnerNoSee=True
}