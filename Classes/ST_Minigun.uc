//=============================================================================
// ST_Minigun.
//=============================================================================
class ST_Minigun extends ST_UnrealWeapons;

var float ShotAccuracy, LastShellSpawn;
var int Count;
var bool bOutOfAmmo, bFiredShot;
var float FireInterval, NextFireInterval;
var int HitCounter;

function float RateSelf( out int bUseAltMode )
{
	local float dist;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;

	if ( Pawn(Owner).Enemy == None )
	{
		bUseAltMode = 0;
		return AIRating;
	}

	dist = VSize(Pawn(Owner).Enemy.Location - Owner.Location); 
	bUseAltMode = 1;
	if ( dist > 1200 )
	{
		if ( dist > 1700 )
			bUseAltMode = 0;
		return (AIRating * FMin(Pawn(Owner).DamageScaling, 1.5) + FMin(0.0001 * dist, 0.3)); 
	}
	AIRating *= FMin(Pawn(Owner).DamageScaling, 1.5);
	return AIRating;
}

function Fire( float Value )
{
	if ( AmmoType == None )
	{
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		SoundVolume = 255*Pawn(Owner).SoundDampening;
		bCanClientFire = true;
		CheckVisibility();
		bPointing=True;
		ShotAccuracy = 0.2;
		FireInterval = 0.120;
		NextFireInterval = 0.111;
		ClientFire(value);
		if (!bNewNet)
			Pawn(Owner).PlayRecoil(FiringSpeed);
		if (Owner.IsA('Bot'))
			Pawn(Owner).PlayRecoil(FiringSpeed);
		GotoState('NormalFire');
	}
	else GoToState('Idle');
}

function AltFire( float Value )
{
	if ( AmmoType == None )
	{
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		bPointing=True;
		bCanClientFire = true;
		CheckVisibility();
		ShotAccuracy = 0.95;
		FireInterval = 0.120;
		NextFireInterval = 0.111;
		SoundVolume = 255*Pawn(Owner).SoundDampening;	
		ClientAltFire(value);
		if (!bNewNet)
			Pawn(Owner).PlayRecoil(FiringSpeed);
		if (Owner.IsA('Bot'))
			Pawn(Owner).PlayRecoil(FiringSpeed);
		GoToState('AltFiring');		
	}
	else GoToState('Idle');	
}

simulated function bool ClientFire(float Value)
{
	local bbPlayer bbP;

	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false;
		if ( AmmoType == None )
		{
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			SoundVolume = 255*Pawn(Owner).SoundDampening;
			Pawn(Owner).PlayRecoil(FiringSpeed);
			bCanClientFire = true;
			CheckVisibility();
			bPointing=True;
			ShotAccuracy = 0.2;
			FireInterval = 0.120;
			NextFireInterval = 0.111;
			GotoState('ClientFiring');
		}
		else GoToState('Idle');
	}
	return Super.ClientFire(Value);
}

simulated function bool ClientAltFire( float Value )
{
	local bbPlayer bbP;

	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false;
		if ( AmmoType == None )
		{
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			bPointing=True;
			bCanClientFire = true;
			CheckVisibility();
			ShotAccuracy = 0.95;
			FireInterval = 0.120;
			NextFireInterval = 0.111;
			Pawn(Owner).PlayRecoil(FiringSpeed);
			SoundVolume = 255*Pawn(Owner).SoundDampening;
			GoToState('ClientAltFiring');		
		}
		else GoToState('Idle');	
	}
	return Super.ClientAltFire(Value);
}

function GenerateBullet()
{
	if ( LightType == LT_None )
		LightType = LT_Steady;
	else
		LightType = LT_None;
	bFiredShot = true;
	if ( AmmoType.UseAmmo(1) ) 
		TraceFire(ShotAccuracy);
	else
		GotoState('FinishFire');
}

simulated function NN_GenerateBullet()
{
	if (Owner.IsA('Bot'))
		return;
	if ( LightType == LT_None )
		LightType = LT_Steady;
	else
		LightType = LT_None;
	bFiredShot = true;
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ClientInstantFlash( -0.2, vect(325, 225, 95));
	if ( AmmoType.AmmoAmount > 0 ) 
		NN_TraceFire(ShotAccuracy);
	else
		GotoState('ClientFinish');
}

