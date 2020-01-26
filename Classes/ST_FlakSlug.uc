// ===============================================================
// Stats.ST_FlakSlug: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_FlakSlug extends flakslug;

var ST_Mutator STM;
var actor NN_HitOther;
var int zzNN_ProjIndex;
var bool bDirect;
var bool bHurtEntry;

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
	if ( Other != instigator && Other != Owner && Other.Owner != Owner && NN_HitOther != Other )
	{
		NN_HitOther = Other;
		bDirect = Other.IsA('Pawn');
		NewExplode(HitLocation,Normal(HitLocation - Other.Location));
	}
}

/*simulated function NewExplode(vector HitLocation, vector HitNormal, bool bDirect)
{
	local vector start;
	local ST_UTChunkInfo CI;
	local bbPlayer bbP;
	local ST_UTChunk Proj;
	local int ProjIndex;
	
	bbP = bbPlayer(Owner);
	
	if (STM != None)
		STM.PlayerHit(Instigator, 15, bDirect);		// 15 = Flak Slug
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_FlakSlugOwnerHidden'))
		{
			bbP.NN_HurtRadius(self, class'UT_FlakCannon', 1, 150, 'FlakDeath', MomentumTransfer, HitLocation, zzNN_ProjIndex);
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, HitNormal);
		}
	}
	else
	{
		HurtRadius(damage, 150, 'FlakDeath', MomentumTransfer, HitLocation);
	}
	
	if (STM != None)
		STM.PlayerClear();				// Damage is given now.
	start = Location + 10 * HitNormal;
 	Spawn( class'ut_FlameExplosion',,,Start);
	CI = Spawn(Class'ST_UTChunkInfo', Instigator);
	CI.STM = STM;
	
	Proj = Spawn( class 'ST_UTChunk2',Owner, '', Start);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxClientDemoFix(Proj, class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, Proj.Rotation);
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'ST_UTChunk3',Owner, '', Start);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxClientDemoFix(Proj, class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, Proj.Rotation);
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'ST_UTChunk4',Owner, '', Start);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxClientDemoFix(Proj, class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, Proj.Rotation);
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'ST_UTChunk1',Owner, '', Start);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxClientDemoFix(Proj, class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, Proj.Rotation);
	CI.AddChunk(Proj);
	
	Proj = Spawn( class 'ST_UTChunk2',Owner, '', Start);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxClientDemoFix(Proj, class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, Proj.Rotation);
	CI.AddChunk(Proj);
	
 	Destroy();
}*/

simulated function NewExplode (Vector HitLocation, Vector HitNormal)
{
  local Vector Start;
  local ST_UTChunkInfo CI;
  local actor Victims, TracedTo;
	local int DamageRadius;
	local float damageScale, dist;
	local vector dir, VictimHitLocation, VictimMomentum, MoverHitLocation, MoverHitNormal;
	local bbPlayer bbP;
	local Mover M;

	if(STM != None)
  		STM.PlayerHit(Instigator,15,bDirect);
  //if ( (Role == ROLE_Authority) && (Level.NetMode != NM_Client ))
  //{
    HurtRadius(Damage,150.0,'FlakDeath',MomentumTransfer,HitLocation);
  //}
   bbP = bbPlayer(Owner);

		if( bHurtEntry )
			return;
		
		DamageRadius = 150;
		bHurtEntry = true;
		foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
		{
			if( Victims != self )
			{
				dir = Victims.Location - HitLocation;
				dist = FMax(1,VSize(dir));
				dir = dir/dist;
				dir.Z = FMin(0.45, dir.Z); 
				damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
				VictimHitLocation = Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir;
				VictimMomentum = damageScale * MomentumTransfer * dir;
				if (bbP != None && bbP.bNewNet)
				{
					if (Level.NetMode == NM_Client && !IsA('NN_FlakSlugOwnerHidden'))
					{
						bbP.xxNN_TakeDamage
						(
							Victims,
							class'UT_FlakCannon',
							1,
							Instigator, 
							VictimHitLocation,
							VictimMomentum,
							MyDamageType,
							zzNN_ProjIndex,
							damageScale * Damage,
							DamageRadius
						);
					}
				}
				else
				{
					Victims.TakeDamage
					(
						damageScale * Damage,
						Instigator, 
						VictimHitLocation,
						VictimMomentum,
						MyDamageType
					);
				}
				if (Victims == Owner)
				{
					//NN_Momentum(VictimMomentum, VictimHitLocation);
					NN_Momentum(150, MomentumTransfer, VictimHitLocation);
				}
			} 
		}
		
		if (bbP != None && bbP.bNewNet)
		{
			foreach RadiusActors( class 'Mover', M, DamageRadius, HitLocation )
			{
				TracedTo = Trace(MoverHitLocation, MoverHitNormal, M.Location, HitLocation, True);
				dir = MoverHitLocation - HitLocation;
				dist = FMax(1,VSize(dir));
				if (TracedTo != M || dist > DamageRadius)
					continue;
				dir = dir/dist; 
				damageScale = 1 - FMax(0,(dist - M.CollisionRadius)/DamageRadius);
				bbP.xxNN_ServerTakeDamage( M, class'UT_FlakCannon', 1, Instigator, HitLocation, bbP.GetBetterVector(damageScale * MomentumTransfer * dir), MyDamageType, zzNN_ProjIndex, damageScale * Damage);
				//bbP.xxMover_TakeDamage( M, damageScale * Damage, bbP, M.Location - 0.5 * (M.CollisionHeight + M.CollisionRadius) * dir, damageScale * MomentumTransfer * dir, MyDamageType );
			}
		}
		
		bHurtEntry = false;
		MakeNoise(1.0);
  if (STM != None)
	STM.PlayerClear();
  Start = Location + 10 * HitNormal;
  Spawn(Class'UT_FlameExplosion',,,Start);
  CI = Spawn(Class'ST_UTChunkInfo',Instigator);
  CI.AddChunk(Spawn(Class'ST_UTChunk2',Owner,'None',Start));
  CI.AddChunk(Spawn(Class'ST_UTChunk3',Owner,'None',Start));
  CI.AddChunk(Spawn(Class'ST_UTChunk4',Owner,'None',Start));
  CI.AddChunk(Spawn(Class'ST_UTChunk1',Owner,'None',Start));
  CI.AddChunk(Spawn(Class'ST_UTChunk2',Owner,'None',Start));
  Destroy();
}

simulated function NN_Momentum( float DamageRadius, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
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
	NN_Momentum(150, MomentumTransfer, HitLocation);
	NewExplode(HitLocation, HitNormal);
}

defaultproperties
{
}
