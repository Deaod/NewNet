// ===============================================================
// UTPureStats7A.ST_PulseGun: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_PulseGun extends PulseGun;

var bool bNewNet;				// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;

simulated function RenderOverlays(Canvas Canvas)
{
	local bbPlayer bbP;
	
	Super.RenderOverlays(Canvas);
	yModInit();
	
	bbP = bbPlayer(Owner);
	if (bNewNet && Role < ROLE_Authority && bbP != None)
	{
		if (bbP.bFire != 0 && !IsInState('ClientFiring'))
			ClientFire(1);
		else if (bbP.bAltFire != 0 && !IsInState('ClientAltFiring'))
			ClientAltFire(1);
	}
}

simulated function yModInit()
{
	if (bbPlayer(Owner) != None && Owner.Role == ROLE_AutonomousProxy)
		GV = bbPlayer(Owner).zzViewRotation;
	
	if (PlayerPawn(Owner) == None)
		return;
		
	yMod = PlayerPawn(Owner).Handedness;
	if (yMod != 2.0)
		yMod *= Default.FireOffset.Y;
	else
		yMod = 0;

	CDO = CalcDrawOffset();
}

function Fire( float Value )
{
	local bbPlayer bbP;
	local NN_PlasmaSphereOwnerHidden NNPS;
	
	if ( (AmmoType == None) && (AmmoName != None) )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		GotoState('NormalFire');
		bPointing=True;
		bCanClientFire = true;
		ClientFire(Value);
		if (!bNewNet && (bRapidFire || (FiringSpeed > 0) ) )
		{
			Pawn(Owner).PlayRecoil(FiringSpeed);
		}
		if (bNewNet)
		{
			NNPS = NN_PlasmaSphereOwnerHidden(ProjectileFire(class'NN_PlasmaSphereOwnerHidden', ProjectileSpeed, bWarnTarget));
			NNPS.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
			bbP = bbPlayer(Owner);
			if (bbP != None)
				NNPS.zzNN_ProjIndex = bbP.xxNN_AddProj(NNPS);
		}
		else
			ProjectileFire(ProjectileClass, ProjectileSpeed, bWarnTarget);
	}
}

function AltFire( float Value )
{
	local Vector Start, X,Y,Z;
	
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if (AmmoType.UseAmmo(1))
	{
		GotoState('AltFiring');
		bCanClientFire = true;
		bPointing=True;
		ClientAltFire(value);

		if (!bNewNet)
		{
			Pawn(Owner).PlayRecoil(FiringSpeed);
		}

		if ( PlasmaBeam == None )
		{
			if (bNewNet)
				PlasmaBeam = PBolt(ProjectileFire(Class'NN_StarterBoltOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
			else
				PlasmaBeam = PBolt(ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget));
			if ( FireOffset.Y == 0 )
				PlasmaBeam.bCenter = true;
			else if ( Mesh == mesh'PulseGunR' )
				PlasmaBeam.bRight = false;
		}
	}
}

State ClientActive
{
	simulated function bool ClientFire(float Value)
	{
		if (Owner.IsA('Bot'))
			return Super.ClientFire(Value);
		bForceFire = bbPlayer(Owner) == None /* || !bbPlayer(Owner).ClientCannotShoot() */;
		return bForceFire;
	}

	simulated function bool ClientAltFire(float Value)
	{
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(Value);
		bForceAltFire = bbPlayer(Owner) == None /* || !bbPlayer(Owner).ClientCannotShoot() */;
		return bForceAltFire;
	}
	
	simulated function AnimEnd()
	{
		if ( Owner == None )
		{
			Global.AnimEnd();
			GotoState('');
		}
		else if ( Owner.IsA('TournamentPlayer') 
			&& (TournamentPlayer(Owner).PendingWeapon != None || TournamentPlayer(Owner).ClientPending != None) )
			GotoState('ClientDown');
		else if ( bWeaponUp )
		{
			if ( (bForceFire || (PlayerPawn(Owner).bFire != 0)) && Global.ClientFire(1) )
				return;
			else if ( (bForceAltFire || (PlayerPawn(Owner).bAltFire != 0)) && Global.ClientAltFire(1) )
				return;
			PlayIdleAnim();
			GotoState('');
		}
		else
		{
			PlayPostSelect();
			bWeaponUp = true;
		}
	}
}

state AltFiring
{
	ignores AnimEnd;

	function Tick(float DeltaTime)
	{
		local Pawn P;
		
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}

		P = Pawn(Owner);
		if ( P == None )
		{
			GotoState('Pickup');
			return;
		}
		if ( (P.bAltFire == 0) || (P.IsA('Bot')
					&& ((P.Enemy == None) || (Level.TimeSeconds - Bot(P).LastSeenTime > 5))) )
		{
			P.bAltFire = 0;
			Finish();
			return;
		}

		Count += Deltatime;
		if ( Count > 0.24 )
		{
			Count -= 0.24;
			if ( !AmmoType.UseAmmo(1) )
				Finish();
		}
	}
Begin:
	AmbientGlow = 200;
	FinishAnim();
	PlayAnim( 'boltloop');
}