simulated function NN_TraceFire( float Accuracy )
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z, AimDir;
	local actor Other;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local float R1, R2;
	local int ClientFRVI;
    local MTracer MT;
	
	if (Owner.IsA('Bot'))
		return;
		
	yModInit();

	PawnOwner = Pawn(Owner);
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return;
	
	ClientFRVI = bbP.zzNN_FRVI;
	R1 = NN_GetFRV();
	R2 = NN_GetFRV();
	
	if (bbP.bAltFire != 0)
		Accuracy = 0.95;
	else if (bbP.bFire != 0)
		Accuracy = 0.2;
	
	GetAxes(GV,X,Y,Z);
	StartTrace = Owner.Location + CDO + yMod * Y + FireOffset.Z * Z; 
	EndTrace = StartTrace + Accuracy * (R1 - 0.5 )* Y * 1000
		+ Accuracy * (R2 - 0.5 ) * Z * 1000;
	AimDir = vector(GV);
	EndTrace += (10000 * AimDir);
	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,PawnOwner);
	
	if (PawnOwner.bFire != 0)
		bbP.xxNN_TakeDamage(Other, class'Minigun2', 0, PawnOwner, HitLocation, 3500.0*X, MyDamageType, -1);
	else
		bbP.xxNN_TakeDamage(Other, class'Minigun2', 1, PawnOwner, HitLocation, 5000.0*X, MyDamageType, -1);

	NN_ProcessTraceHit(Other, HitLocation, HitNormal, vector(GV),Y,Z);
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
	if (Owner.IsA('Bot'))
		return;
	if (Other == Level) 
	{
		Spawn(class'UT_LightWallHitEffect',,, HitLocation+HitNormal, Rotator(HitNormal));
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxClientDemoFix(None, class'UT_LightWallHitEffect', HitLocation+HitNormal,,, Rotator(HitNormal));
	}
	else if ( (Other!=self) && (Other!=Owner) && (Other != None) ) 
	{
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9); 
	}
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

state NormalFire
{
	function Tick( float DeltaTime )
	{
		local Pawn P;

		if (Owner.IsA('Bot'))
		{
			if (Owner==None) 
				AmbientSound = None;
		}

		P = Pawn(Owner);

		if (P == None)
			return;
	
		if (P.Weapon != Self)
			AmbientSound = None;

		FireInterval -= DeltaTime;
		while (FireInterval < 0.0)
		{
			FireInterval += NextFireInterval;
			if (P.bAltFire == 0)
				GenerateBullet();
		}

		if	( bFiredShot && ((P.bFire==0) || bOutOfAmmo) ) 
			GoToState('FinishFire');
	}

	function AnimEnd()
	{
		if (Pawn(Owner).Weapon != self) GotoState('');
		else if (Pawn(Owner).bFire!=0 && AmmoType.AmmoAmount>0)
		{
			if ( (PlayerPawn(Owner) != None) || (FRand() < ReFireRate) )
				Global.Fire(0);
			else 
			{
				Pawn(Owner).bFire = 0;
				GotoState('FinishFire');
			}
		}
		else if ( Pawn(Owner).bAltFire!=0 && AmmoType.AmmoAmount>0)
			Global.AltFire(0);
		else 
			GotoState('FinishFire');
		if ( AmbientSound == None )
		{
			AmbientSound = FireSound;
		}
		if ( Affector != None )
			Affector.FireEffect();
	}

	function BeginState()
	{
		AmbientSound = FireSound;
		bSteadyFlash3rd = true;
		Super.BeginState();
	}

	function EndState()
	{
		bSteadyFlash3rd = false;
		LightType = LT_None;
		AmbientSound = None;
		Super.EndState();
	}

Begin:
	if (Owner.IsA('Bot'))
	{
		Sleep(0.13);
		GenerateBullet();
		Goto('Begin');
	}
/* 
	Sleep(0.13);
	GenerateBullet();
	Goto('Begin');
 */
}

