class ST_AsmdPulseRifle expands ST_WildcardsWeapons;

var float LastFiredTime;
var float Angle, Count;
var() sound DownSound;
var() int HitDamage;
var float ClientSleepAgain;
var int HitCounter;
var Projectile Tracked;
var bool bBotSpecialMove;

replication
{
	reliable if ( Role == ROLE_Authority )
		FixOffset;
}

simulated function InitGraphics()
{
	if ( OrgClass == none )
	{
		Log("Original class still fails!");
		return;
	}
	else
		default.bGraphicsInitialized = true;

	default.FireSound = OrgClass.default.FireSound;
	FireSound = default.FireSound;

	default.AltFireSound = OrgClass.default.AltFireSound;
	AltFireSound = default.AltFireSound;

	default.AmmoName = OrgClass.default.AmmoName;
	AmmoName = default.AmmoName;

	default.PickupAmmoCount = OrgClass.default.PickupAmmoCount;
	PickupAmmoCount = default.PickupAmmoCount;

	default.MultiSkins[2] = OrgClass.default.MultiSkins[2];
	default.MultiSkins[1] = OrgClass.default.MultiSkins[1];
	MultiSkins[2] = default.MultiSkins[2];
	MultiSkins[1] = default.MultiSkins[1];

 	if ( Role == ROLE_Authority )
	{
		Spawn(class'ST_AsmdPulseLoader').TW = OrgClass;
	}
}

simulated function FixOffset (float Y)
{
	FireOffset.Y=Y;
}

simulated event RenderOverlays( canvas Canvas )
{
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	if (bNewNet && Role < ROLE_Authority && bbP != None)
	{
		if (bbP.bFire != 0 && !IsInState('ClientFiring'))
			ClientFire(1);
		else if (bbP.bAltFire != 0 && !IsInState('ClientAltFiring'))
			ClientAltFire(1);
	}
	
	MultiSkins[1] = none;
	Texture'Ammoled'.NotifyActor = Self;
	Super.RenderOverlays(Canvas);
	Texture'Ammoled'.NotifyActor = None;
	MultiSkins[1] = Default.MultiSkins[1];
}

simulated function AnimEnd()
{
	if ( (Level.NetMode == NM_Client) && (Mesh != PickupViewMesh) )
	{
		if ( AnimSequence == 'SpinDown' )
			AnimSequence = 'Idle';
		PlayIdleAnim();
	}
}
// set which hand is holding weapon
function setHand(float Hand)
{
	if ( Hand == 2 )
	{
		FireOffset.Y = 0;
		bHideWeapon = true;
		return;
	}
	else
		bHideWeapon = false;
	PlayerViewOffset = Default.PlayerViewOffset * 100;
	if ( Hand == 1 )
	{
		FireOffset.Y = Default.FireOffset.Y;
		Mesh = mesh(DynamicLoadObject("Botpack.PulseGunL", class'Mesh'));
	}
	else
	{
		FireOffset.Y = -1 * Default.FireOffset.Y;
		Mesh = mesh'PulseGunR';
	}
	FixOffset(FireOffset.Y);
}

// return delta to combat style
function float SuggestAttackStyle()
{
	local float EnemyDist;

	EnemyDist = VSize(Pawn(Owner).Enemy.Location - Owner.Location);
	if ( EnemyDist < 1000 )
		return 0.4;
	else
		return 0;
}

function float RateSelf( out int bUseAltMode )
{
	local Pawn P;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;

	P = Pawn(Owner);
	if ( (P.Enemy == None) || (Owner.IsA('Bot') && Bot(Owner).bQuickFire) )
	{
		bUseAltMode = 0;
		return AIRating;
	}

	if ( P.Enemy.IsA('StationaryPawn') )
	{
		bUseAltMode = 0;
		return (AIRating + 0.4);
	}
	else
		bUseAltMode = int( 700 > VSize(P.Enemy.Location - Owner.Location) );

	AIRating *= FMin(Pawn(Owner).DamageScaling, 1.5);
	return AIRating;
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'AsmdPulseRifle');
}

simulated function PlayFiring()
{
	FlashCount++;
	AmbientSound = FireSound;
	SoundVolume = Pawn(Owner).SoundDampening*255;
	LoopAnim( 'shootLOOP', 1 + 0.5 * FireAdjust, 0.0);
	bWarnTarget = (FRand() < 0.2);
}

