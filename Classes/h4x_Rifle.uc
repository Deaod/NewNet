class h4x_Rifle expands TournamentWeapon;

#exec AUDIO IMPORT FILE="Sounds\BLAM.WAV" NAME="BLAM" GROUP="Rifle"

var ST_Mutator STM;
var bool bNewNet;		// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;
var int zzWin;
var string Allow55;
var float HitDamage;
var float HeadDamage;
var float BodyHeight;

var int NumFire;
var name FireAnims[5];
var vector OwnerLocation;
var float StillTime, StillStart;
var bool bZoom, bFinishZooming;

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
		else if (bbP.bAltFire != 0 && !bFinishZooming)
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

simulated event PostNetBeginPlay()
{
	local h4x_HUDMutator crosshair;
	local PlayerPawn HUDOwner;

	Super.PostNetBeginPlay();


	HUDOwner = PlayerPawn(Owner);
	if (HUDOwner != None && HUDOwner.IsA('bbPlayer') && HUDOwner.myHUD != None)
	{
		ForEach AllActors(Class'h4x_HUDMutator', crosshair)
			break;
		if (crosshair == None)
		{
			crosshair = Spawn(Class'h4x_HUDMutator', Owner);
			crosshair.RegisterHUDMutator();
			crosshair.HUDOwner = HUDOwner;
		}
	}
}


function float RateSelf( out int bUseAltMode )
{
	local float dist;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;

	bUseAltMode = 0;
	if ( (Bot(Owner) != None) && Bot(Owner).bSniping )
		return AIRating + 1.15;
	if (  Pawn(Owner).Enemy != None )
	{
		dist = VSize(Pawn(Owner).Enemy.Location - Owner.Location);
		if ( dist > 1200 )
		{
			if ( dist > 2000 )
				return (AIRating + 0.75);
			return (AIRating + FMin(0.0001 * dist, 0.45));
		}
	}
	return AIRating;
}

function setHand(float Hand)
{
	Super.SetHand(Hand);
	if ( Hand == 1 )
	{
		Mesh = mesh(DynamicLoadObject("Botpack.Rifle2mL", class'Mesh'));
	}
	else
	{
		Mesh = mesh'Rifle2m';

	}
}

simulated function PlayFiring()
{
	local int r;

	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*3.0);
	if ( (Owner.Physics != PHYS_Falling && Owner.Physics != PHYS_Swimming && Pawn(Owner).bDuck != 0)
	   || Owner.Velocity == 0 * Owner.Velocity )
		PlayAnim(FireAnims[/*Rand(5)*/4],3 + 3 * FireAdjust, 0.05);
	else
		PlayAnim(FireAnims[Rand(5)],0.3 + 0.3 * FireAdjust, 0.05);

	if ( (PlayerPawn(Owner) != None)
		&& (PlayerPawn(Owner).DesiredFOV == PlayerPawn(Owner).DefaultFOV) )
		bMuzzleFlash++;
}

simulated function bool ClientFire(float Value)
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
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
			NN_TraceFire(0);
		}
	}
	return Super.ClientFire(Value);
}

simulated function bool ClientAltFire( float Value )
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	//if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
	//	return false;
	GotoState('Zooming');
	return true;
}

function Fire( float Value )
{
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;
	
	bbPlayer(Owner).xxAddFired(zzWin);
	
	if ( (AmmoType == None) && (AmmoName != None) )
	{

		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		GotoState('NormalFire');
		bPointing=True;
		bCanClientFire = true;
		ClientFire(Value);
		if ( Owner.IsA('Bot') )
		{
			if ( Bot(Owner).bSniping && (FRand() < 0.65) )
				AimError = AimError/FClamp(StillTime, 1.0, 8.0);
			else if ( VSize(Owner.Location - OwnerLocation) < 6 )
				AimError = AimError/FClamp(0.5 * StillTime, 1.0, 3.0);
			else
				StillTime = 0;
		}
		if ( !bNewNet && ( bRapidFire || (FiringSpeed > 0) ))
			Pawn(Owner).PlayRecoil(FiringSpeed);
		TraceFire(0);
		AimError = Default.AimError;
		ClientFire(Value);
	}
}

function AltFire( float Value )
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;
	ClientAltFire(Value);
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

state NormalFire
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
	function EndState()
	{
		Super.EndState();
		OldFlashCount = FlashCount;
	}

Begin:
		FlashCount++;
}