simulated function bool ClientFire( float Value)
{
	local Vector Start, X,Y,Z;
	local ST_PlasmaSphere ps;
	local int ProjIndex;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
/* 		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false; */
		yModInit();
		
		if ( (AmmoType == None) && (AmmoName != None) )
		{
			// ammocheck
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			GotoState('ClientFiring');
			bPointing=True;
			bCanClientFire = true;
			if ( bRapidFire || (FiringSpeed > 0) )
				Pawn(Owner).PlayRecoil(FiringSpeed);

			GetAxes(GV,X,Y,Z);
			Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
			Start = Start - Sin(Angle)*Y*4 + (Cos(Angle)*4 - 10.78)*Z;
			Angle += 1.8;
			
			ps = Spawn(class'ST_PlasmaSphere', Owner,, Start, GV);
			if (bbP != None)
			{
				ProjIndex = bbP.xxNN_AddProj(ps);
				ps.zzNN_ProjIndex = ProjIndex;
			}
			
			bbP.xxNN_Fire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			bbP.xxClientDemoFix(PS, class'PlasmaSphere', Start, PS.Velocity, PS.Acceleration, GV);
		}
	}
	return Super.ClientFire(Value);
}

simulated state ClientFiring
{
	simulated function Tick( float DeltaTime )
	{
 		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}
		if (Owner==None) 
			GotoState('Pickup');
			
		if ( (Pawn(Owner) != None) && (Pawn(Owner).bFire != 0) )
		{
			AmbientSound = FireSound;
		}
		else
			AmbientSound = None;
	}

	simulated function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		
		if ( (AmmoType != None) && (AmmoType.AmmoAmount <= 0) )
		{
			PlaySpinDown();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner) == None )
		{
			PlaySpinDown();
			GotoState('');
		}
	}

	simulated function BeginState()
	{
		Super.BeginState();
		if (Owner.IsA('Bot'))
			return;
		Angle = 0;
		AmbientGlow = 200;
	}

	simulated function EndState()
	{
		if (!Owner.IsA('Bot'))
		{
			PlaySpinDown();
			AmbientSound = None;
			AmbientGlow = 0;	
			OldFlashCount = FlashCount;
		}
		Super.EndState();
	}
	
Begin:
	if (!Owner.IsA('Bot'))
	{
		Sleep(0.18);
		ClientFinish();
	}
}

simulated function ClientFinish()
{
	local Pawn PawnOwner;
	local bool bForce, bForceAlt;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return;
	
	bbP = bbPlayer(Owner);
	bForce = bForceFire;
	bForceAlt = bForceAltFire;
	bForceFire = false;
	bForceAltFire = false;

	if ( bChangeWeapon )
	{
		GotoState('DownWeapon');
		return;
	}

	PawnOwner = Pawn(Owner);
	if ( PawnOwner == None )
		return;
		
	AnimEnd();
	if ( ((AmmoType != None) && (AmmoType.AmmoAmount<=0)) || (PawnOwner.Weapon != self) )
		GotoState('Idle');
	else if ( (PawnOwner.bFire!=0) || bForce )
		Global.ClientFire(0);
	else if ( (PawnOwner.bAltFire!=0) || bForceAlt )
		Global.ClientAltFire(0);
	else 
		GotoState('Idle');
}

simulated function bool ClientAltFire( float Value )
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
/* 		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false; */
		Instigator = Pawn(Owner);
		bCanClientFire = AmmoType.AmmoAmount > 0;
		GotoState('ClientAltFiring');
		if ( PlasmaBeam == None )
		{
			PlasmaBeam = PBolt(NN_ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget));
			if ( bHideWeapon )
				PlasmaBeam.bCenter = true;
			else if ( Mesh == mesh'PulseGunR' )
				PlasmaBeam.bRight = false;
			
			bbP.xxNN_AltFire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			bbP.xxClientDemoBolt(PlasmaBeam, PlasmaBeam.Location, PlasmaBeam.Rotation);
		}
	}
	return Super.ClientAltFire(Value);
}

state NormalFire
{
	function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
	{
		local Vector Start, X,Y,Z;
		local bbPlayer bbP;
		
		if (Owner.IsA('Bot'))
			return Super.ProjectileFire(ProjClass, ProjSpeed, bWarn);
		
		yModInit();
		
		bbP = bbPlayer(Owner);

		Owner.MakeNoise(Pawn(Owner).SoundDampening);
		if (bbP == None || !bNewNet)
		{
			GetAxes(Pawn(Owner).ViewRotation,X,Y,Z);
			Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}
		else
		{
			GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
			if (Mover(bbP.Base) == None)
				Start = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			else
				Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}
		AdjustedAim = pawn(owner).AdjustAim(ProjSpeed, Start, AimError, True, bWarn);	
		Start = Start - Sin(Angle)*Y*4 + (Cos(Angle)*4 - 10.78)*Z;
		Angle += 1.8;
		return Spawn(ProjClass,Owner,, Start,AdjustedAim);	
	}
	function BeginState()
	{
		if (!Owner.IsA('Bot'))
			AmbientSound = FireSound;
		Super.BeginState();
	}
}

