// ===============================================================
// Stats.ST_enforcer: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_enforcer extends enforcer;

var bool bNewNet;				// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;
var int ClipCount;

simulated function RenderOverlays(Canvas Canvas)
{
	local bbPlayer bbP;
	
	Super.RenderOverlays(Canvas);
	if (bIsSlave)
		return;
	
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
	if (bIsSlave)
		return;
		
	if (bbPlayer(Owner) != None && Owner.Role == ROLE_AutonomousProxy)
		GV = bbPlayer(Owner).zzViewRotation;
	
	if (PlayerPawn(Owner) == None)
		return;
		
	//yMod = PlayerPawn(Owner).Handedness;
	//if (yMod != 2.0)
	//	yMod *= Default.FireOffset.Y;
	//else
		yMod = 0;

	CDO = CalcDrawOffset();
	
	if (SlaveEnforcer != None)
	{
		ST_enforcer(SlaveEnforcer).yMod = yMod;
		ST_enforcer(SlaveEnforcer).CDO = CDO;
		ST_enforcer(SlaveEnforcer).GV = GV;
	}
}

simulated function bool ClientFire(float Value)
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self && !bIsSlave)
			return false;
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
			
			NN_TraceFire(0.2);
		}
	}
	return Super.ClientFire(Value);
}

function Fire(float Value)
{
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		GotoState('NormalFire');
		bCanClientFire = true;
		bPointing=True;
		ClientFire(value);
		if ( SlaveEnforcer != None )
			Pawn(Owner).PlayRecoil(2 * FiringSpeed);
		else if ( !bIsSlave )
			Pawn(Owner).PlayRecoil(FiringSpeed);
		TraceFire(0.2);
	}
}

simulated function bool ClientAltFire(float Value)
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot())
			return false;
		if ( (AmmoType == None) && (AmmoName != None) )
		{
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			bPointing=True;
			bCanClientFire = true;
			AltAccuracy = 0.4;
			GotoState('ClientAltFiring');
		}
	}
	if ( bCanClientFire && ((Role == ROLE_Authority) || (AmmoType == None) || (AmmoType.AmmoAmount > 0)) )
	{
		PlayAltFiring();
		if ( Role < ROLE_Authority )
			GotoState('ClientAltFiring');
		return true;
	}
	return false;
}

