class ST_RocketMk2 extends RocketMk2;

var ST_Mutator STM;
var bool bDirect;
var actor NN_HitOther;
var int zzNN_ProjIndex;
var bool bHurtEntry;

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

auto state Flying
{
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		if ( (Other != instigator) && !Other.IsA('Projectile') && Other != Owner && Other.Owner != Owner )
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
		
		bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, HitNormal);
		Super.Explode(HitLocation, HitNormal);
	}

	/*simulated function BlowUp(vector HitLocation)
	{
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if (STM != None)
			STM.PlayerHit(Instigator, 16, bDirect);		// 16 = Rockets.
		//if ( (Role == ROLE_Authority) && (Level.NetMode != NM_Client ))
  		//{
    		HurtRadius(Damage,150.0,MyDamageType,MomentumTransfer,HitLocation);
  		//}
		NN_Momentum(220.0, MomentumTransfer, HitLocation);
		if (STM != None)
			STM.PlayerClear();
		MakeNoise(1.0);
	}*/

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
	
	simulated function BeginState()
	{
		local vector Dir;

		Dir = vector(Rotation);
		Velocity = speed * Dir;
		Acceleration = Dir * 50;
		PlayAnim( 'Wing', 0.2 );
		if (Region.Zone.bWaterZone)
		{
			bHitWater = True;
			Velocity=0.6*Velocity;
		}
	}

	/*simulated function NN_Momentum( float DamageRadius, float Momentum, vector HitLocation )
	{
		local actor Victims;
		local float damageScale, dist;
		local vector dir;
		local bbPlayer bbP;
		
		bbP = bbPlayer(Owner);
		
		if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_rocketmk2OwnerHidden') || RemoteRole == ROLE_Authority )
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
	}*/

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
	MomentumTransfer=80000
}
