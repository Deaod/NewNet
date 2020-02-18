//=============================================================================
// NN_BigBioGelOwnerHidden.
//=============================================================================
class NN_BigBioGelOwnerHidden extends ST_BigBioGel;

var bool bAlreadyHidden;

simulated function Tick(float DeltaTime)
{
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

function vector GetVRV()
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return vect(0,0,0);
	
	bbP.zzVRVI++;
	if (bbP.zzVRVI == bbP.VRVI_length)
		bbP.zzVRVI = 0;
	return bbP.GetVRV(bbP.zzVRVI)/10000;
}

auto state Flying
{
	simulated function HitWall( vector HitNormal, actor Wall )
	{
		SetPhysics(PHYS_None);		
		MakeNoise(0.6);	
		bOnGround = True;
		PlaySound(ImpactSound);	
		SetWall(HitNormal, Wall);
		DrawScale=DrawScale*1.4;
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
		GotoState('Exploding');
	}
}

defaultproperties
{
     bOwnerNoSee=True
}