State ClientActive
{
	simulated function bool ClientFire(float Value)
	{
		if (Owner.IsA('Bot'))
			return Super.ClientFire(Value);
		bForceFire = bbPlayer(Owner) == None || !bbPlayer(Owner).ClientCannotShoot();
		return bForceFire;
	}

	simulated function bool ClientAltFire(float Value)
	{
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(Value);
		bForceAltFire = bbPlayer(Owner) == None || !bbPlayer(Owner).ClientCannotShoot();
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

state ClientFiring
{
	simulated function EndState()
	{
		Super.EndState();
		if (Owner.IsA('Bot'))
			return;
		OldFlashCount = FlashCount;
	}

Begin:
	if (!Owner.IsA('Bot'))
	{
		FlashCount++;
		if ( SlaveEnforcer != none )
			SetTimer(0.20, false);
		FinishAnim();
		if ( bIsSlave )
			GotoState('Idle');
		else 
			ClientFinish();
	}
}

state ClientAltFiring
{
	simulated function BeginState()
	{
		if (!Owner.IsA('Bot'))
			AltAccuracy = 0.4;
		Super.BeginState();
	}
	
	simulated function PlayRepeatFiring()
	{
		if (bNewNet && !Owner.IsA('Bot')) {
			NN_TraceFire(AltAccuracy);
/* 			if (SlaveEnforcer != None)
				ST_enforcer(SlaveEnforcer).NN_TraceFire(AltAccuracy); */
		}
		Global.PlayRepeatFiring();
	}
	
	simulated function AnimEnd()
	{
		Super.AnimEnd();
		if ( AltAccuracy < 3 && !Owner.IsA('Bot') ) 
			AltAccuracy += 0.5;
	}
}

state AltFiring
{
ignores Fire, AltFire, AnimEnd;

Begin:
	if ( SlaveEnforcer != none )
		SetTimer(0.20, false);
	FinishAnim();
Repeater:	
	if (AmmoType.UseAmmo(1))
	{
		FlashCount++;
		if (!bNewNet || Owner.IsA('Bot'))
		{
			if ( SlaveEnforcer != None )
				Pawn(Owner).PlayRecoil(3 * FiringSpeed);
			else if ( !bIsSlave )
				Pawn(Owner).PlayRecoil(1.5 * FiringSpeed);
		}
		TraceFire(AltAccuracy);
		PlayRepeatFiring();
		FinishAnim();
	}

	if ( AltAccuracy < 3 ) 
		AltAccuracy += 0.5;
	if ( bIsSlave )
	{
		if ( (Pawn(Owner).bAltFire!=0) 
			&& AmmoType.AmmoAmount>0 )
			Goto('Repeater');
	}
	else if ( bChangeWeapon )
		GotoState('DownWeapon');
	else if ( (Pawn(Owner).bAltFire!=0) 
		&& AmmoType.AmmoAmount>0 )
	{
		if ( PlayerPawn(Owner) == None )
			Pawn(Owner).bAltFire = int( FRand() < AltReFireRate );
		Goto('Repeater');	
	}
	PlayAnim('T2', 0.9, 0.05);	
	FinishAnim();
	Finish();
}

simulated function ClientFinish()
{
	local Pawn PawnOwner;
	local bool bForce, bForceAlt;
	
	if (Owner.IsA('Bot'))
		return;

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
		
	if ( ((AmmoType != None) && (AmmoType.AmmoAmount<=0)) || (PawnOwner.Weapon != self) )
		GotoState('Idle');
	else if ( (PawnOwner.bFire!=0) || bForce )
		Global.ClientFire(0);
	else if ( (PawnOwner.bAltFire!=0) || bForceAlt )
		Global.ClientAltFire(0);
	else 
		GotoState('Idle');
}

simulated function NN_TraceFire(float Accuracy)
{
	local vector RealOffset;
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z, AimDir;
	local actor Other;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local float R1, R2;
	local int ClientFRVI;
	
	if (Owner.IsA('Bot'))
		return;
		
	yModInit();

	RealOffset = FireOffset;
	FireOffset *= 0.35;
	if ( (SlaveEnforcer != None) || bIsSlave )
		Accuracy = FClamp(2*Accuracy,0.45,3);	// was FClamp(3*Accuracy,0.75,3);
	else if ( Owner.IsA('Bot') && !Bot(Owner).bNovice )
		Accuracy = FMax(Accuracy, 0.45);

	PawnOwner = Pawn(Owner);
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return;
	
	ClientFRVI = bbP.zzNN_FRVI;
	R1 = NN_GetFRV();
	R2 = NN_GetFRV();

	//Owner.MakeNoise(PawnOwner.SoundDampening);
	GetAxes(GV,X,Y,Z);
	StartTrace = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
	//AdjustedAim = PawnOwner.AdjustAim(1000000, StartTrace, 2*AimError, False, False);	
	EndTrace = StartTrace + Accuracy * (R1 - 0.5 )* Y * 1000
		+ Accuracy * (R2 - 0.5 ) * Z * 1000;
	AimDir = vector(GV);
	EndTrace += (10000 * AimDir);
		
	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,PawnOwner);
	NN_ProcessTraceHit(Other, HitLocation, HitNormal, vector(GV),Y,Z);
	
	bbP.xxNN_TakeDamage(Other, class'Enforcer', 0, PawnOwner, HitLocation, 3000.0*X, MyDamageType, -1);
	/*
	if (PawnOwner.bFire != 0)
		bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, vect(0,0,0), bIsSlave, ClientFRVI, Accuracy);
	else
		bbP.xxNN_AltFire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, vect(0,0,0), bIsSlave, ClientFRVI, Accuracy);
	*/
	FireOffset = RealOffset;
}

simulated function float NN_GetFRV()
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return 0;
	
	bbP.zzNN_FRVI++;
	if (bbP.zzNN_FRVI == bbP.FRVI_length)
		bbP.zzNN_FRVI = 0;
	return bbP.GetFRV(bbP.zzNN_FRVI);
}

simulated function NN_ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local UT_Shellcase s;
	local vector realLoc;
	
	if (Owner.IsA('Bot'))
		return;
		
	yModInit();

	realLoc = Owner.Location + CDO;
	s = Spawn(class'UT_ShellCase',, '', realLoc + 20 * X + yMod * Y + Z);
	if ( s != None )
		s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.2+0.2)*Y + (FRand()*0.3+1.0) * Z)*160);              
	if (Other == Level) 
	{
		if ( bIsSlave || (SlaveEnforcer != None) )
		{
			Spawn(class'UT_LightWallHitEffect',Owner,, HitLocation+HitNormal, Rotator(HitNormal));
			if (bbPlayer(Owner) != None)
				bbPlayer(Owner).xxClientDemoFix(None, class'UT_LightWallHitEffect', HitLocation+HitNormal,,, Rotator(HitNormal));
		}
		else
		{
			Spawn(class'UT_WallHit',Owner,, HitLocation+HitNormal, Rotator(HitNormal));
			if (bbPlayer(Owner) != None)
				bbPlayer(Owner).xxClientDemoFix(None, class'UT_WallHit', HitLocation+HitNormal,,, Rotator(HitNormal));
		}
	}
	else if ((Other != self) && (Other != Owner) && (Other != None) ) 
	{
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
		{
			spawn(class'UT_SpriteSmokePuff',Owner,,HitLocation+HitNormal*9);
			if (bbPlayer(Owner) != None)
				bbPlayer(Owner).xxClientDemoFix(None, class'UT_SpriteSmokePuff', HitLocation+HitNormal*9);
		}
	}
}

