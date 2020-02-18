//================================================================================
// ST_BioGel.
//================================================================================
class ST_BioGel extends BioGel;

var bool bDirect;
var actor NN_HitOther;
var int zzNN_ProjIndex;

simulated function Timer()
{
	local GreenGelPuff f;
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);

	f = spawn(class'GreenGelPuff',,,Location + SurfaceNormal*8); 
	f.numBlobs = numBio;
	if ( numBio > 0 )
		f.SurfaceNormal = SurfaceNormal;	
	PlaySound (MiscSound,,3.0*DrawScale);	
	if ( (Mover(Base) != None) && Mover(Base).bDamageTriggered )
		Base.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);

	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !bOwnerNoSee)
		{
			if (IsA('BioGlob'))
				bbP.NN_HurtRadius(self, class'UT_BioRifle', 1, FMin(250, DrawScale * 75), MyDamageType, MomentumTransfer * Drawscale, Location, zzNN_ProjIndex, false, damage * Drawscale);
			else
				bbP.NN_HurtRadius(self, class'UT_BioRifle', 0, FMin(250, DrawScale * 75), MyDamageType, MomentumTransfer * Drawscale, Location, zzNN_ProjIndex, false, damage * Drawscale);
		}
	}
	else
	{
		HurtRadius(damage * Drawscale, DrawScale * 120, MyDamageType, MomentumTransfer * Drawscale, Location);
	}
	NN_Momentum(DrawScale * 120, MomentumTransfer * Drawscale, Location);
	Destroy();
}
	
simulated function SetWall(vector HitNormal, Actor Wall)
{
	local vector TraceNorm, TraceLoc, Extent;
	local actor HitActor;
	local rotator RandRot;

	SurfaceNormal = HitNormal;
	if ( Level.NetMode != NM_DedicatedServer )
		spawn(class'BioMark',,,Location, rotator(SurfaceNormal));
	RandRot = rotator(HitNormal);
	RandRot.Roll += 32768;
	SetRotation(RandRot);	
	if ( Mover(Wall) != None )
		SetBase(Wall);
}

simulated function NN_Momentum( float DamageRadius, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_BioGelOwnerHidden') || RemoteRole == ROLE_Authority )
		return;

	foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
	{
		if( Victims == Owner )
		{
			dir = Owner.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist; 
			damageScale = 1 - FMax(0,(dist - Owner.CollisionRadius)/DamageRadius);
			
			dir = damageScale * Momentum * dir;
			
			if (bbP.Physics == PHYS_None)
				bbP.SetMovementPhysics();
			if (bbP.Physics == PHYS_Walking)
				dir.Z = FMax(dir.Z, 0.4 * VSize(dir));
				
			dir = 0.6*dir/bbP.Mass;

			bbP.AddVelocity(dir); 
		}
	}
}

auto state Flying
{
	simulated function ProcessTouch (Actor Other, vector HitLocation) 
	{ 
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( ( Other != Owner && Pawn(Other)!=Instigator /*&& ther.Owner != Owner  */|| bOnGround) && (!Other.IsA('ST_BioGel')/*  || Other.Owner != Owner */) && NN_HitOther != Other && !bOwnerNoSee )
		{
			NN_HitOther = Other;
			bDirect = Other.IsA('Pawn') && !bOnGround;
			Global.Timer(); 
	
			if (bbP != None && bbP.bNewNet && Level.NetMode == NM_Client)
			{
				bbP.xxNN_TakeDamage(Other, class'UT_BioRifle', 0, Instigator, HitLocation, MomentumTransfer*Vector(Rotation), MyDamageType, zzNN_ProjIndex);
				bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, Normal(HitLocation - Other.Location));
			}
		}
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
	MyDamageType=Corroded
}