simulated function PlayAltFiring()
{
	
	FlashCount++;
	AmbientSound = AltFireSound;
	SoundVolume = Pawn(Owner).SoundDampening*255;
	LoopAnim( 'shootLOOP', 1 + 0.5 * FireAdjust, 0.0);
	bWarnTarget = (FRand() < 0.2);
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	local Color C;
	local string Temp;

	if ( AmmoType == none )
		return;
	
	Temp = String(AmmoType.AmmoAmount);
	while(Len(Temp) < 3) Temp = "0"$Temp;

	Tex.DrawTile( 30, 100, (Min(AmmoType.AmmoAmount,AmmoType.Default.AmmoAmount)*196)/AmmoType.Default.AmmoAmount, 10, 0, 0, 1, 1, Texture'AmmoCountBar', False );

	if(AmmoType.AmmoAmount < 10)
	{
		C.R = 255;
		C.G = 0;
		C.B = 0;	
	}
	else
	{
		C.R = 0;
		C.G = 0;
		C.B = 255;
	}

	Tex.DrawColoredText( 56, 14, Temp, Font'LEDFont', C );	
}

simulated function PlaySpinDown()
{
	if ( (Mesh != PickupViewMesh) && (Owner != None) )
	{
		PlayAnim('Spindown', 1.0, 0.0);
		Owner.PlayOwnedSound(DownSound, SLOT_None,1.0*Pawn(Owner).SoundDampening);
	}
}	

state ComboMove
{
	function Fire(float F); 
	function AltFire(float F); 

	function Tick(float DeltaTime)
	{
		if ( (Owner == None) || (Pawn(Owner).Enemy == None) )
		{
			Tracked = None;
			bBotSpecialMove = false;
			Finish();
			return;
		}
		if ( (Tracked == None) || Tracked.bDeleteMe 
			|| (((Tracked.Location - Owner.Location) 
				dot (Tracked.Location - Pawn(Owner).Enemy.Location)) >= 0)
			|| (VSize(Tracked.Location - Pawn(Owner).Enemy.Location) < 100) )
			Global.Fire(0);
	}

Begin:
	Sleep(7.0);
	Tracked = None;
	bBotSpecialMove = false;
	Global.Fire(0);
}

state Idle
{
Begin:
	bPointing=False;
	if ( (AmmoType != None) && (AmmoType.AmmoAmount<=0) ) 
		Pawn(Owner).SwitchToBestWeapon();  //Goto Weapon that has Ammo
	if ( Pawn(Owner).bFire!=0 ) Fire(0.0);
	if ( Pawn(Owner).bAltFire!=0 ) AltFire(0.0);	

	Disable('AnimEnd');
	PlayIdleAnim();
}

auto state Pickup
{
	ignores AnimEnd;

	// Landed on ground.
	simulated function Landed(Vector HitNormal)
	{
		local rotator newRot;

		newRot = Rotation;
		newRot.pitch = 0;
		SetRotation(newRot);
		if ( Role == ROLE_Authority )
		{
			bSimFall = false;
			SetTimer(2.0, false);
		}
	}
}

state NormalFire
{
	ignores AnimEnd;

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
	function Tick( float DeltaTime )
	{
		if (Owner==None) 
			GotoState('Pickup');
	}

	function BeginState()
	{
		Super.BeginState();
		Angle = 0;
		AmbientGlow = 200;
	}

	function EndState()
	{
		PlaySpinDown();
		AmbientSound = None;
		AmbientGlow = 0;	
		OldFlashCount = FlashCount;	
		Super.EndState();
	}

Begin:
	Sleep(0.18);
	Finish();
}

state AltFiring
{
	ignores AnimEnd;

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

	function Tick( float DeltaTime )
	{
		if (Owner==None) 
			GotoState('Pickup');
	}

	function BeginState()
	{
		Super.BeginState();
		Angle = 0;
		AmbientGlow = 200;
	}

	function EndState()
	{
		PlaySpinDown();
		AmbientSound = None;
		AmbientGlow = 0;	
		OldFlashCount = FlashCount;	
		Super.EndState();
	}

Begin:
	Sleep(0.18);
	Finish();
}

