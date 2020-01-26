class ST_ShockProjGreen extends GreenShockProj;

var ST_Mutator STM;

// For Standstill combo Special
var vector StartLocation;
var actor NN_HitOther;
var int zzNN_ProjIndex;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	
	if (Pawn(Owner) != None)
		StartLocation = Pawn(Owner).Location;
	else if (Owner != None)
		StartLocation = Owner.Location;
	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
	}
}

simulated function Tick(float DeltaTime)
{
	//if(Role == ROLE_Authority || Instigator.IsA('Bot'))
	//{
		Texture = Texture'UltimateNewNetv0_6_Database.TeamShock4.G_a00';
		LightBrightness=255;
   		LightHue=106;
    	LightSaturation=64;
    	LightRadius=6;
    	LightEffect=LE_Cylinder;
	//}
}

function SuperExplosion()	// aka, combo.
{	
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	if (STM != None)
	{
		STM.PlayerUnfire(Pawn(Owner), 6);			// 6 = Shock Ball -> remove this
		STM.PlayerFire(Pawn(Owner), 7);				// 7 = Shock Combo -> Pawn(Owner) gets +1 Combo
		STM.PlayerHit(Pawn(Owner), 7, Pawn(Owner).Location == StartLocation);	// 7 = Shock Combo, bSpecial if Standstill.
	}
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_ShockProjGreenOwnerHidden'))
		{
			bbP.NN_HurtRadius(self, class'ShockRifle', 2, 250, MyDamageType, MomentumTransfer*2, Location, zzNN_ProjIndex );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*3, 250, MyDamageType, MomentumTransfer*2, Location );
	}
	if (STM != None)
		STM.PlayerClear();
	
	if(Pawn(Owner) != None)
	{
		Spawn(Class'Green_ComboRing',,'',Location, Pawn(Owner).ViewRotation);
	}
	PlayOwnedSound(ExploSound,,20.0,,2000,0.6);
	
	Destroy(); 
}

function SuperDuperExplosion()	// aka, combo.
{	
	local bbPlayer bbP;
   	local Green_SuperComboRing GRing;
	
	bbP = bbPlayer(Owner);
	if (STM != None)
	{
		STM.PlayerUnfire(Pawn(Owner), 6);			// 6 = Shock Ball -> remove this
		STM.PlayerFire(Pawn(Owner), 7);				// 7 = Shock Combo -> Pawn(Owner) gets +1 Combo
		STM.PlayerHit(Pawn(Owner), 7, Pawn(Owner).Location == StartLocation);	// 7 = Shock Combo, bSpecial if Standstill.
	}
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client)
		{
			bbP.NN_HurtRadius(self, class'ShockRifle', 2, 250, MyDamageType, MomentumTransfer*2, Location, zzNN_ProjIndex );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*3, 250, MyDamageType, MomentumTransfer*2, Location );
	}
	if (STM != None)
		STM.PlayerClear();
	
	if(bbP != none && Pawn(Owner) != None)
    {
    	GRing = Spawn(Class'Green_SuperComboRing',,'',Location, Pawn(Owner).ViewRotation);
	}
	PlayOwnedSound(ExploSound,,20.0,,2000,0.6);
	
	Destroy(); 
}

simulated function NN_SuperExplosion(Pawn Pwner)	// aka, combo.
{
	local rotator Tater;
	local bbPlayer bbP;
	local Green_ComboRing GreenRing;
	
	bbP = bbPlayer(Pwner);
		
	if (bbP != None)
		Tater = bbP.zzViewRotation;
	else
		Tater = Pwner.ViewRotation;
		
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client)
		{
			bbP.NN_HurtRadius(self, class'ShockRifle', 2, 250, MyDamageType, MomentumTransfer*2, Location, zzNN_ProjIndex );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*3, 250, MyDamageType, MomentumTransfer*2, Location );
	}
	if(Pawn(Owner) != None && Pwner != None)
	{
		GreenRing = Spawn(Class'Green_ComboRing',Pawn(Owner),'',Location, Tater);
	}
	PlaySound(ExploSound,,20.0,,2000,0.6);
    if(bbP != none && Pawn(Owner) != None)
    {
    	bbP.xxClientDemoFix(GreenRing, class'Green_ComboRing', Location, GreenRing.Velocity, GreenRing.Acceleration, Tater);		
    }
	
	Destroy();
}