function Timer()
{
	local actor targ;
	local float bestAim, bestDist;
	local vector FireDir;
	local Pawn P;

	bestAim = 0.95;
	P = Pawn(Owner);
	if ( P == None )
	{
		GotoState('');
		return;
	}
	if ( VSize(P.Location - OwnerLocation) < 6 )
		StillTime += FMin(2.0, Level.TimeSeconds - StillStart);

	else
		StillTime = 0;
	StillStart = Level.TimeSeconds;
	OwnerLocation = P.Location;
	FireDir = vector(P.ViewRotation);
	targ = P.PickTarget(bestAim, bestDist, FireDir, Owner.Location);
	if ( Pawn(targ) != None )
	{
		SetTimer(1 + 4 * FRand(), false);
		bPointing = true;
		Pawn(targ).WarnTarget(P, 200, FireDir);
	}
	else
	{
		SetTimer(0.4 + 1.6 * FRand(), false);
		if ( (P.bFire == 0) && (P.bAltFire == 0) )
			bPointing = false;
	}
}

simulated function bool NN_ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z, float yMod)
{
	local UT_Shellcase s;
	local Pawn PawnOwner;
	local float CH;
	
	if (Owner.IsA('Bot'))
		return false;

	PawnOwner = Pawn(Owner);

	s = Spawn(class'UT_ShellCase',, '', Owner.Location + CDO + 30 * X + (2.8 * yMod+5.0) * Y - Z * 1);
	if ( s != None ) 
	{
		s.DrawScale = 2.0;
		s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.2+0.2)*Y + (FRand()*0.3+1.0) * Z)*160);              
	}
	if (Other == Level || Other.IsA('Mover'))
	{
		Spawn(class'UT_HeavyWallHitEffect',,, HitLocation+HitNormal, Rotator(HitNormal));
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxClientDemoFix(None, class'UT_HeavyWallHitEffect', HitLocation+HitNormal,,, Rotator(HitNormal));
		//if (Other.IsA('Mover')) {
		//	if (HitDamage > 0)
		//		bbPlayer(Owner).xxMover_TakeDamage(Mover(Other), HitDamage, Pawn(Owner), HitLocation, 30000.0 * X, MyDamageType);
		//	else
		//		bbPlayer(Owner).xxMover_TakeDamage(Mover(Other), class'UTPure'.default.SniperDamagePri, Pawn(Owner), HitLocation, 30000.0 * X, MyDamageType);
		//}
	}
	else if ( (Other != self) && (Other != Owner) && (Other != None) )
	{
		if ( Other.bIsPawn )
		{
			if ((Other.GetAnimGroup(Other.AnimSequence) == 'Ducking') && (Other.AnimFrame > -0.03)) {
				CH = 0.3 * Other.CollisionHeight;
				return false; // disable crouching headshot
			} else {
				CH = Other.CollisionHeight;
			}
			
			if (HitLocation.Z - Other.Location.Z > BodyHeight * CH)
				return true;
		}
		
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9);	
	}
	return false;
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local UT_Shellcase s;
	local Pawn PawnOwner, POther;
	local PlayerPawn PPOther;
	local vector HeadHitLocation, HeadHitNormal;
	local actor Head;
	local int ArmorAmount;
	local inventory inv;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
	{
		Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP == None || !bNewNet)
	{
		Super.ProcessTraceHit(Other, HitLocation, HitNormal, X,Y,Z);
		return;
	}
	
	if (bbPlayer(Owner) != None && !bbPlayer(Owner).xxConfirmFired(24))
		return;

	PawnOwner = Pawn(Owner);
	POther = Pawn(Other);
	PPOther = PlayerPawn(Other);
	if (STM != None)
		STM.PlayerFire(PawnOwner, 18);		// 18 = Sniper

	if (bNewNet)
		s = Spawn(class'NN_UT_ShellCaseOwnerHidden',Owner, '', Owner.Location + CalcDrawOffset() + 30 * X + (2.8 * FireOffset.Y+5.0) * Y - Z * 1);
	else
		s = Spawn(class'UT_ShellCase',, '', Owner.Location + CalcDrawOffset() + 30 * X + (2.8 * FireOffset.Y+5.0) * Y - Z * 1);
	if ( s != None ) 
	{
		s.DrawScale = 2.0;
		s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.2+0.2)*Y + (FRand()*0.3+1.0) * Z)*160);              
	}
	if (Other == Level)
	{
		if (bNewNet)
			Spawn(class'NN_UT_HeavyWallHitEffectOwnerHidden',Owner,, HitLocation+HitNormal, Rotator(HitNormal));
		else
			Spawn(class'UT_HeavyWallHitEffect',,, HitLocation+HitNormal, Rotator(HitNormal));
	}
	else if ( (Other != self) && (Other != Owner) && (Other != None) )
	{
		if ( Other.bIsPawn )
			Other.PlaySound(Sound 'ChunkHit',, 4.0,,100);
		
		if ( (bbP.zzbNN_Special || !bNewNet &&
			Other.bIsPawn && (HitLocation.Z - Other.Location.Z > BodyHeight * Other.CollisionHeight) 
			&& (instigator.IsA('PlayerPawn') || (instigator.IsA('Bot') && !Bot(Instigator).bNovice)) )
			&& !PPOther.bIsCrouching && PPOther.GetAnimGroup(PPOther.AnimSequence) != 'Ducking' )
		{
			if (STM != None)
				STM.PlayerHit(PawnOwner, 18, True);		// 18 = Sniper, Headshot
			if (HeadDamage > 0)
				Other.TakeDamage(HeadDamage, PawnOwner, HitLocation, 35000 * X, AltDamageType); // was 100 (150) dmg
			else
				Other.TakeDamage(class'UTPure'.default.HeadshotDamage, PawnOwner, HitLocation, 35000 * X, AltDamageType);
			if (STM != None)
				STM.PlayerClear();
		}
		else
		{
			if (STM != None)
				STM.PlayerHit(PawnOwner, 18, False);		// 18 = Sniper
			if (HitDamage > 0)
				Other.TakeDamage(HitDamage,  PawnOwner, HitLocation, 30000.0*X, MyDamageType);	 // was 45 (67) dmg
			else
				Other.TakeDamage(class'UTPure'.default.SniperDamagePri,  PawnOwner, HitLocation, 30000.0*X, MyDamageType);
			if (STM != None)
				STM.PlayerClear();
		}
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
		{
			if (bNewNet)
				spawn(class'NN_UT_SpriteSmokePuffOwnerHidden',Owner,,HitLocation+HitNormal*9);
			else
				spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9);
		}
	}
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