simulated state ClientFiring
{
	simulated function Tick( float DeltaTime )
	{
		if ( (Pawn(Owner) != None) && (Pawn(Owner).bFire != 0) )
			AmbientSound = FireSound;
		else
			AmbientSound = None;
		if ((ClientSleepAgain -= DeltaTime) <= 0 ) //ACE IS BUGGED, SO I HAVE TO HANDLE THIS HERE
			AnimEnd();
	}

	simulated function AnimEnd()
	{
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
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else if ( Pawn(Owner).bAltFire != 0 )
			Global.ClientAltFire(0);
		else
		{
			PlaySpinDown();
			GotoState('');
		}
	}
Begin:
	ClientSleepAgain = 0.18;
//	Sleep(0.18);
}

simulated state ClientAltFiring
{
	simulated function Tick( float DeltaTime )
	{
		if ( (Pawn(Owner) != None) && (Pawn(Owner).bFire != 0) )
			AmbientSound = FireSound;
		else
			AmbientSound = FireSound;
		if ((ClientSleepAgain -= DeltaTime) <= 0 )
			AnimEnd();
	}
	simulated function AnimEnd()
	{
		local bool bForce, bForceAlt;
		
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}

		bForce = bForceFire;
		bForceAlt = bForceAltFire;
		bForceFire = false;
		bForceAltFire = false;

		if ( AmmoType.AmmoAmount <= 0 )
		{
			PlayIdleAnim();
			GotoState('');
		}

		if ( bNewNet && Level.NetMode == NM_Client && bCanClientFire && (PlayerPawn(Owner) != None) && (AmmoType.AmmoAmount > 0) )
		{
			if ( bForce || (Pawn(Owner).bFire != 0) )
			{
				Global.ClientFire(1);
				return;
			}
			else if ( bForceAlt || (Pawn(Owner).bAltFire != 0) )
			{
				Global.ClientAltFire(1);
				return;
			}
			else if ( !bCanClientFire )
				GotoState('');
			else if ( Pawn(Owner) == None )
			{
				PlayIdleAnim();
				GotoState('');
			}
			else if ( Pawn(Owner).bAltFire != 0 )
				LoopAnim( 'shootLOOP', 1 + 0.5 * FireAdjust, 0.0);
			else if ( Pawn(Owner).bFire != 0 )
				Global.ClientFire(0);
			else
			{
				PlayIdleAnim();
				GotoState('');
			}
		}
	}
Begin:
	Sleep(0.18);
	AnimEnd();
}

simulated function PlayIdleAnim()
{
	if ( Mesh == PickupViewMesh )
		return;

	if ( (AnimSequence == 'BoltLoop') || (AnimSequence == 'BoltStart') )
		PlayAnim('BoltEnd');		
	else if ( AnimSequence != 'SpinDown' )
		TweenAnim('Idle', 0.1);
}

simulated function NN_TraceFire()
{
	local vector HitLocation, HitDiff, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;
	local bool zzbNN_Combo;
	local bbPlayer bbP;
	local Pawn P;
	
	if (Owner.IsA('Bot'))
		return;
	
	yModInit();
	
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return;

//	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(GV,X,Y,Z);
	StartTrace = Owner.Location + CDO + yMod * Y + FireOffset.Z * Z;
	EndTrace = StartTrace + (100000 * vector(GV)); 
	
	//for (P = Level.PawnList; P != None; P = P.NextPawn)
	//	P.SetCollisionSize(P.CollisionRadius * ShockRadius / 100, P.CollisionHeight);

	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,Pawn(Owner));
	if (Other.IsA('Pawn'))
		HitDiff = HitLocation - Other.Location;
	
	zzbNN_Combo = NN_ProcessTraceHit(Other, HitLocation, HitNormal, vector(GV),Y,Z);
	if (zzbNN_Combo)
		bbP.xxNN_Fire(ST_sgShockProj(Other).zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, true);
	else
		bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, false);
	if (Other == bbP.zzClientTTarget)
		bbP.zzClientTTarget.TakeDamage(0, Pawn(Owner), HitLocation, 60000.0*vector(GV), MyDamageType);
	
	//for (P = Level.PawnList; P != None; P = P.NextPawn)
	//	P.SetCollisionSize(P.Default.CollisionRadius, P.CollisionHeight);
}