state AltFiring
{
	function Tick( float DeltaTime )
	{
		local Pawn P;
		
		if (Owner.IsA('Bot'))
		{
			if (Owner==None) 
			{
				AmbientSound = None;
				GotoState('Pickup');
			}			

			if	( bFiredShot && ((pawn(Owner).bAltFire==0) || bOutOfAmmo) ) 
				GoToState('FinishFire');
		}

		P = Pawn(Owner);

		if (P == None)
			return;

		if (P.Weapon != Self)
			AmbientSound = None;

		FireInterval -= DeltaTime;
		while (FireInterval < 0.0)
		{
			FireInterval += NextFireInterval;
			if (P.bFire == 0)
				GenerateBullet();
		}

		if	( bFiredShot && ((P.bAltFire==0) || bOutOfAmmo) ) 
			GoToState('FinishFire');
	}

	function AnimEnd()
	{
		if ( (AnimSequence != 'Shoot2') || !bAnimLoop )
		{
			AmbientSound = AltFireSound;
			LoopAnim('Shoot2',1.9);
			SoundVolume = 255*Pawn(Owner).SoundDampening;
			NextFireInterval = 0.08;
		}
		else if ( AmbientSound == None )
			AmbientSound = FireSound;
		if ( Affector != None )
			Affector.FireEffect();
	}
	
	function BeginState()
	{
		AmbientSound = FireSound;
		bFiredShot = false;
		Super.BeginState();
		bSteadyFlash3rd = true;
	}

	function EndState()
	{
		bSteadyFlash3rd = false;
		LightType = LT_None;
		AmbientSound = None;
		Super.EndState();
	}

Begin:
	if (Owner.IsA('Bot'))
	{
		Sleep(0.13);
		GenerateBullet();
		if ( AnimSequence == 'Shoot2' )
			Goto('FastShoot');
		Goto('Begin');
	}
/*
	Sleep(0.13);
	GenerateBullet();
	if ( AnimSequence == 'Shoot2' )
		Goto('FastShoot');
	Goto('Begin');
 */
FastShoot:
	if (Owner.IsA('Bot'))
	{
		Sleep(0.08);
		GenerateBullet();
		Goto('FastShoot');
	}
/*
	Sleep(0.08);
	GenerateBullet();
	Goto('FastShoot');
 */
}

state ClientFiring
{
	simulated function bool ClientFire(float F) {}
	simulated function bool ClientAltFire(float F) {}

	simulated function Tick( float DeltaTime )
	{
		local Pawn P;
		
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}

		P = Pawn(Owner);

		if (P == None)
			return;
	
		if (P.Weapon != Self)
			AmbientSound = None;

		FireInterval -= DeltaTime;
		while (FireInterval < 0.0)
		{
			FireInterval += NextFireInterval;
			if (P.bAltFire == 0)
				NN_GenerateBullet();
		}

		if	( bFiredShot && ((P.bFire==0) || bOutOfAmmo) ) 
			GoToState('ClientFinish');
	}

	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (AmmoType.AmmoAmount <= 0) )
		{
			PlayUnwind();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else if ( Pawn(Owner).bAltFire != 0 )
			Global.ClientAltFire(0);
		else
		{
			PlayUnwind();
			GotoState('ClientFinish');
		}
	}

	simulated function BeginState()
	{
		bSteadyFlash3rd = true;
		AmbientSound = FireSound;
	}
	
	simulated function EndState()
	{
		if (!Owner.IsA('Bot'))
			LightType = LT_None;
		bSteadyFlash3rd = false;
		Super.EndState();
	}
}

state ClientAltFiring
{
	simulated function bool ClientFire(float F) {}
	simulated function bool ClientAltFire(float F) {}

	simulated function Tick( float DeltaTime )
	{
		local Pawn P;
		
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}

		P = Pawn(Owner);

		if (P == None)
			return;

		if (P.Weapon != Self)
			AmbientSound = None;

		FireInterval -= DeltaTime;
		while (FireInterval < 0.0)
		{
			FireInterval += NextFireInterval;
			if (P.bFire == 0)
				NN_GenerateBullet();
		}

		if	( bFiredShot && ((P.bAltFire==0) || bOutOfAmmo) ) 
			GoToState('ClientFinish');
	}
	
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (AmmoType.AmmoAmount <= 0) )
		{
			PlayUnwind();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner).bAltFire != 0 )
		{
			if ( (AnimSequence != 'Shoot2') || !bAnimLoop )
			{	
				SoundVolume = 255*Pawn(Owner).SoundDampening;
				AmbientSound = AltFireSound;
				PlayAnim('Shoot2',1.9);
			}
			else if ( AmbientSound == None )
				AmbientSound = FireSound;
			if ( Affector != None )
				Affector.FireEffect();
			if ( PlayerPawn(Owner) != None )
				PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
		}
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else
		{
			PlayUnwind();
			bSteadyFlash3rd = false;
			GotoState('ClientFinish');
		}
	}

	simulated function BeginState()
	{
		bSteadyFlash3rd = true;
		AmbientSound = FireSound;
	}
	
	simulated function EndState()
	{
		if (!Owner.IsA('Bot'))
			LightType = LT_None;
		bSteadyFlash3rd = false;
		Super.EndState();
	}