function Finish()
{
	if ( (Pawn(Owner).bFire!=0) && (FRand() < 0.6) )
		Timer();
	Super.Finish();
}

simulated function NN_TraceFire(float Accuracy)
{
	local vector HitLocation, HitDiff, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local bool bHeadshot;
	local int ClientFRVI;
	local float R1, R2;
	
	if (Owner.IsA('Bot'))
		return;
	
	yModInit();
	
	PawnOwner = Pawn(Owner);
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return;
	
	if (
		Pawn(Owner).bDuck != 0
		|| Owner.Velocity == 0 * Owner.Velocity
		|| Owner.Physics == PHYS_Falling
		|| PlayerPawn(Owner).DodgeDir != Dodge_NONE && PlayerPawn(Owner).DodgeDir != Dodge_DONE
	)
		Accuracy = 0;
	else
		Accuracy = 16000;

//	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(GV,X,Y,Z);
	StartTrace = Owner.Location + CDO + yMod * Y + FireOffset.Z * Z;
	
	R1 = NN_GetFRV();
	R2 = NN_GetFRV();
	EndTrace = StartTrace + Accuracy * (R1 - 0.5 )* Y * 1000
		+ Accuracy * (R2 - 0.5 ) * Z * 1000;
	EndTrace += (10000000 * vector(GV));
	
	ClientFRVI = bbP.zzNN_FRVI;
	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,PawnOwner);
	if (Other.IsA('Pawn'))
		HitDiff = HitLocation - Other.Location;
	
	bHeadshot = NN_ProcessTraceHit(Other, HitLocation, HitNormal, X,Y,Z,yMod);
	bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, bHeadshot, ClientFRVI);
	if (Other == bbP.zzClientTTarget)
		bbP.zzClientTTarget.TakeDamage(0, Pawn(Owner), HitLocation, 30000.0*vector(GV), MyDamageType);
}