simulated function bool NN_ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local bool zzbNN_Combo;
	
	if (Owner.IsA('Bot'))
		return false;
	
	if (Other==None)
	{
		HitNormal = -X;
		HitLocation = Owner.Location + X*100000.0;
	}
	
	NN_SpawnEffect(HitLocation, Owner.Location + CDO + (FireOffset.X + 20) * X + Y * yMod + FireOffset.Z * Z, HitNormal);

	if ( ST_sgShockProj(Other)!=None )
	{
		ST_sgShockProj(Other).NN_SuperExplosion(Pawn(Owner));
		zzbNN_Combo = true;
	}
	else
	{
		Spawn(class'UT_RingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxClientDemoFix(None, class'UT_RingExplosion2',HitLocation+HitNormal*8,,, rotator(HitNormal));
	}
	
	//if (Other.IsA('Mover')) {
	//	if (HitDamage > 0)
	//		bbPlayer(Owner).xxMover_TakeDamage(Mover(Other), HitDamage, Pawn(Owner), HitLocation, 60000.0 * X, MyDamageType);
	//	else
	//		bbPlayer(Owner).xxMover_TakeDamage(Mover(Other), class'UTPure'.default.ShockDamagePri, Pawn(Owner), HitLocation, 60000.0 * X, MyDamageType);
	//}

	//if ( (Other != self) && (Other != Owner) && (bbPlayer(Other) != None) ) 
	//	bbPlayer(Other).NN_Momentum( 60000.0*X );
	return zzbNN_Combo;
}

simulated function NN_SpawnEffect(vector HitLocation, vector SmokeLocation, vector HitNormal)
{
	local ShockBeam Smoke,shock;
	local Vector DVector;
	local int NumPoints;
	local rotator SmokeRotation;
	
	if (Owner.IsA('Bot'))
		return;

	DVector = HitLocation - SmokeLocation;
	NumPoints = VSize(DVector)/135.0;
	if ( NumPoints < 1 )
		return;
	SmokeRotation = rotator(DVector);
	SmokeRotation.roll = Rand(65535);
	
	Smoke = Spawn(class'NN_ShockBeam',Owner,,SmokeLocation,SmokeRotation);
	Smoke.MoveAmount = DVector/NumPoints;
	Smoke.NumPuffs = NumPoints - 1;
	if (bbPlayer(Owner) != None)
		bbPlayer(Owner).xxClientDemoFix(None, class'NN_ShockBeam',SmokeLocation,,,SmokeRotation);
}

function Fire ( float Value )
{
	local bbPlayer bbP;
/* 	
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	 */
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;
	Super.Fire(Value);
}

function AltFire( float Value )
{
	local actor HitActor;
	local vector HitLocation, HitNormal, Start;
	local bbPlayer bbP;
	local NN_sgShockProjOwnerHidden NNSP;
/* 	
	if (Owner.IsA('Bot'))
	{
		Super.AltFire(Value);
		return;
	}
 */
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;

	if ( Owner == None )
		return;

	if ( Owner.IsA('Bot') ) //make sure won't blow self up
	{
		Start = Owner.Location + CalcDrawOffset() + FireOffset.Z * vect(0,0,1); 
		if ( Pawn(Owner).Enemy != None )
			HitActor = Trace(HitLocation, HitNormal, Start + 250 * Normal(Pawn(Owner).Enemy.Location - Start), Start, false, vect(12,12,12));
		else
			HitActor = self;
		if ( HitActor != None )
		{
			Global.Fire(Value);
			return;
		}
	}	
	if ( AmmoType != None && AmmoType.UseAmmo(1) )
	{
		GotoState('AltFiring');
		bCanClientFire = true;
		if ( Owner.IsA('Bot') )
		{
			if ( Owner.IsInState('TacticalMove') && (Owner.Target == Pawn(Owner).Enemy)
			 && (Owner.Physics == PHYS_Walking) && !Bot(Owner).bNovice
			 && (FRand() * 6 < Pawn(Owner).Skill) )
				Pawn(Owner).SpecialFire();
		}
		bPointing=True;
		ClientAltFire(value);
		if (bNewNet)
		{
			NNSP = NN_sgShockProjOwnerHidden(ProjectileFire(Class'NN_sgShockProjOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
			if (NNSP != None)
			{
				NNSP.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
				if (bbP != None)
					NNSP.zzNN_ProjIndex = bbP.xxNN_AddProj(NNSP);
			}
		}
		else
		{
			Pawn(Owner).PlayRecoil(FiringSpeed);
			ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget);
		}
	}
}

simulated function bool ClientFire( float Value )
{
	local bbPlayer bbP;

 	if (Owner.IsA('Bot'))
		return Super.ClientFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Level.TimeSeconds - LastFiredTime < 0.2)
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
			NN_TraceFire();
			LastFiredTime = Level.TimeSeconds;
		}
	}
	return Super.ClientFire(Value);
}

