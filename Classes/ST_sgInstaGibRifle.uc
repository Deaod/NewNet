class ST_sgInstaGibRifle extends ST_WildcardsWeapons;

var bool bAltFired;
var float LastFiredTime;
var Projectile Tracked;
var bool bBotSpecialMove;
var() int HitDamage;
var float TapTime;

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

	default.StatusIcon = OrgClass.default.StatusIcon;
	StatusIcon = default.StatusIcon;

	default.Icon = OrgClass.default.Icon;
	Icon = default.Icon;

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
		Spawn(class'ST_sgInstaGibLoader').TW = OrgClass;
	}
}

simulated function RenderOverlays(Canvas Canvas)
{
	local bbPlayer bbP;
	
	MultiSkins[1] = none;
	Super.RenderOverlays(Canvas);
	MultiSkins[1] = MultiSkins[7];
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

simulated function bool ClientFire(float Value)
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Level.TimeSeconds - LastFiredTime < 0.9)
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
	if (bbP != None)
	{
		LastFiredTime = Level.TimeSeconds;
	}
	bCanClientFire = true;
	Instigator = Pawn(Owner);
	if (bbP != None)
	{
		bbP.xxNN_AltFire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
	}
	return Super.ClientAltFire(Value);
}

function Fire( float Value )
{
	local bbPlayer bbP;

	bbP = bbPlayer(Owner);
	bAltFired = false;
	if (bbP != None && bNewNet && Value < 1)
		return;
	if (AmmoType.AmmoAmount > 0 )
	{
		GotoState('NormalFire');
		bCanClientFire = true;
		bPointing=True;
		ClientFire(value);
		AmmoType.UseAmmo(1);
		if ( bRapidFire || (FiringSpeed > 0) )
			Pawn(Owner).PlayRecoil(FiringSpeed);
		if ( bInstantHit )
			TraceFire(0.0);
		else
			ProjectileFire(ProjectileClass, ProjectileSpeed, bWarnTarget);
	}
}

function AltFire( float Value )
{
	bAltFired = true;
	if (AmmoType.AmmoAmount > 0 )
	{
		GotoState('NormalFire');
		bCanClientFire = true;
		bPointing=True;
		ClientFire(value);
		AmmoType.UseAmmo(1);
		if ( bRapidFire || (FiringSpeed > 0) )
			Pawn(Owner).PlayRecoil(FiringSpeed);
		if ( bInstantHit )
			TraceFire(0.0);
		else
			ProjectileFire(ProjectileClass, ProjectileSpeed, bWarnTarget);
	}
}

simulated function PlayFiring()
{
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
	if (Level.NetMode == NM_Client)
		LoopAnim('Fire1', 0.20 + 0.20 * FireAdjust,0.05);
	else
		LoopAnim('Fire1', 0.22 + 0.22 * FireAdjust,0.05);
}

simulated function PlayAltFiring()
{
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
	LoopAnim('Fire1', 0.20 + 0.20 * FireAdjust,0.05);
}

simulated function PlayIdleAnim()
{
	if ( Mesh != PickupViewMesh )
		LoopAnim('Still',0.04,0.3);
}

state Idle
{

	function BeginState()
	{
		bPointing = false;
		SetTimer(0.5 + 2 * FRand(), false);
		Super.BeginState();
		if (Pawn(Owner).bFire!=0) Fire(0.0);
		if (Pawn(Owner).bAltFire!=0) AltFire(0.0);		
	}

	function EndState()
	{
		SetTimer(0.0, false);
		Super.EndState();
	}
}

state ClientFiring
{
	simulated function bool ClientFire(float Value)
	{
		if ( Level.TimeSeconds - TapTime < 0.2 )
			return false;
		bForceFire = bForceFire || ( bCanClientFire && (Pawn(Owner) != None) && (AmmoType.AmmoAmount > 0) );
		return bForceFire;
	}

	simulated function bool ClientAltFire(float Value)
	{
		if ( Level.TimeSeconds - TapTime < 0.2 )
			return false;
		bForceAltFire = bForceAltFire || ( bCanClientFire && (Pawn(Owner) != None) && (AmmoType.AmmoAmount > 0) );
		return bForceAltFire;
	}

	simulated function AnimEnd()
	{
		local bool bForce, bForceAlt;

		bForce = bForceFire;
		bForceAlt = bForceAltFire;
		bForceFire = false;
		bForceAltFire = false;

		if ( bCanClientFire && (PlayerPawn(Owner) != None) && (AmmoType.AmmoAmount > 0) )
		{
			if ( bForce || (Pawn(Owner).bFire != 0) )
			{
				Global.ClientFire(0);
				return;
			}
			else if ( bForceAlt || (Pawn(Owner).bAltFire != 0) )
			{
				Global.ClientAltFire(0);
				return;
			}
		}			
		Super.AnimEnd();
	}

	simulated function EndState()
	{
		bForceFire = false;
		bForceAltFire = false;
	}

	simulated function BeginState()
	{
		TapTime = Level.TimeSeconds;
		bForceFire = false;
		bForceAltFire = false;
	}
}

