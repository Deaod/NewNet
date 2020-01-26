class ST_UT_SeekingRocket extends UT_SeekingRocket;

var ST_Mutator STM;
var bool bDirect;
var actor NN_HitOther;
var int zzNN_ProjIndex;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
	}
}

simulated function Timer()
{
	local ut_SpriteSmokePuff b;
	local vector SeekingDir;
	local float MagnitudeVel;

	if ( InitialDir == vect(0,0,0) )
		InitialDir = Normal(Velocity);
		 
	if ( (Seeking != None) && (Seeking != Instigator) ) 
	{
		SeekingDir = Normal(Seeking.Location - Location);
		if ( (SeekingDir Dot InitialDir) > 0 )
		{
			MagnitudeVel = VSize(Velocity);
			SeekingDir = Normal(SeekingDir * 0.5 * MagnitudeVel + Velocity);
			Velocity =  MagnitudeVel * SeekingDir;	
			Acceleration = 25 * SeekingDir;	
			SetRotation(rotator(Velocity));
		}
	}
	if ( bHitWater || (Level.NetMode == NM_DedicatedServer) )
		Return;

	if ( (Level.bHighDetailMode && !Level.bDropDetail) || (FRand() < 0.5) )
	{
		b = Spawn(class'ut_SpriteSmokePuff');
		b.RemoteRole = ROLE_None;
	}
}

auto state Flying
{
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( (Other != instigator) && !Other.IsA('Projectile') && Other != Owner && Other.Owner != Owner && NN_HitOther != Other ) 
		{
			bDirect = Other.IsA('Pawn');
			NN_HitOther = Other;
			Explode(HitLocation,Normal(HitLocation-Other.Location));
		}
	}
	
	simulated function Explode(vector HitLocation, vector HitNormal)
	{
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if (bDeleteMe)
			return;
		if (bbP != None && bbP.bNewNet && Level.NetMode == NM_Client && !IsA('NN_ut_SeekingRocketOwnerHidden'))
		{
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, HitNormal);
		}
		
		Super.Explode(HitLocation, HitNormal);
	}

	simulated function BlowUp(vector HitLocation)
	{
		local actor Victims, TracedTo;
		local int DamageRadius;
		local float damageScale, dist;
		local vector dir, VictimHitLocation, VictimMomentum, MoverHitLocation, MoverHitNormal;
		local bbPlayer bbP;
		local Mover M;
		
		bbP = bbPlayer(Owner);

		if( bHurtEntry )
			return;
		
		DamageRadius = 180;
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
					if (Level.NetMode == NM_Client && !IsA('NN_RocketMk2OwnerHidden'))
					{
						bbP.xxNN_TakeDamage
						(
							Victims,
							class'UT_Eightball',
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
					NN_Momentum(VictimMomentum, VictimHitLocation);
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
				bbP.xxNN_ServerTakeDamage( M, class'UT_Eightball', 1, Instigator, HitLocation, bbP.GetBetterVector(damageScale * MomentumTransfer * dir), MyDamageType, zzNN_ProjIndex, damageScale * Damage);
				//bbP.xxMover_TakeDamage( M, damageScale * Damage, bbP, M.Location - 0.5 * (M.CollisionHeight + M.CollisionRadius) * dir, damageScale * MomentumTransfer * dir, MyDamageType );
			}
		}
		
		bHurtEntry = false;
		MakeNoise(1.0);
	}

	simulated function NN_Momentum( vector Momentum, vector HitLocation )
	{
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_Razor2AltOwnerHidden') || RemoteRole == ROLE_Authority )
			return;
		
		if (bbP.Physics == PHYS_None)
			bbP.SetMovementPhysics();
		if (bbP.Physics == PHYS_Walking)
			Momentum.Z = FMax(Momentum.Z, 0.4 * VSize(Momentum));
			
		Momentum = 0.6*Momentum/bbP.Mass;

		bbP.AddVelocity(Momentum);
	}
}

defaultproperties
{
}