simulated function bool ClientAltFire(float Value)
{
	local bbPlayer bbP;
	
 	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Level.TimeSeconds - LastFiredTime < 0.2)
			return false;
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			GotoState('AltFiring');
			bCanClientFire = true;
			Pawn(Owner).PlayRecoil(FiringSpeed);
			bPointing=True;
			NN_ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget);
			LastFiredTime = Level.TimeSeconds;
		}
	}
	return Super.ClientAltFire(Value);
}

function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;
	local PlayerPawn PlayerOwner;
	local bbPlayer bbP;
	
 	if (Owner.IsA('Bot'))
		return Super.ProjectileFire(ProjClass, ProjSpeed, bWarn);

	PlayerOwner = PlayerPawn(Owner);
	bbP = bbPlayer(Owner);
	
	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	if (bNewNet && bbP != None)
	{
		if (Level.TimeSeconds - LastFiredTime < 0.2)
			return None;
		GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
		if (Mover(bbP.Base) == None)
			Start = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		else
			Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
	}
	else
	{
		GetAxes(Pawn(Owner).ViewRotation,X,Y,Z);
		Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
	}
	AdjustedAim = pawn(owner).AdjustAim(ProjSpeed, Start, AimError, True, bWarn);	

	if ( PlayerOwner != None )
		PlayerOwner.ClientInstantFlash( -0.4, vect(450, 190, 650));
	
	LastFiredTime = Level.TimeSeconds;
	return Spawn(ProjClass,Owner,, Start,AdjustedAim);
}

simulated function Projectile NN_ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;
	local PlayerPawn PlayerOwner;
	local Projectile Proj;
	local ST_sgShockProj ST_Proj;
	local int ProjIndex;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return None;
	
	yModInit();
	
	bbP = bbPlayer(Owner);
	if (bbP == None || (Level.TimeSeconds - LastFiredTime) < 0.2)
		return None;
		
	GetAxes(GV,X,Y,Z);
	Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
	if ( PlayerOwner != None )
		PlayerOwner.ClientInstantFlash( -0.2, vect(450, 190, 650));
	
	LastFiredTime = Level.TimeSeconds;
	Proj = Spawn(ProjClass,Owner,, Start,GV);
	ST_Proj = ST_sgShockProj(Proj);
	ProjIndex = bbP.xxNN_AddProj(Proj);
	if (ST_Proj != None)
		ST_Proj.zzNN_ProjIndex = ProjIndex;
	bbP.xxNN_AltFire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
	bbP.xxClientDemoFix(ST_Proj, Class'ShockProj', Start, ST_Proj.Velocity, Proj.Acceleration, GV);
}