function TraceFire( float Accuracy )
{
	local bbPlayer bbP;
	local vector NN_HitLoc, HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local float R1, R2;
	
	if (
		Pawn(Owner).bDuck != 0
		|| Owner.Velocity == 0 * Owner.Velocity
		|| Owner.Physics == PHYS_Falling
		|| PlayerPawn(Owner).DodgeDir != Dodge_NONE && PlayerPawn(Owner).DodgeDir != Dodge_DONE
	)
		Accuracy = 0;
	else
		Accuracy = 16000;
	
	if (Owner.IsA('Bot'))
	{
		Super.TraceFire(Accuracy);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP == None || !bNewNet)
	{
		Super.TraceFire(Accuracy);
		return;
	}
	
	if (bbP.zzNN_HitActor.IsA('bbPlayer') && !bbPlayer(bbP.zzNN_HitActor).xxCloseEnough(bbP.zzNN_HitLoc))
		bbP.zzNN_HitActor = None;
	
	Owner.MakeNoise(bbP.SoundDampening);
	GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
	
	StartTrace = Owner.Location + bbP.Eyeheight * Z; 
	AdjustedAim = bbP.AdjustAim(1000000, StartTrace, 2*AimError, False, False);	
	X = vector(AdjustedAim);
	
	R1 = GetFRV();
	R2 = GetFRV();
	EndTrace = StartTrace + Accuracy * (R1 - 0.5 )* Y * 1000
		+ Accuracy * (R2 - 0.5 ) * Z * 1000;
	EndTrace += (10000000 * vector(GV));
	
	if (bbP.zzNN_HitActor != None && VSize(bbP.zzNN_HitDiff) > bbP.zzNN_HitActor.CollisionRadius + bbP.zzNN_HitActor.CollisionHeight)
		bbP.zzNN_HitDiff = vect(0,0,0);
	
	if (bbP.zzNN_HitActor != None && (bbP.zzNN_HitActor.IsA('Pawn') || bbP.zzNN_HitActor.IsA('Projectile')) && FastTrace(bbP.zzNN_HitActor.Location + bbP.zzNN_HitDiff, StartTrace))
	{
		NN_HitLoc = bbP.zzNN_HitActor.Location + bbP.zzNN_HitDiff;
		bbP.TraceShot(HitLocation,HitNormal,NN_HitLoc,StartTrace);
	}
	else
	{
		bbP.TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
		NN_HitLoc = bbP.zzNN_HitLoc;
	}
	
	ProcessTraceHit(bbP.zzNN_HitActor, NN_HitLoc, HitNormal, X,Y,Z);
	bbP.zzNN_HitActor = None;
}


state Idle
{
	function Fire( float Value )
	{
		Global.Fire(Value);
	}
	
	function bool ClientAltFire( float Value)
	{
		bFinishZooming = false;
		return Super.ClientAltFire( Value );
	}

	function BeginState()
	{
		bPointing = false;
		SetTimer(0.4 + 1.6 * FRand(), false);
		Super.BeginState();
	}

	function EndState()
	{
		SetTimer(0.0, false);
		Super.EndState();
	}

Begin:
	bPointing=False;
	if ( AmmoType.AmmoAmount<=0 )
		Pawn(Owner).SwitchToBestWeapon();
	if ( Pawn(Owner).bFire!=0 ) Fire(0.0);
	Disable('AnimEnd');
	PlayIdleAnim();
}

state Zooming
{
	simulated function Tick(float DeltaTime)
	{
		if ( Pawn(Owner).bAltFire == 0 )
		{
			bZoom = false;
			SetTimer(0.0,False);
			GoToState('Idle');
		}
		else if ( bZoom )
		{
			if ( PlayerPawn(Owner).DesiredFOV > 3 )
			{
				PlayerPawn(Owner).DesiredFOV -= PlayerPawn(Owner).DesiredFOV*DeltaTime*4.0;
			}

			if ( PlayerPawn(Owner).DesiredFOV <=3 )
			{
				PlayerPawn(Owner).DesiredFOV = 3;
				bZoom = false;
				SetTimer(0.0,False);
				GoToState('Idle');
			}
		}
	}

	simulated function BeginState()
	{
		if ( Owner.IsA('PlayerPawn') )
		{
			bFinishZooming = true;
			if ( PlayerPawn(Owner).DesiredFOV == PlayerPawn(Owner).DefaultFOV )
			{
				bZoom = true;
				SetTimer(0.2,True);
			}
			else if ( bZoom == false )
			{
				PlayerPawn(Owner).DesiredFOV = PlayerPawn(Owner).DefaultFOV;
				Pawn(Owner).bAltFire = 0;
			}
		}
		else
		{
			Pawn(Owner).bFire = 1;
			Pawn(Owner).bAltFire = 0;
			Global.Fire(0);
		}
	}
}

simulated function PlayIdleAnim()
{
	if ( Mesh != PickupViewMesh )
		PlayAnim('Still',1.0, 0.05);
}