simulated function NN_TraceFire()
{
	local vector HitLocation, HitDiff, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local vector zzHitLocation, zzHitDiff, zzHitNormal, zzStartTrace, zzEndTrace, zzX,zzY,zzZ;
	local actor Other, zzOther;
	local bool zzbNN_Combo;
	local bbPlayer bbP, zzbbP;
	local float oRadius, oHeight;
	
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

	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,Pawn(Owner));
	if (Other.IsA('Pawn'))
	{
		HitDiff = HitLocation - Other.Location;
	}
	
	zzbNN_Combo = NN_ProcessTraceHit(Other, HitLocation, HitNormal, vector(GV),Y,Z);
	if (zzbNN_Combo)
		bbP.xxNN_Fire(ST_ShockProj(Other).zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, true);
	else
		bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, false);
	if (Other == bbP.zzClientTTarget)
		bbP.zzClientTTarget.TakeDamage(0, Pawn(Owner), HitLocation, 60000.0*vector(GV), MyDamageType);
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

	if ( ST_ShockProj(Other)!=None )
	{ 
		ST_ShockProj(Other).NN_SuperDuperExplosion(Pawn(Owner));
		zzbNN_Combo = true;
	}
	else
	{
		Spawn(class'UT_GreenRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxClientDemoFix(None, class'UT_GreenRingExplosion2',HitLocation+HitNormal*8,,, rotator(HitNormal));
	}

	//if ( (Other != self) && (Other != Owner) && (bbPlayer(Other) != None) ) 
	//	bbPlayer(Other).NN_Momentum( 60000.0*X );
	return zzbNN_Combo;
}

simulated function NN_SpawnEffect(vector HitLocation, vector SmokeLocation, vector HitNormal)
{
	local GreenShockBeam Smoke,shock;
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
	
	Smoke = Spawn(class'NN_GreenShockBeam',Owner,,SmokeLocation,SmokeRotation);
	Smoke = Spawn(class'GreenShockBeamEffect',Owner,,SmokeLocation,SmokeRotation);
	Smoke.MoveAmount = DVector/NumPoints;
	Smoke.NumPuffs = NumPoints - 1;
	if (bbPlayer(Owner) != None)
		bbPlayer(Owner).xxClientDemoFix(None, class'NN_GreenShockBeam',SmokeLocation,,,SmokeRotation);
		bbPlayer(Owner).xxClientDemoFix(None, class'GreenShockBeamEffect',SmokeLocation,,,SmokeRotation);
}