function TraceFire( float Accuracy )
{
	local bbPlayer bbP;
	local actor NN_Other;
	local bool bShockCombo;
	local NN_sgShockProjOwnerHidden NNSP;
	local vector NN_HitLoc, HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;

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

	if (bbP.zzNN_HitActor != None && bbP.zzNN_HitActor.IsA('bbPlayer') && !bbPlayer(bbP.zzNN_HitActor).xxCloseEnough(bbP.zzNN_HitLoc))
		bbP.zzNN_HitActor = None;
	
	NN_Other = bbP.zzNN_HitActor;
	bShockCombo = bbP.zzbNN_Special && (NN_Other == None || NN_sgShockProjOwnerHidden(NN_Other) != None && NN_Other.Owner != Owner);
	
	if (bShockCombo && NN_Other == None)
	{
		ForEach AllActors(class'NN_sgShockProjOwnerHidden', NNSP)
			if (NNSP.zzNN_ProjIndex == bbP.zzNN_ProjIndex)
				NN_Other = NNSP;
		
		if (NN_Other == None)
			NN_Other = Spawn(class'NN_sgShockProjOwnerHidden', Owner,, bbP.zzNN_HitLoc);
		else
			NN_Other.SetLocation(bbP.zzNN_HitLoc);
		
		bbP.zzNN_HitActor = NN_Other;
	}
	
	Owner.MakeNoise(bbP.SoundDampening);
	GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
	
	StartTrace = Owner.Location + CalcDrawOffset() + FireOffset.Y * Y + FireOffset.Z * Z;
	EndTrace = StartTrace + Accuracy * (FRand() - 0.5 )* Y * 1000
		+ Accuracy * (FRand() - 0.5 ) * Z * 1000 ;

	if ( bBotSpecialMove && (Tracked != None)
		&& (((Owner.Acceleration == vect(0,0,0)) && (VSize(Owner.Velocity) < 40)) ||
			(Normal(Owner.Velocity) Dot Normal(Tracked.Velocity) > 0.95)) )
		EndTrace += 100000 * Normal(Tracked.Location - StartTrace);
	else
	{
		AdjustedAim = bbP.AdjustAim(1000000, StartTrace, 2.75*AimError, False, False);	
		EndTrace += (100000 * vector(AdjustedAim)); 
	}
	
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
	
	ProcessTraceHit(bbP.zzNN_HitActor, NN_HitLoc, HitNormal, vector(AdjustedAim),Y,Z);
	bbP.zzNN_HitActor = None;
	Tracked = None;
	bBotSpecialMove = false;
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local PlayerPawn PlayerOwner;
	local Pawn PawnOwner;

	if (Owner.IsA('Bot'))
	{
		Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		return;
	}

	PawnOwner = Pawn(Owner);
	if (STM != None)
		STM.PlayerFire(PawnOwner, 5);		// 5 = Shock Beam.

	if (Other==None)
	{
		HitNormal = -X;
		HitLocation = Owner.Location + X*10000.0;
	}

	PlayerOwner = PlayerPawn(Owner);
	if ( PlayerOwner != None )
		PlayerOwner.ClientInstantFlash( -0.4, vect(450, 190, 650));
	SpawnEffect(HitLocation, Owner.Location + CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * Y + FireOffset.Z * Z);
	
	if (bbPlayer(Owner) != None && !bbPlayer(Owner).xxConfirmFired(7))
		return;
	
	if ( NN_sgShockProjOwnerHidden(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);		// 5 = Shock Beam
		Other.SetOwner(Owner);
		NN_sgShockProjOwnerHidden(Other).SuperExplosion();
		return;
	}
	else if ( ST_sgShockProj(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);		// 5 = Shock Beam
		ST_sgShockProj(Other).SuperExplosion();
		return;
	}
	else if (bNewNet)
	{
		DoRingExplosion5(PlayerPawn(Owner), HitLocation, HitNormal);
	}
	else
	{
		Spawn(class'UT_RingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
	}

	if ( (Other != self) && (Other != Owner) && (Other != None) ) 
	{
		if (STM != None)
			STM.PlayerHit(PawnOwner, 5, False);			// 5 = Shock Beam
		//if (HitDamage > 0)
			Other.TakeDamage(HitDamage, PawnOwner, HitLocation, 60000.0*X, MyDamageType);
		//else
			//Other.TakeDamage(class'UTPure'.default.ShockDamagePri, PawnOwner, HitLocation, 60000.0*X, MyDamageType);
		if (STM != None)
			STM.PlayerClear();
	}

	if (Pawn(Other) != None && Other != Owner && Pawn(Other).Health > 0)
	{	// We hit a pawn that wasn't the owner or dead. (How can you hit yourself? :P)
		HitCounter++;						// +1 hit
		if (HitCounter == 3)
		{	// Wowsers!
			HitCounter = 0;
			if (STM != None)
				STM.PlayerSpecial(PawnOwner, 5);		// 5 = Shock Beam
		}
	}
	else
		HitCounter = 0;
}

simulated function DoRingExplosion5(PlayerPawn Pwner, vector HitLocation, vector HitNormal)
{
	local PlayerPawn P;
	local Actor CR;
	
	if (Owner.IsA('Bot'))
		return;

	if (RemoteRole < ROLE_Authority) {
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
			if (P != Pwner) {
				CR = P.Spawn(class'UT_RingExplosion2',P,, HitLocation+HitNormal*8,rotator(HitNormal));
				CR.bOnlyOwnerSee = True;
			}
	}
}

function SpawnEffect(vector HitLocation, vector SmokeLocation)
{
	local ShockBeam Smoke,shock;
	local Vector DVector;
	local int NumPoints;
	local rotator SmokeRotation;
/* 	
	if (Owner.IsA('Bot'))
	{
		Super.SpawnEffect(HitLocation, SmokeLocation);
		return;
	}
 */
	DVector = HitLocation - SmokeLocation;
	NumPoints = VSize(DVector)/135.0;
	if ( NumPoints < 1 )
		return;
	SmokeRotation = rotator(DVector);
	SmokeRotation.roll = Rand(65535);
	
	if (bNewNet)
		Smoke = Spawn(class'NN_ShockBeamOwnerHidden',Owner,,SmokeLocation,SmokeRotation);
	else
		Smoke = Spawn(class'ShockBeam',,,SmokeLocation,SmokeRotation);
	Smoke.MoveAmount = DVector/NumPoints;
	Smoke.NumPuffs = NumPoints - 1;	
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
	FireDir = vector(P.ViewRotation);
	targ = P.PickTarget(bestAim, bestDist, FireDir, Owner.Location);
	if ( Pawn(targ) != None )
	{
		bPointing = true;
		Pawn(targ).WarnTarget(P, 300, FireDir);
		SetTimer(1 + 4 * FRand(), false);
	}
	else 
	{
		SetTimer(0.5 + 2 * FRand(), false);
		if ( (P.bFire == 0) && (P.bAltFire == 0) )
			bPointing = false;
	}
}	

function Finish()
{
	if ( (Pawn(Owner).bFire!=0) && (FRand() < 0.6) )
		Timer();
	if ( !bChangeWeapon && (Tracked != None) && !Tracked.bDeleteMe && (Owner != None) 
		&& (Owner.IsA('Bot')) && (Pawn(Owner).Enemy != None) && (FRand() < 0.3 + 0.35 * Pawn(Owner).skill)
		&& (AmmoType.AmmoAmount > 0) ) 
	{
		if ( (Owner.Acceleration == vect(0,0,0)) ||
			(Abs(Normal(Owner.Velocity) dot Normal(Tracked.Velocity)) > 0.95) )
		{
			bBotSpecialMove = true;
			GotoState('ComboMove');
			return;
		}
	}

	bBotSpecialMove = false;
	Tracked = None;
	Super.Finish();
}

defaultproperties
{
     bNewNet=True
     hitdamage=50
     AltProjectileClass=Class'ST_sgShockProj'
     DownSound=Sound'Botpack.PulseGun.PulseDown'
     bInstantHit=True
     bRapidFire=True
     FireOffset=(X=16.000000,Y=-14.000000,Z=-8.000000)
     MyDamageType=jolted
     AltDamageType=jolted
     shakemag=135.000000
     shakevert=8.000000
     AIRating=0.700000
     RefireRate=0.950000
     AltRefireRate=0.990000
     SelectSound=Sound'Botpack.PulseGun.PulsePickup'
     DeathMessage="%o was torn to pieces by %k's %w."
     NameColor=(R=128,G=0,B=128)
     FlashLength=0.020000
     AutoSwitchPriority=5
     InventoryGroup=5
     PickupMessage="You got the ASMD Pulse Rifle"
     ItemName="ASMD Pulse Rifle"
     PlayerViewOffset=(X=1.500000,Z=-2.000000,Y=0)
     PlayerViewMesh=LodMesh'Botpack.PulseGunR'
	 PlayerViewScale=1.0
     PickupViewMesh=LodMesh'Botpack.PulsePickup'
     ThirdPersonMesh=LodMesh'Botpack.PulseGun3rd'
     ThirdPersonScale=0.400000
     StatusIcon=Texture'Botpack.Icons.UsePulse'
     bMuzzleFlashParticles=True
     MuzzleFlashStyle=STY_Translucent
     MuzzleFlashMesh=LodMesh'Botpack.muzzPF3'
     MuzzleFlashScale=0.400000
     MuzzleFlashTexture=Texture'Botpack.Skins.MuzzyPulse'
     PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
     Icon=Texture'Botpack.Icons.UsePulse'
     Mesh=LodMesh'Botpack.PulsePickup'
}
