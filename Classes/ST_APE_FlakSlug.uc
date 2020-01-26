class ST_APE_FlakSlug extends APE_FlakSlug;

var ST_Mutator STM;
var actor NN_HitOther;
var int zzNN_ProjIndex;

function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
	}
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{		
	if (bDeleteMe || Other == None || Other.bDeleteMe)
		return;
	if ( Other != instigator && Other != Owner && /* Other.Owner != Owner && */ NN_HitOther != Other )
	{
		NN_HitOther = Other;
		NewExplode(HitLocation,Normal(HitLocation-Other.Location), Other.IsA('Pawn'));
	}
}

simulated function NewExplode(vector HitLocation, vector HitNormal, bool bDirect)
{
	local vector start;
	local bbPlayer bbP;
	local int ProjIndex;
	local rotator aRot;
	local ST_FlakSlug Proj1;
	local ST_APE_FlakSlug Proj2;
	
	bbP = bbPlayer(Owner);
	
	if (STM != None)
		STM.PlayerHit(Instigator, 15, bDirect);		// 15 = Flak Slug
	if (bbP != None && bbP.bNewNet)
	{
			if (Level.NetMode == NM_Client && !IsA('NN_APE_FlakSlugOwnerHiddenFlakSlugOwnerHidden'))
			{
				bbP.NN_HurtRadius(self, 21, 170, 'FlakDeath', MomentumTransfer, HitLocation, zzNN_ProjIndex);
				bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, HitNormal);
			}
	}
	else
	{
		HurtRadius(damage, 170, 'FlakDeath', MomentumTransfer, HitLocation);
	}
	
	if (STM != None)
		STM.PlayerClear();				// Damage is given now.
	start = Location + 12 * HitNormal;
 	Spawn( class'ut_FlameExplosion',,,Start);
	aRot = rotator( vector(rotation)*2 + hitnormal);

	if ( bLast )
	{
		Spawn( class 'ST_FlakSlug',Owner, '', Start, aRot);
		//bbP.xxClientDemoFix(Proj1, class'FlakSlug', Start, Proj1.Velocity, Proj1.Acceleration, Proj1.Rotation);
		Destroy();
	}
	else if ( FRand() > 0.05 )
	{
		Spawn( class 'ST_APE_FlakSlug',Owner, '', Start, aRot).bLast = True;
		//bbP.xxClientDemoFix(Proj2, class'APE_FlakSlug', Start, Proj2.Velocity, Proj2.Acceleration, Proj2.Rotation);
	 	Destroy();
	}
 	Destroy();
}

simulated function NN_Momentum( float DamageRadius, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_APE_FlakSlugOwnerHidden') || RemoteRole == ROLE_Authority )
		return;
	if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_FlakSlugOwnerHidden') || RemoteRole == ROLE_Authority )
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

simulated function Explode(vector HitLocation, vector HitNormal)
{
	if (bDeleteMe)
		return;
	NN_Momentum(170, MomentumTransfer, HitLocation);
	NewExplode(HitLocation, HitNormal, False);
}

defaultproperties
{
}