function TraceFire( float Accuracy )
{
	local bbPlayer bbP;
	local actor NN_Other;
	local bool bShockCombo;
	local NN_ShockProjOwnerHidden NNSP;
	local vector NN_HitLoc, HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	
	if (Owner.IsA('Bot'))
	{
		Super.TraceFire(Accuracy);
		return;
	}

	bbP = bbPlayer(Owner);
	if (bbP == None || !bNewNet || bAltFired)
	{
		Super.TraceFire(Accuracy);
		bAltFired = false;
		return;
	}
	
	if (bbP.zzNN_HitActor != None && bbP.zzNN_HitActor.IsA('bbPlayer') && !bbPlayer(bbP.zzNN_HitActor).xxCloseEnough(bbP.zzNN_HitLoc))
		bbP.zzNN_HitActor = None;
	
	NN_Other = bbP.zzNN_HitActor;
	bShockCombo = bbP.zzbNN_Special && (NN_Other == None || NN_ShockProjOwnerHidden(NN_Other) != None && NN_Other.Owner != Owner);
	
	if (bShockCombo && NN_Other == None)
	{
		ForEach AllActors(class'NN_ShockProjOwnerHidden', NNSP)
			if (NNSP.zzNN_ProjIndex == bbP.zzNN_ProjIndex)
				NN_Other = NNSP;
		
		if (NN_Other == None)
			NN_Other = Spawn(class'NN_ShockProjOwnerHidden', Owner,, bbP.zzNN_HitLoc);
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
		bbP.zzNN_HitActor = bbP.TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
		NN_HitLoc = bbP.zzNN_HitLoc;
	}
	
	ProcessTraceHit(bbP.zzNN_HitActor, NN_HitLoc, HitNormal, vector(AdjustedAim),Y,Z);
	bbP.zzNN_HitActor = None;
	Tracked = None;
	bBotSpecialMove = false;
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local Pawn PawnOwner;
	
/* 	if (Owner.IsA('Bot'))
	{
		Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		return;
	}
	
	if (bbPlayer(Owner) != None && !bbPlayer(Owner).xxConfirmFired(7))
		return;
	 */
	yModInit();

	PawnOwner = Pawn(Owner);

	if (Other==None)
	{
		HitNormal = -X;
		HitLocation = Owner.Location + X*10000.0;
	}
	SpawnEffect(HitLocation, Owner.Location + CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * Y + FireOffset.Z * Z);
	if (bNewNet && !bAltFired)
	{
		DoRingExplosion_GREEN(PlayerPawn(Owner), HitLocation, HitNormal);
	}
	else
	{
		Spawn(class'UT_GreenRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
	}
	
	if ( (Other != self) && (Other != Owner) && (Other != None) ) 
	{
		Other.TakeDamage(HitDamage, PawnOwner, HitLocation, 60000.0*X, MyDamageType);
	}
}

simulated function DoRingExplosion_GREEN(PlayerPawn Pwner, vector HitLocation, vector HitNormal)
{
	local PlayerPawn P;
	local Actor CR;
	
	//if (Owner.IsA('Bot'))
		//return;

	if (RemoteRole < ROLE_Authority) {
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
			if (P != Pwner) {
				CR = P.Spawn(class'UT_GreenRingExplosion2',P,, HitLocation+HitNormal*8,rotator(HitNormal));
				CR.bOnlyOwnerSee = True;
			}
	}
}

function SpawnEffect(vector HitLocation, vector SmokeLocation)
{
	local GreenShockBeam Smoke,shock;
	local Vector DVector;
	local int NumPoints;
	local rotator SmokeRotation;

	DVector = HitLocation - SmokeLocation;
	NumPoints = VSize(DVector)/135.0;
	if ( NumPoints < 1 )
		return;
	SmokeRotation = rotator(DVector);
	SmokeRotation.roll = Rand(65535);
	
	if (bNewNet && !bAltFired)
	{
		Smoke = Spawn(class'NN_GreenShockBeamOwnerHidden',Owner,,SmokeLocation,SmokeRotation);
		Smoke = Spawn(class'GreenShockBeamEffectOH',Owner,,SmokeLocation,SmokeRotation);
	}
	else
	{
		Smoke = Spawn(class'NN_GreenShockBeam',,,SmokeLocation,SmokeRotation);
		Smoke = Spawn(class'GreenShockBeamEffect',,,SmokeLocation,SmokeRotation);
	}
	Smoke.MoveAmount = DVector/NumPoints;
	Smoke.NumPuffs = NumPoints - 1;	
//	Log("MoveAmount="$Smoke.MoveAmount);
//	Log("NumPuffs="$Smoke.NumPuffs);
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
}

state AltFiring
{
	function Fire(float F) 
	{
		if (Owner.IsA('Bot'))
		{
			Super.AltFire(F);
			return;
		}
		if (F > 0 && bbPlayer(Owner) != None)
			Global.Fire(F);
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
}

function float RateSelf( out int bUseAltMode )
{
	local Pawn P;
	local bool bNovice;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;

	P = Pawn(Owner);

	bUseAltMode = 0;
	return AIRating;
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

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'SiegeInstaGibRifle');
}

simulated function PlaySelect ()
{
	Class'NN_WeaponFunctions'.static.PlaySelect( self);
}

simulated function TweenDown ()
{
	Class'NN_WeaponFunctions'.static.TweenDown( self);
}

defaultproperties
{
     HitDamage=300
     WeaponDescription="Classification: Energy Rifle"
     InstFlash=-0.400000
     InstFog=(X=800.000000)
     AmmoName=Class'SuperShockCore'
     PickupAmmoCount=50
     bInstantHit=True
     bAltWarnTarget=True
     bSplashDamage=True
     FiringSpeed=2.000000
	 FireOffset=(X=10.000000,Y=-7.000000,Z=-9.000000)
     MyDamageType=jolted
     aimerror=650.000000
     AIRating=0.630000
     AltRefireRate=0.700000
     FireSound=Sound'TazerFire'
     AltFireSound=Sound'TazerFire'
     SelectSound=Sound'UnrealShare.ASMD.TazerSelect'
     DeathMessage="%k electrified %o with the %w."
     NameColor=(R=128,G=0)
     AutoSwitchPriority=4
     InventoryGroup=4
     PickupMessage="You got the Siege Enhanced Shock Rifle."
     ItemName="Siege Enhanced Shock Rifle"
     PlayerViewOffset=(X=4.400000,Y=-1.700000,Z=-1.600000)
     PlayerViewMesh=LodMesh'Botpack.sshockm'
     PlayerViewScale=2.000000
     BobDamping=0.975000
     PickupViewMesh=LodMesh'Botpack.ASMD2pick'
     ThirdPersonMesh=LodMesh'Botpack.SASMD2hand'
     StatusIcon=Texture'UseASMD'
     PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
     Icon=Texture'UseASMD'
     Mesh=LodMesh'Botpack.ASMD2pick'
     CollisionRadius=34.000000
     CollisionHeight=8.000000
     Mass=50.000000
}
