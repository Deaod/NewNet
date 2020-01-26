class ST_sgShockProjRed extends ST_sgShockProj;

simulated function Tick(float DeltaTime)
{
	Texture = Texture'R_a00';
	LightBrightness=255;
	LightHue=0;
	LightSaturation=0;
	LightRadius=6;
	LightEffect=LE_Cylinder;
}

function SuperExplosion()	// aka, combo.
{	
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	if (STM != None)
	{
		STM.PlayerUnfire(Instigator, 6);			// 6 = Shock Ball -> remove this
		STM.PlayerFire(Instigator, 7);				// 7 = Shock Combo -> Instigator gets +1 Combo
		STM.PlayerHit(Instigator, 7, Instigator.Location == StartLocation);	// 7 = Shock Combo, bSpecial if Standstill.
	}
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_sgShockProjRedOwnerHidden'))
		{
			bbP.NN_HurtRadius(self, 9, 250, MyDamageType, MomentumTransfer*2, Location, zzNN_ProjIndex );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*3, 250, MyDamageType, MomentumTransfer*2, Location );
	}
	if (STM != None)
		STM.PlayerClear();
	
	Spawn(Class'Red_ComboRing',,'',Location, Instigator.ViewRotation);
	PlayOwnedSound(ExploSound,,20.0,,2000,0.6);
	
	Destroy(); 
}

function SuperDuperExplosion()	// aka, combo.
{	
	local bbPlayer bbP;
    local Red_SuperComboRing Ring;
	
	bbP = bbPlayer(Owner);
	if (STM != None)
	{
		STM.PlayerUnfire(Instigator, 6);			// 6 = Shock Ball -> remove this
		STM.PlayerFire(Instigator, 7);				// 7 = Shock Combo -> Instigator gets +1 Combo
		STM.PlayerHit(Instigator, 7, Instigator.Location == StartLocation);	// 7 = Shock Combo, bSpecial if Standstill.
	}
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_sgShockProjRedOwnerHidden'))
		{
			bbP.NN_HurtRadius(self, 10, 750, MyDamageType, MomentumTransfer*6, Location, zzNN_ProjIndex );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*9, 750, MyDamageType, MomentumTransfer*6, Location );
	}
	if (STM != None)
		STM.PlayerClear();
	
	Ring = Spawn(Class'Red_SuperComboRing',,'',Location, Instigator.ViewRotation);
	PlayOwnedSound(ExploSound,,20.0,,2000,0.6);
	
	Destroy(); 
}

simulated function NN_SuperExplosion(Pawn Pwner)	// aka, combo.
{
	local rotator Tater;
	local bbPlayer bbP;
    local Red_ComboRing Ring;
	
	bbP = bbPlayer(Pwner);
		
	if (bbP != None)
		Tater = bbP.zzViewRotation;
	else
		Tater = Pwner.ViewRotation;
		
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client)
		{
			bbP.NN_HurtRadius(self, 9, 250, MyDamageType, MomentumTransfer*2, Location, zzNN_ProjIndex );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*3, 250, MyDamageType, MomentumTransfer*2, Location );
	}
	Ring = Spawn(Class'Red_ComboRing',Pwner,'',Location, Tater);
	PlaySound(ExploSound,,20.0,,2000,0.6);
    if(bbP != none)
    {
        bbP.xxClientDemoFix(Ring, class'Red_ComboRing', Location, Ring.Velocity, Ring.Acceleration, Tater);
    }
	
	Destroy();
}

simulated function NN_SuperDuperExplosion(Pawn Pwner)	// aka, combo.
{
	local rotator Tater;
	local bbPlayer bbP;
    local Red_SuperComboRing Ring;
	
	bbP = bbPlayer(Pwner);
		
	if (bbP != None)
		Tater = bbP.zzViewRotation;
	else
		Tater = Pwner.ViewRotation;
		
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client)
		{
			bbP.NN_HurtRadius(self, 10, 750, MyDamageType, MomentumTransfer*6, Location, zzNN_ProjIndex );
			bbP.xxNN_RemoveProj(zzNN_ProjIndex, Location, vect(0,0,0), true);
		}
	}
	else
	{
		HurtRadius(Damage*9, 750, MyDamageType, MomentumTransfer*6, Location );
	}
	Ring = Spawn(Class'Red_SuperComboRing',Pwner,'',Location, Tater);
	PlaySound(ExploSound,,20.0,,2000,0.6);
    if(bbP != none)
        bbP.xxClientDemoFix(Ring, Class'Red_SuperComboRing', Location, Ring.Velocity, Ring.Acceleration, Tater);
	
	Destroy();
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	
	if (bDeleteMe)
		return;
	
	if (STM != None)
		STM.PlayerHit(Instigator, 6, False);	// 6 = Shock Ball
	if (bbP != None && bbP.bNewNet)
	{
		if (Level.NetMode == NM_Client && !IsA('NN_sgShockProjRedOwnerHidden'))
		{
			bbP.NN_HurtRadius(self, 8, 70, MyDamageType, MomentumTransfer, Location, zzNN_ProjIndex );
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
		Spawn(class'UT_RedRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
		if (bbP != None)
			bbP.xxClientDemoFix(None, class'UT_RedRingExplosion2',HitLocation+HitNormal*8,,, rotator(HitNormal));
	}
	else
	{
		Spawn(class'UT_RedRingExplosion2',,, HitLocation+HitNormal*8,rotator(Velocity));
		if (bbP != None)
			bbP.xxClientDemoFix(None, class'UT_RedRingExplosion2',HitLocation+HitNormal*8,,, rotator(Velocity));
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
	
	if ( bbP == None || !bbP.bNewNet || Self.IsA('NN_sgShockProjRedOwnerHidden') || RemoteRole == ROLE_Authority )
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

defaultproperties
{
    Texture=Texture'R_a00'
   	LightBrightness=255
   	LightHue=0
    LightSaturation=0
    LightRadius=6
    LightEffect=LE_Cylinder
}