state ClientAltFiring
{
	simulated function Tick(float DeltaTime)
	{
		local Pawn P;
		
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}

		P = Pawn(Owner);
		if ( P == None )
		{
			GotoState('Pickup');
			return;
		}
		if ( (P.bAltFire == 0) || (P.IsA('Bot')
					&& ((P.Enemy == None) || (Level.TimeSeconds - Bot(P).LastSeenTime > 5))) )
		{
			P.bAltFire = 0;
			ClientFinish();
			return;
		}

		Count += Deltatime;
		if ( Count > 0.24 )
		{
			if ( Affector != None )
				Affector.FireEffect();
			if ( PlayerPawn(Owner) != None && (!bNewNet || Level.NetMode == NM_Client) )
			{
				PlayerPawn(Owner).ClientInstantFlash( InstFlash, InstFog);
			}
			Count -= 0.24;
			AmmoType.UseAmmo(1);
			if ( AmmoType.AmmoAmount < 1 )
				Finish();
		}
	}

	simulated function EndState()
	{
		if (!Owner.IsA('Bot'))
		{
			AmbientGlow = 0;
			AmbientSound = None;
			if ( PlasmaBeam != None )
			{
				PlasmaBeam.Destroy();
				PlasmaBeam = None;
			}
		}
		Super.EndState();
	}
	simulated function AnimEnd()
	{
		if ( AmmoType.AmmoAmount <= 0 )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner) == None )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( Pawn(Owner).bAltFire != 0 )
			PlayAnim('BoltLoop');
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else
		{
			PlayIdleAnim();
			GotoState('');
		}
	}
Begin:
	if (!Owner.IsA('Bot'))
	{
		AmbientGlow = 200;
		FinishAnim();
		PlayAnim( 'boltloop');
	}
}

simulated function Projectile NN_ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;
	
	if (Owner.IsA('Bot'))
		return None;
		
	yModInit();

	GetAxes(GV,X,Y,Z);
	Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
	Start = Start - Sin(Angle)*Y*4 + (Cos(Angle)*4 - 10.78)*Z;
	Angle += 1.8;
	return Spawn(ProjClass,Owner,, Start,GV);	
}

function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ProjectileFire(ProjClass, ProjSpeed, bWarn);
	
	yModInit();
	
	bbP = bbPlayer(Owner);

	PawnOwner = Pawn(Owner);
	Owner.MakeNoise(PawnOwner.SoundDampening);
	if (bbP == None || !bNewNet)
		GetAxes(Pawn(Owner).ViewRotation,X,Y,Z);
	else
		GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
	Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
	AdjustedAim = PawnOwner.AdjustAim(ProjSpeed, Start, AimError, True, bWarn);	
	return Spawn(ProjClass,Owner,, Start,AdjustedAim);	
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'PulseGun');
}

simulated function TweenDown ()
{
	Class'NN_WeaponFunctions'.static.TweenDown( self);
}


simulated function PlaySelect ()
{
	Class'NN_WeaponFunctions'.static.PlaySelect( self);
}

simulated function AnimEnd ()
{
	if ( (Level.NetMode == NM_Client) && (Mesh != PickupViewMesh) )
		AmbientSound = None;
	Class'NN_WeaponFunctions'.static.AnimEnd( self);
}

simulated function PlayIdleAnim()
{
	if ( Mesh == PickupViewMesh )
		return;
	if ( (AnimSequence == 'BoltLoop') || (AnimSequence == 'BoltStart') )
		PlayAnim('BoltEnd',1.0,0.05);		
	else if ( AnimSequence != 'SpinDown' )
		LoopAnim('Still',1.0,0.05);
}

simulated function TweenToStill()
{
	if ( Mesh == PickupViewMesh )
		return;
	Super.TweenToStill();
}

simulated function PlayFiring()
{
	FlashCount++;
	AmbientSound = FireSound;
	PlayAnim( 'shootLOOP', 1 + 0.5 * FireAdjust, 0.0);
	SoundVolume = Pawn(Owner).SoundDampening*255;
	bWarnTarget = (FRand() < 0.2);
}

auto state Pickup
{
	ignores AnimEnd;
	
	simulated function Landed(Vector HitNormal)
	{
		Super(Inventory).Landed(HitNormal);
	}
}

defaultproperties
{
    bNewNet=True
    ProjectileClass=Class'ST_PlasmaSphere'
    AltProjectileClass=Class'ST_StarterBolt'
}