Begin:
}

state FinishFire
{
	function Fire(float F) {}
	function AltFire(float F) {}

	function ForceFire()
	{
		bForceFire = true;
	}

	function ForceAltFire()
	{
		bForceAltFire = true;
	}

	function BeginState()
	{
		PlayUnwind();
	}

Begin:
	FinishAnim();
	Finish();
}

state ClientFinish
{
	simulated function bool ClientFire(float Value)
	{
		bForceFire = bForceFire || ( bCanClientFire && (Pawn(Owner) != None) && (AmmoType.AmmoAmount > 0) );
		return bForceFire;
	}

	simulated function bool ClientAltFire(float Value)
	{
		bForceAltFire = bForceAltFire || ( bCanClientFire && (Pawn(Owner) != None) && (AmmoType.AmmoAmount > 0) );
		return bForceAltFire;
	}

	simulated function AnimEnd()
	{
		if ( bCanClientFire && (PlayerPawn(Owner) != None) && (AmmoType.AmmoAmount > 0) )
		{
			if ( bForceFire || (Pawn(Owner).bFire != 0) )
			{
				Global.ClientFire(0);
				return;
			}
			else if ( bForceAltFire || (Pawn(Owner).bAltFire != 0) )
			{
				Global.ClientAltFire(0);
				return;
			}
		}			
		GotoState('');
		Global.AnimEnd();
	}

	simulated function EndState()
	{
		bSteadyFlash3rd = false;
		bForceFire = false;
		bForceAltFire = false;
		AmbientSound = None;
	}

	simulated function BeginState()
	{
		if (Owner.IsA('Bot'))
			return;
		if (PlayerPawn(Owner).bFire != 0)
			GotoState('ClientFiring');
		else if (PlayerPawn(Owner).bAltFire != 0)
			GotoState('ClientAltFiring');
		
		PlayUnwind();
		bSteadyFlash3rd = false;
		bForceFire = false;
		bForceAltFire = false;
	}

Begin:
	FinishAnim();
	NN_Finish();
}

State ClientDown
{
	simulated function AnimEnd()
	{
		local TournamentPlayer T;
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}

		T = TournamentPlayer(Owner);
		if ( T != None )
		{
			if ( (T.ClientPending != None) 
				&& (T.ClientPending.Owner == Owner) )
			{
				T.Weapon = T.ClientPending;
				T.Weapon.GotoState('ClientActive');
				T.ClientPending = None;
				GotoState('');
			}
			else
			{
				T.NeedActivate();
			}
		}
	}
	simulated function BeginState();
}

simulated function NN_Finish()
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
		GotoState('ClientDown');
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

function TraceFire( float Accuracy )
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z, AimDir;
	local actor Other;
	local bbPlayer bbP;
	local float R1, R2;

	bbP = bbPlayer(Owner);
	if (!bNewNet || bbP == None) {
		Super.TraceFire(Accuracy);
		return;
	}
	
	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
	StartTrace = Owner.Location + CalcDrawOffset() + FireOffset.Y * Y + FireOffset.Z * Z; 
	AdjustedAim = pawn(owner).AdjustAim(1000000, StartTrace, 2.75*AimError, False, False);	
	R1 = NN_GetFRV();
	R2 = NN_GetFRV();
	EndTrace = StartTrace + Accuracy * (R1 - 0.5 )* Y * 1000
		+ Accuracy * (R2 - 0.5 ) * Z * 1000;
	AimDir = vector(AdjustedAim);
	EndTrace += (10000 * AimDir); 
	Other = Pawn(Owner).TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
	Other = bbP.zzNN_HitActor;
	if (Pawn(Other) != None && FastTrace(Other.Location))
		HitLocation += (bbP.zzNN_HitLoc - Other.Location);
	
	ProcessTraceHit(Other, HitLocation, HitNormal, vector(AdjustedAim),Y,Z);
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local int rndDam;
	local Pawn PawnOwner;

	PawnOwner = Pawn(Owner);

	if (Other == Level) 
		Spawn(class'NN_UT_LightWallHitEffectOwnerHidden',Owner,, HitLocation+HitNormal, Rotator(HitNormal));
	else if ( (Other!=self) && (Other!=Owner) && (Other != None) ) 
	{

		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			spawn(class'NN_UT_SpriteSmokePuffOwnerHidden',Owner,,HitLocation+HitNormal*9); 
		else
			Other.PlaySound(Sound 'ChunkHit',, 4.0,,100);

		if ( Other.IsA('Bot') && (FRand() < 0.2) )
			Pawn(Other).WarnTarget(PawnOwner, 500, X);
		if (PlayerPawn(Owner).bAltFire != 0)
			rndDam = 10;
		else
			rndDam = 7;
		if ( FRand() < 0.2 )
			X *= 2.5;
		if (!bNewNet)
			Other.TakeDamage(rndDam, PawnOwner, HitLocation, rndDam*500.0*X, MyDamageType);
		if (Owner.IsA('Bot'))
			Other.TakeDamage(rndDam, PawnOwner, HitLocation, rndDam*500.0*X, MyDamageType);
	}

	if (Pawn(Other) != None && Other != Owner && Pawn(Other).Health > 0)
	{
		HitCounter++;
		if (HitCounter == 8)
		{
			HitCounter = 0;
		}
	}
	else
		HitCounter = 0;
}