simulated function NN_SuperDuperExplosion(Pawn Pwner)	// aka, combo.
{
	local rotator Tater;
	local bbPlayer bbP;
    local Green_SuperComboRing GRing;
	
	bbP = bbPlayer(Pwner);
		
	if (bbP != None)
		Tater = bbP.zzViewRotation;
	else
		Tater = Pwner.ViewRotation;
		
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client)
		{
			bbP.NN_HurtRadius(self, class'ShockRifle', 3, 250, MyDamageType, MomentumTransfer*6, Location, zzNN_ProjIndex );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*2, 250, MyDamageType, MomentumTransfer*6, Location );
	}

	if(bbP != none && Pawn(Owner) != None)
    {
    	GRing = Spawn(Class'Green_SuperComboRing',Pawn(Owner),'',Location, Tater);
	}
	PlaySound(ExploSound,,20.0,,2000,0.6);
    if(bbP != none && Pawn(Owner) != None)
    {
    	bbP.xxClientDemoFix(GRing, Class'Green_SuperComboRing', Location, GRing.Velocity, GRing.Acceleration, Tater);
    }
	
	Destroy();
}

auto state Flying
{
	simulated function ProcessTouch(Actor Other, vector HitLocation)
	{
		if (bDeleteMe || Other == None || Other.bDeleteMe)
			return;
		If ( Level.NetMode == NM_Client && Other!=Owner && Other!=Pawn(Owner) && Other.Owner != Owner && (!Other.IsA('Projectile') || (Other.CollisionRadius > 0)) && NN_HitOther != Other )
		{
			if (Other.IsA('Projectile') && Other.bOwnerNoSee)
				bbPlayer(Owner).xxExplodeOther(Projectile(Other));
			NN_HitOther = Other;
			Explode(HitLocation,Normal(HitLocation-Other.Location));
		}
	}

	simulated function BeginState()
	{
		Velocity = vector(Rotation) * speed;	
	}
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	local bbPlayer bbP;
	local Pawn P;
	
	bbP = bbPlayer(Owner);
	
	if (bDeleteMe)
		return;
	
	if (STM != None)
		STM.PlayerHit(Pawn(Owner), 6, False);	// 6 = Shock Ball

	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_ShockProjGreenOwnerHidden'))
		{
			bbP.NN_HurtRadius(self, class'ShockRifle', 1, 70, MyDamageType, MomentumTransfer, Location, zzNN_ProjIndex );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, HitLocation, HitNormal);
		}
	}
	else
	{
		HurtRadius(Damage, 70, MyDamageType, MomentumTransfer, Location );
	}
	NN_Momentum( 70, MomentumTransfer, Location );
	if (STM != None)
		STM.PlayerClear();

	if (Damage > 60)
	{
		if(Pawn(Owner) != None)
		{
			Spawn(class'Green_RingExplosion',,, HitLocation+HitNormal*8,rotator(HitNormal));
		}

		if (bbP != None && Pawn(Owner) != None)
		{
			bbP.xxClientDemoFix(None, class'Green_RingExplosion',HitLocation+HitNormal*8,,, rotator(HitNormal));
		}
	}
	else
	{
		if(Pawn(Owner) != None)
		{
			Spawn(class'Green_RingExplosion',,, HitLocation+HitNormal*8,rotator(HitNormal));
		}

		if (bbP != None && Pawn(Owner) != None)
		{
			bbP.xxClientDemoFix(None, class'Green_RingExplosion',HitLocation+HitNormal*8,,, rotator(HitNormal));
		}
	}
		
	PlayOwnedSound(ImpactSound, SLOT_Misc, 0.5,,, 0.5+FRand());

	Destroy();
}

simulated function NN_Momentum( float DamageRadius, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_ShockProjGreenOwnerHidden') || RemoteRole == ROLE_Authority )
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

function TakeDamage( int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, name DamageType)
{
	if (STM != None)
	{
		if (DamageType == 'shot') // || DamageType == 'Pulsed' ||		// Enforcer/Minigun/Sniper, Pulse Sphere
	//		DamageType == 'Corroded' || DamageType == 'jolted')	// Bio and Shock Ball.
			STM.PlayerSpecial(Pawn(Owner), 6);	// 6 = Shock Ball blocked a shot.
	}
}

defaultproperties
{
	Texture=Texture'UltimateNewNetv0_6_Database.TeamShock4.G_a00'
	LightBrightness=255
   	LightHue=106
    LightSaturation=64
    LightRadius=6
    LightEffect=LE_Cylinder
}