function SetWeaponStay()
{
	bWeaponStay = false;
}

simulated function SetSwitchPriority(pawn Other)
{	// Make sure "old" priorities are kept.
	local int i;
	local name temp, carried;

	if ( PlayerPawn(Other) != None )
	{
		for ( i=0; i<ArrayCount(PlayerPawn(Other).WeaponPriority); i++)
			if ( IsA(PlayerPawn(Other).WeaponPriority[i]) )		// <- The fix...
			{
				AutoSwitchPriority = i;
				return;
			}
		// else, register this weapon
		carried = 'SniperRifle';
		for ( i=AutoSwitchPriority; i<ArrayCount(PlayerPawn(Other).WeaponPriority); i++ )
		{
			if ( PlayerPawn(Other).WeaponPriority[i] == '' )
			{
				PlayerPawn(Other).WeaponPriority[i] = carried;
				return;
			}
			else if ( i<ArrayCount(PlayerPawn(Other).WeaponPriority)-1 )
			{
				temp = PlayerPawn(Other).WeaponPriority[i];
				PlayerPawn(Other).WeaponPriority[i] = carried;
				carried = temp;
			}
		}
	}		
}

simulated function PlaySelect()
{
	bForceFire = false;
	bForceAltFire = false;
	bCanClientFire = false;
	if ( !IsAnimating() || (AnimSequence != 'Select') )
		PlayAnim('Select',1.35 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000,0.0);
	Owner.PlaySound(SelectSound, SLOT_Misc, Pawn(Owner).SoundDampening);
	GoToState('Idle');
}

simulated function TweenDown()
{
	if ( IsAnimating() && (AnimSequence != '') && (GetAnimGroup(AnimSequence) == 'Select') )
		TweenAnim( AnimSequence, AnimFrame * 0.4 );
	else
		PlayAnim('Down', 1.35 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000, 0.05);
}

defaultproperties
{
     bNewNet=True
     zzWin=55
     Allow55="TRUE"
     hitdamage=45.000000
     HeadDamage=100.000000
     BodyHeight=0.620000
     FireAnims(0)=Fire
     FireAnims(1)=Fire2
     FireAnims(2)=Fire3
     FireAnims(3)=Fire4
     FireAnims(4)=Fire5
     WeaponDescription="Modified sniper rifle for h4x."
     AmmoName=Class'NewNetWeaponsv0_9_17.h4x_Bullets'
     PickupAmmoCount=500
     bInstantHit=True
     bAltInstantHit=True
     FiringSpeed=1.600000
     FireOffset=(Y=-5.000000,Z=-2.000000)
     MyDamageType=shot
     AltDamageType=Decapitated
     shakemag=0.000000
     shaketime=0.000000
     shakevert=0.000000
     AIRating=0.540000
     RefireRate=0.990000
     AltRefireRate=0.300000
     FireSound=Sound'NewNetWeaponsv0_9_17.Rifle.BLAM'
     AltFireSound=Sound'UnrealShare.AutoMag.shot'
     DeathMessage="%k fucked %o up"
     NameColor=(R=0,G=0)
     bDrawMuzzleFlash=True
     MuzzleScale=1.000000
     FlashY=0.110000
     FlashO=0.010000
     FlashC=0.030000
     FlashLength=0.010000
     FlashS=256
     AutoSwitchPriority=5
     InventoryGroup=10
     PickupMessage="You Picked Up A h4x Sniper Rifle."
     ItemName="h4x Sniper Rifle"
     PlayerViewOffset=(X=5.000000,Y=-1.600000,Z=-1.700000)
     PlayerViewMesh=LodMesh'Botpack.Rifle2m'
     PlayerViewScale=2.000000
     BobDamping=0.980000
     PickupViewMesh=LodMesh'Botpack.RiflePick'
     ThirdPersonMesh=LodMesh'Botpack.RifleHand'
     StatusIcon=Texture'Botpack.Icons.UseRifle'
     bMuzzleFlashParticles=True
     MuzzleFlashMesh=LodMesh'Botpack.muzzsr3'
     MuzzleFlashScale=0.100000
     MuzzleFlashTexture=Texture'Botpack.Skins.Muzzy3'
     PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
     Icon=Texture'Botpack.Icons.UseRifle'
     Rotation=(Roll=-1536)
     Mesh=LodMesh'Botpack.RiflePick'
     bNoSmooth=False
     CollisionRadius=32.000000
     CollisionHeight=8.000000
}