state Idle
{

Begin:
	if (Pawn(Owner).bFire!=0 && AmmoType.AmmoAmount>0) Fire(0.0);
	if (Pawn(Owner).bAltFire!=0 && AmmoType.AmmoAmount>0) AltFire(0.0);	
	LoopAnim('Idle',0.2,0.9);
	bPointing=False;
	if ( (AmmoType != None) && (AmmoType.AmmoAmount<=0) ) 
		Pawn(Owner).SwitchToBestWeapon();
	Disable('AnimEnd');	
}

simulated function PlayFiring()
{  
	PlayAnim('Shoot1',0.8, 0.05);
}

simulated function PlayAltFiring()
{
	PlayAnim('Shoot1',0.8, 0.05);
}

simulated function PlayUnwind()
{
	if ( Owner != None )
	{
		PlayOwnedSound(Misc1Sound, SLOT_Misc, 3.0*Pawn(Owner).SoundDampening);  //Finish firing, power down    
		PlayAnim('UnWind',0.8, 0.05);
	}
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'minigun2');
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

simulated function PlayIdleAnim()
{
	if ( Mesh == PickupViewMesh )
		return;
	LoopAnim('Still',1.0,0.05);
}

simulated function TweenToStill()
{
	if ( Mesh == PickupViewMesh )
		return;
	Super.TweenToStill();
}

defaultproperties
{
	FireInterval=0.120000
	NextFireInterval=0.111000
	WeaponDescription="Classification: Gatling Gun\n\nPrimary Fire: Steady Stream of bullets, fast, accurate.\n\nSecondary Fire: More rapid, but less accurate stream of bullets.\n\nTechniques: Secondary fire is much more useful at close range, but can eat up tons of ammunition."
	AmmoName=Class'ST_ShellBox'
	PickupAmmoCount=50
	bInstantHit=True
	bAltInstantHit=True
	FireOffset=(X=0.00,Y=-5.00,Z=-4.00),
    shakemag=135.00
    shakevert=8.00
	shaketime=0.10
	AIRating=0.60
	RefireRate=0.90
	AltRefireRate=0.93
	FireSound=Sound'UnrealI.Minigun.RegF1'
	AltFireSound=Sound'UnrealI.Minigun.AltF1'
	SelectSound=Sound'UnrealI.Minigun.MiniSelect'
	Misc1Sound=Sound'UnrealI.Minigun.WindD2'
	DeathMessage="%k's %w turned %o into a leaky piece of meat."
	AutoSwitchPriority=7
	InventoryGroup=7
	PickupMessage="You got the Minigun"
	ItemName="Minigun"
	PlayerViewOffset=(X=5.60,Y=-1.50,Z=-1.80),
	PlayerViewMesh=LodMesh'UnrealI.minigunM'
	PickupViewMesh=LodMesh'UnrealI.minipick'
	ThirdPersonMesh=LodMesh'UnrealI.SMini3'
	StatusIcon=Texture'UseM'
	Icon=Texture'UseM'
	Mesh=LodMesh'UnrealI.minipick'
	SoundRadius=64
	SoundVolume=255
	CollisionRadius=28.00
	CollisionHeight=8.00
	LightEffect=13
	LightBrightness=250
	LightHue=28
	LightSaturation=32
	LightRadius=6
	bClientAnim=True
}