class ST_h4xRifle extends ST_SniperRifle;

var string Allow55;

simulated function PlayFiring()
{
	local int r;
	local PlayerPawn PPOwner;
	PPOwner = PlayerPawn(Owner);
	
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*3.0);
	
	if (PPOwner.bIsCrouching || PPOwner.GetAnimGroup(PPOwner.AnimSequence) == 'Ducking' || VSize(PPOwner.Velocity) < 10 && PPOwner.Physics != PHYS_Falling && PPOwner.Base != None)
		SniperSpeed = class'UTPure'.default.H4xSpeed;
	else
		SniperSpeed = 1;
	
	PlayAnim(FireAnims[Rand(5)], 0.5 * SniperSpeed + 0.5 * FireAdjust, 0.05);

	if ( (PlayerPawn(Owner) != None) 
		&& (PlayerPawn(Owner).DesiredFOV == PlayerPawn(Owner).DefaultFOV) )
		bMuzzleFlash++;
}

function Fire( float Value )
{
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;
	
	bbPlayer(Owner).xxAddFired(zzWin);
	
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	
	GotoState('NormalFire');
	bCanClientFire = true;
	bPointing=True;
	if ( Owner.IsA('Bot') )
	{
		// simulate bot using zoom
		if ( Bot(Owner).bSniping && (FRand() < 0.65) )
			AimError = AimError/FClamp(StillTime, 1.0, 8.0);
		else if ( VSize(Owner.Location - OwnerLocation) < 6 )
			AimError = AimError/FClamp(0.5 * StillTime, 1.0, 3.0);
		else
			StillTime = 0;
	}
	Pawn(Owner).PlayRecoil(FiringSpeed);
	TraceFire(0.0);
	AimError = Default.AimError;
	ClientFire(Value);
}

simulated function NN_TraceFire()
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

//	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(GV,X,Y,Z);
	StartTrace = Owner.Location + CDO + yMod * Y + FireOffset.Z * Z;
	
	if (SniperSpeed == 1)
	{
		R1 = NN_GetFRV();
		R2 = NN_GetFRV();
		EndTrace = StartTrace + 0.95 * (R1 - 0.5 )* Y * 1000
			+ 0.95 * (R2 - 0.5 ) * Z * 1000;
		EndTrace += (10000 * vector(GV));
	}
	else
	{
		EndTrace = StartTrace + (100000 * vector(GV)); 
	}
	
	ClientFRVI = bbP.zzNN_FRVI;
	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,PawnOwner);
	if (Other.IsA('Pawn'))
		HitDiff = HitLocation - Other.Location;
	
	bHeadshot = NN_ProcessTraceHit(Other, HitLocation, HitNormal, X,Y,Z,yMod);
	bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, bHeadshot, ClientFRVI);
}

function TraceFire( float Accuracy )
{
	local bbPlayer bbP;
	local vector NN_HitLoc, HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local float R1, R2;
	
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
	
	if (SniperSpeed == 1)
	{
		R1 = GetFRV();
		R2 = GetFRV();
		EndTrace = StartTrace + 0.95 * (R1 - 0.5 )* Y * 1000
			+ 0.95 * (R2 - 0.5 ) * Z * 1000;
	}
	else
	{
		EndTrace = StartTrace + 10000 * X;
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
	
	ProcessTraceHit(bbP.zzNN_HitActor, NN_HitLoc, HitNormal, X,Y,Z);
	bbP.zzNN_HitActor = None;
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

state Idle
{
	function Fire( float Value )
	{
		Global.Fire(Value);
	}
}

defaultproperties {
    PickupAmmoCount=100
	HitDamage=45
	HeadDamage=100
	BodyHeight=0.62
	SniperSpeed=1
	Allow55="TRUE"
	zzWin=55
	PickupMessage="You got the H4X Rifle."
	ItemName="H4X Rifle"
}