function TraceFire( float Accuracy )
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;
	local Pawn PawnOwner;
	local vector RealOffset;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
	{
		Super.TraceFire(Accuracy);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (!bNewNet || bbP == None) {
		Super.TraceFire(Accuracy);
		return;
	}

	RealOffset = FireOffset;
	FireOffset *= 0.35;
	if ( (SlaveEnforcer != None) || bIsSlave )
		Accuracy = FClamp(3*Accuracy,0.75,3);
	else if ( Owner.IsA('Bot') && !Bot(Owner).bNovice )
		Accuracy = FMax(Accuracy, 0.45);

	PawnOwner = Pawn(Owner);

	Owner.MakeNoise(PawnOwner.SoundDampening);
	GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
	StartTrace = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
	AdjustedAim = PawnOwner.AdjustAim(1000000, StartTrace, 2*AimError, False, False);	
	EndTrace = StartTrace + Accuracy * (FRand() - 0.5 )* Y * 1000
		+ Accuracy * (FRand() - 0.5 ) * Z * 1000;
	X = vector(AdjustedAim);
	EndTrace += (10000 * X); 
	Other = PawnOwner.TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
	Other = bbP.zzNN_HitActor;
	if (Pawn(Other) != None && FastTrace(Other.Location))
		HitLocation += (bbP.zzNN_HitLoc - Other.Location);
	ProcessTraceHit(Other, HitLocation, HitNormal, X,Y,Z);
	FireOffset = RealOffset;
}

function float GetFRV()
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return 0;
	
	bbP.zzFRVI++;
	if (bbP.zzFRVI == bbP.FRVI_length)
		bbP.zzFRVI = 0;
	return bbP.GetFRV(bbP.zzFRVI);
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local vector realLoc;
	local Pawn PawnOwner;
	
	if (Owner.IsA('Bot'))
	{
		Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		return;
	}
		
	yModInit();

	PawnOwner = Pawn(Owner);

	realLoc = Owner.Location + CalcDrawOffset();
	DoShellCase(PlayerPawn(Owner), realLoc + 20 * X + FireOffset.Y * Y + Z, X,Y,Z);          
	if (Other == Level) 
	{
		if ( bIsSlave || (SlaveEnforcer != None) )
			Spawn(class'NN_UT_LightWallHitEffectOwnerHidden',Owner,, HitLocation+HitNormal, Rotator(HitNormal));
		else
			Spawn(class'NN_UT_WallHitOwnerHidden',Owner,, HitLocation+HitNormal, Rotator(HitNormal));
	}
	else if ((Other != self) && (Other != Owner) && (Other != None) ) 
	{
		if ( FRand() < 0.2 )
			X *= 5;
		if (!bNewNet) {
			if (HitDamage > 0)
				Other.TakeDamage(HitDamage, PawnOwner, HitLocation, 3000.0*X, MyDamageType);
			else
				Other.TakeDamage(class'UTPure'.default.EnforcerDamagePri, PawnOwner, HitLocation, 3000.0*X, MyDamageType);
		}
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			spawn(class'NN_UT_SpriteSmokePuffOwnerHidden',Owner,,HitLocation+HitNormal*9);
		else
			Other.PlaySound(Sound 'ChunkHit',, 4.0,,100);
	}
}

simulated function DoShellCase(PlayerPawn Pwner, vector HitLoc, Vector X, Vector Y, Vector Z)
{
	local PlayerPawn P;
	local Actor CR;
	local UT_Shellcase s;
	
	if (Owner.IsA('Bot'))
		return;

	if (RemoteRole < ROLE_Authority) {
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
		{
			if (P != Pwner) {
				CR = P.Spawn(class'UT_ShellCase',P, '', HitLoc);
				CR.bOnlyOwnerSee = True;
				s = UT_Shellcase(CR);
				if ( s != None )
					s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.2+0.2)*Y + (FRand()*0.3+1.0) * Z)*160);    
			}
		}
	}
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'enforcer');
}

simulated function PlaySelect ()
{
	Class'NN_WeaponFunctions'.static.PlaySelect( self);
}

simulated function TweenDown ()
{
	Class'NN_WeaponFunctions'.static.TweenDown( self);
}

simulated function AnimEnd ()
{
	Class'NN_WeaponFunctions'.static.AnimEnd( self);
}

function DropFrom(vector StartLocation)
{
	if ( !SetLocation(StartLocation) )
		return; 
	if ( SlaveEnforcer != None )
	{
		SlaveEnforcer.SetOwner(None);
		SlaveEnforcer.bIsSlave = false;
		SlaveEnforcer.AmmoType = None;
		SlaveEnforcer.Velocity = Velocity;
		SlaveEnforcer.bTossedOut = true;
		SlaveEnforcer.PickupAmmoCount = 30;
		AmmoType.AmmoAmount -= SlaveEnforcer.PickupAmmoCount;
		SlaveEnforcer.DropFrom(StartLocation);
		SlaveEnforcer = None;
		Velocity = vect(0,0,0);
		bTossedOut = false;
		return;
	}
	AIRating = Default.AIRating;
	
	bCanClientFire = false;
	bSimFall = true;
	SimAnim.X = 0;
	SimAnim.Y = 0;
	SimAnim.Z = 0;
	SimAnim.W = 0;
	if ( !SetLocation(StartLocation) )
		return; 
	AIRating = Default.AIRating;
	bMuzzleFlash = 0;
	if ( AmmoType != None )
	{
		if (bbPlayer(Owner) != None && bbPlayer(Owner).FindInventoryType(class'ST_minigun2') == None )
		{
			PickupAmmoCount = AmmoType.AmmoAmount;
			AmmoType.AmmoAmount = 0;
		}
		else
		{
			PickupAmmoCount = AmmoType.AmmoAmount / 2;
			AmmoType.AmmoAmount -= PickupAmmoCount;
		}
	}
	RespawnTime = 0.0; //don't respawn
	SetPhysics(PHYS_Falling);
	RemoteRole = ROLE_DumbProxy;
	BecomePickup();
	NetPriority = 2.5;
	bCollideWorld = true;
	if ( Pawn(Owner) != None )
		Pawn(Owner).DeleteInventory(self);
	Inventory = None;
	GotoState('PickUp', 'Dropped');
}

simulated function PlayFiring()
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
	{
		Super.PlayFiring();
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (Level.NetMode == NM_Client && bbP != None)
		bbP.PlayOwnedSound(FireSound, SLOT_None,2.0*Pawn(Owner).SoundDampening);
	else
		PlayOwnedSound(FireSound, SLOT_None,2.0*Pawn(Owner).SoundDampening);
	bMuzzleFlash++;
	PlayAnim('Shoot',0.5 + 0.31 * FireAdjust, 0.02);
}

simulated function PlayRepeatFiring()
{
	if (Owner.IsA('Bot'))
	{
		Super.PlayRepeatFiring();
		return;
	}
	if ( Affector != None )
		Affector.FireEffect();
	if ( PlayerPawn(Owner) != None && (!bNewNet || Level.NetMode == NM_Client) )
	{
		PlayerPawn(Owner).ClientInstantFlash( -0.2, vect(325, 225, 95));
		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
	}
	bMuzzleFlash++;
	PlayOwnedSound(FireSound, SLOT_None,2.0*Pawn(Owner).SoundDampening);
	PlayAnim('Shot2', 0.7 + 0.3 * FireAdjust, 0.05);
}

state Active
{
	function Fire(float F) 
	{
		if (Owner.IsA('Bot'))
		{
			Super.Fire(F);
			return;
		}
		if (F > 0 && bbPlayer(Owner) != None)
			Global.Fire(F);
	}
	function AltFire(float F) 
	{
		if (Owner.IsA('Bot'))
		{
			Super.AltFire(F);
			return;
		}
		if (F > 0 && bbPlayer(Owner) != None)
			Global.AltFire(F);
	}
}

auto state Pickup
{
	ignores AnimEnd;
	
	simulated function Landed(Vector HitNormal)
	{
		Super(Inventory).Landed(HitNormal);
	}
}

simulated function TweenToStill()
{
	if ( Mesh == PickupViewMesh )
		return;
	Super.TweenToStill();
}

defaultproperties
{
     bNewNet=True
	 ClipCount=20
}