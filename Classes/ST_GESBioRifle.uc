//=============================================================================
// ST_GESBioRifle.
//=============================================================================
class ST_GESBioRifle expands ST_UnrealWeapons;

var Rotator LastGV;
var name LastState;
var float ChargeSize,Count;
var bool bBurst;

replication
{
	reliable if ( Role < ROLE_Authority )
		ServerForceFire, ServerForceAltFire, ServerShootLoad;
}

function float RateSelf( out int bUseAltMode )
{
	local float EnemyDist;
	local bool bRetreating;
	local vector EnemyDir;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;
	bUseAltMode = 0;
	if ( Pawn(Owner).Enemy == None )
		return AIRating;

	EnemyDir = Pawn(Owner).Enemy.Location - Owner.Location;
	EnemyDist = VSize(EnemyDir);
	if ( EnemyDist > 1400 )
		return 0;

	bRetreating = ( ((EnemyDir/EnemyDist) Dot Owner.Velocity) < -0.6 );
	if ( (EnemyDist > 600) && (EnemyDir.Z > -0.4 * EnemyDist) )
	{
		if ( !bRetreating )
			return 0;

		return AIRating;
	}

	bUseAltMode = int( FRand() < 0.3 );

	if ( bRetreating || (EnemyDir.Z < -0.7 * EnemyDist) )
		return (AIRating + 0.18);
	return AIRating;
}

function float SuggestAttackStyle()
{
	return -0.3;
}

function float SuggestDefenseStyle()
{
	return -0.4;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (ROLE == ROLE_Authority)
	{
		if (bNewNet)
		{
			ProjectileClass = Class'NN_BioGelOwnerHidden';
			AltProjectileClass = Class'NN_BigBioGelOwnerHidden';
		}
	}
}

exec function ServerForceFire()
{
	bForceFire = true;
}

exec function ServerForceAltFire()
{
	bForceAltFire = true;
}

exec function ServerShootLoad( int ProjIndex, float ClientLocX, float ClientLocY, float ClientLocZ, int ViewPitch, int ViewYaw, int ViewRoll, optional int ClientFRVI )
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return;
	
	bbP.zzNN_ProjIndex = ProjIndex;
	bbP.zzNN_ClientLoc.X = ClientLocX;
	bbP.zzNN_ClientLoc.Y = ClientLocY;
	bbP.zzNN_ClientLoc.Z = ClientLocZ;
	bbP.zzNN_ViewRot.Pitch = ViewPitch;
	bbP.zzNN_ViewRot.Yaw = ViewYaw;
	bbP.zzNN_ViewRot.Roll = ViewRoll;
	bbP.zzNN_FRVI = ClientFRVI;
	bbP.zzFRVI = ClientFRVI;
	bbP.zzbNN_ReleasedAltFire = true;
	
	GotoState('ShootLoad');
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'ut_biorifle');
}

simulated function bool ClientFire(float Value)
{
	local Vector Start, X,Y,Z;
	local rotator AdjAim;
	local Projectile Proj;
	local ST_BioGel ST_Proj;
	local int ProjIndex;
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
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			yModInit();
			
			Instigator = Pawn(Owner);
			GotoState('ClientFiring');
			bPointing=True;
			bCanClientFire = true;
			if ( bRapidFire || (FiringSpeed > 0) )
				Pawn(Owner).PlayRecoil(FiringSpeed);

			GetAxes(GV,X,Y,Z);
			Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
			AdjustedAim = pawn(owner).AdjustToss(ProjectileSpeed, Start, 0, True, bWarnTarget);	
			
			Proj = Spawn(Default.ProjectileClass,Owner,, Start, AdjustedAim);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			ST_Proj = ST_BioGel(Proj);
			if (ST_Proj != None)
				ST_Proj.zzNN_ProjIndex = ProjIndex;
			
			bbP.xxNN_Fire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			bbP.xxClientDemoFix(Proj, class'BioGel', Start, Proj.Velocity, Proj.Acceleration, AdjustedAim);
		}
	}
	return Super.ClientFire(Value);
}

function Fire( float Value )
{
	local bbPlayer bbP;
	local NN_BioGelOwnerHidden NNBG;
	
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	
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
		if (!bNewNet && (bRapidFire || (FiringSpeed > 0) ) )
		{
			Pawn(Owner).PlayRecoil(FiringSpeed);
		}
		if (bNewNet)
		{
			NNBG = NN_BioGelOwnerHidden(ProjectileFire(class'NN_BioGelOwnerHidden', ProjectileSpeed, bWarnTarget));
			bbP = bbPlayer(Owner);
			if (bbP != None)
				NNBG.zzNN_ProjIndex = bbP.xxNN_AddProj(NNBG);
		}
		else
			ProjectileFire(ProjectileClass, ProjectileSpeed, bWarnTarget);
	}
}

function AltFire( float Value )
{
	bPointing=True;
	if ( AmmoType == None )
	{
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) ) 
	{
		GoToState('AltFiring');
		bCanClientFire = true;
		ClientAltFire(Value);
	}
}

simulated function bool ClientAltFire( float Value )
{
	local bool bResult;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (bbP == None || bbP.ClientCannotShoot() || bbP.Weapon != Self)
		return false;

	InstFlash = 0.0;
	if ( (bCanClientFire || bNewNet && Level.NetMode == NM_Client) && ((Role == ROLE_Authority) || (AmmoType == None) || (AmmoType.AmmoAmount > 0)) )
	{
		yModInit();
		
		Instigator = Pawn(Owner);

		if ( Affector != None )
			Affector.FireEffect();
		PlayAltFiring();
		if ( Role < ROLE_Authority )
			GotoState('ClientAltFiring');
		bResult = true;
		
		bbP.xxNN_AltFire(-2, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
		
	}
	InstFlash = Default.InstFlash;
	
	return bResult;
}

state ClientAltFiring
{
	simulated function Tick(float DeltaTime)
	{
		ChargeSize += DeltaTime;
		Count += DeltaTime;
		if (Count > 1.0) 
		{
			Count = 0.0;
			if ( (PlayerPawn(Owner) == None) && (FRand() < 0.3) )
				GoToState('ClientShootLoad');
			else if (!AmmoType.UseAmmo(1)) 
				GoToState('ClientShootLoad');
		}
		if( (pawn(Owner).bAltFire==0)) 
			GoToState('ClientShootLoad');
		if ( bBurst )
			return;
		if ( !bCanClientFire || (Pawn(Owner) == None) )
			GotoState('');
		else if ( Pawn(Owner).bAltFire == 0 )
		{
			PlayAltBurst();
			bBurst = true;
		}
	}

	simulated function AnimEnd()
	{
		if ( bBurst )
		{
			bBurst = false;
			Super.AnimEnd();
		}
		else
		{
			PlayAltBurst();
			bBurst = true;
		}
		GoToState('ClientShootLoad');
	}
	
	simulated function BeginState()
	{
		ChargeSize = 0.0;
		Count = 0.0;
	}

	simulated function EndState()
	{
		ChargeSize = FMin(ChargeSize, 4.1);
	}

Begin:
	if (!Owner.IsA('Bot'))
		FinishAnim();
}

state AltFiring
{
	function Tick( float DeltaTime )
	{
		ChargeSize += DeltaTime;
		Count += DeltaTime;
		if (Count > 1.0) 
		{
			Count = 0.0;
			if ( (PlayerPawn(Owner) == None) && (FRand() < 0.3) )
				GoToState('ShootLoad');
			else if (!AmmoType.UseAmmo(1)) 
				GoToState('ShootLoad');
		}
		if( pawn(Owner).bAltFire==0)
		{
			if (bNewNet)
				GoToState('Idle');
			else
				GoToState('ShootLoad');
		}
	}

	simulated function AnimEnd()
	{
		if ( bBurst )
		{
			bBurst = false;
			Super.AnimEnd();
		}
		else
		{
			PlayAltBurst();
			bBurst = true;
		}
		GoToState('ShootLoad');
	}
	
	simulated function BeginState()
	{
		ChargeSize = 0.0;
		Count = 0.0;
	}

	simulated function EndState()
	{
		ChargeSize = FMin(ChargeSize, 4.1);
	}

Begin:
	if (!Owner.IsA('Bot'))
		FinishAnim();
}

state ShootLoad
{
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
		Local ST_BigBioGel BG;
		local bbPlayer bbP;
		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}

		BG = ST_BigBioGel(ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget));
		if (bbP != None)
			BG.zzNN_ProjIndex = bbP.xxNN_AddProj(BG);
		BG.DrawScale = 0.5 + ChargeSize/3.5;
		PlayAltBurst();
	}
}

state ClientShootLoad
{
	simulated function ForceFire()
	{
		bForceFire = true;
	}

	simulated function ForceAltFire()
	{
		bForceAltFire = true;
	}
	
	simulated function bool ClientFire(float F)
	{
		if (Owner.IsA('Bot'))
			return Super.ClientFire(F);
		bForceFire = true;
		ServerForceFire();
	}
	simulated function bool ClientAltFire(float F)
	{
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(F);
		bForceAltFire = true;
		ServerForceAltFire();
	}

	simulated function AnimEnd()
	{
		ClientFinish();
	}

	simulated function BeginState()
	{
		local Vector Start, X,Y,Z;
		local ST_BigBioGel BG;
		local bbPlayer bbP;
		
		yModInit();

		bbP = bbPlayer(Owner);
		if ( bbP == None || bbP.IsInState('Dying') || bbP.Weapon != Self )
			return;
		
		LastGV = GV;
		GetAxes(GV,X,Y,Z);
		Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
		AdjustedAim = pawn(owner).AdjustToss(AltProjectileSpeed, Start, 0, True, bAltWarnTarget);
		
		ServerShootLoad(bbP.zzNN_ProjIndex, bbP.Location.X, bbP.Location.Y, bbP.Location.Z, GV.Pitch, GV.Yaw, GV.Roll, bbP.zzNN_FRVI);

		BG = ST_BigBioGel(Spawn(Default.AltProjectileClass,Owner,, Start, AdjustedAim));
		BG.zzNN_ProjIndex = bbP.xxNN_AddProj(BG);
		BG.DrawScale = 0.5 + ChargeSize/3.5;
		bbP.xxClientDemoFix(BG, class'BigBioGel', Start, BG.Velocity, BG.Acceleration, AdjustedAim, BG.DrawScale);
		
		PlayAltBurst();
	}

Begin:
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;
	local bbPlayer bbP;

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
	AdjustedAim = pawn(owner).AdjustToss(ProjSpeed, Start, 0, True, bWarn);	
	return Spawn(ProjClass,Owner,, Start,AdjustedAim);
}

function Finish()
{
	local bool bForce, bForceAlt;

	bForce = bForceFire;
	bForceAlt = bForceAltFire;
	bForceFire = false;
	bForceAltFire = false;
	if ( bChangeWeapon )
		GotoState('DownWeapon');
	else if ( PlayerPawn(Owner) == None )
	{
		Pawn(Owner).bAltFire = 0;
		Super.Finish();
	}
	else if ( (AmmoType.AmmoAmount<=0) || (Pawn(Owner).Weapon != self) )
		GotoState('Idle');
	else if ( (Pawn(Owner).bFire!=0) || bForce )
		Global.Fire(0);
	else 
		GotoState('Idle');
}

simulated function ClientFinish()
{
	local bool bForce, bForceAlt;

	bForce = bForceFire;
	bForceAlt = bForceAltFire;
	bForceFire = false;
	bForceAltFire = false;

	if ( bChangeWeapon )
		GotoState('DownWeapon');
	else if ( (AmmoType.AmmoAmount<=0) || (Pawn(Owner).Weapon != self) )
		GotoState('Idle');
	else if ( (Pawn(Owner).bFire!=0) || bForce )
		Global.ClientFire(0);
	else if ( (Pawn(Owner).bAltFire!=0) || bForceAlt )
		Global.ClientAltFire(0);
	else 
		GotoState('Idle');
}

simulated function PlayAltBurst()
{
	if ( Affector != None )
		Affector.FireEffect();
	if ( PlayerPawn(Owner) != None && (!bNewNet || Level.NetMode == NM_Client) )
	{
		PlayerPawn(Owner).ClientInstantFlash( InstFlash, InstFog);
		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
	}
	PlayOwnedSound(FireSound, SLOT_Misc, 1.7*Pawn(Owner).SoundDampening,,,fMax(0.5,1.35-ChargeSize/8.0) );
	PlayAnim('Fire',0.4, 0.05);
}

simulated function PlayFiring()
{
	PlayAnim('Fire',1.1, 0.05);
	PlayOwnedSound(AltFireSound, SLOT_None, 1.7*Pawn(Owner).SoundDampening);
}

simulated function PlayAltFiring()
{
	PlayOwnedSound(Misc1Sound, SLOT_Misc, 1.3*Pawn(Owner).SoundDampening);
	PlayAnim('Charging',0.24,0.05);
}

simulated function PlayIdleAnim()
{
	if ( Mesh == PickupViewMesh )
		return;
	if (VSize(Owner.Velocity) > 10)
		PlayAnim('Walking',0.3,0.3);
	else if (FRand() < 0.3 )
		PlayAnim('Drip', 0.1,0.3);
	else
		TweenAnim('Still', 1.0);
	Enable('AnimEnd');
}

simulated function DripSound()
{
	PlayOwnedSound(Misc2Sound, SLOT_None, 0.5*Pawn(Owner).SoundDampening);
}

defaultproperties
{
	WeaponDescription="Classification: Toxic Tarydium waste Rifle\n\nPrimary Fire: Tarydium sludge projectiles explode on contact with living tissue and adhere to most other surfaces for a short time before exploding.\n\nSecondary Fire: Hold down the secondary fire button to launch a larger, more powerful glob of sludge  The longer you hold down the secondary fire button, the bigger the glob (up to 500% sludge).\n\nTechniques: Remember that unlike its newer version, this version will not hold globs forever. Timing is critical!"
	InstFlash=-0.15
	InstFog=(X=139.00,Y=218.00,Z=72.00),
	AmmoName=Class'ST_Sludge'
	PickupAmmoCount=25
	bAltWarnTarget=True
	FireOffset=(X=12.00,Y=-9.00,Z=-16.00),
	ProjectileClass=Class'ST_BioGel'
	AltProjectileClass=Class'ST_BigBioGel'
	AIRating=0.60
	RefireRate=0.90
	AltRefireRate=0.70
	FireSound=Sound'UnrealI.BioRifle.GelShot'
	AltFireSound=Sound'UnrealI.BioRifle.GelShot'
	CockingSound=Sound'UnrealI.BioRifle.GelLoad'
	SelectSound=Sound'UnrealI.BioRifle.GelSelect'
	Misc1Sound=Sound'UnrealI.BioRifle.GelLoad'
	Misc2Sound=Sound'UnrealI.BioRifle.GelDrip'
	DeathMessage="%o drank a glass of %k's dripping green load."
	NameColor=(R=0,G=255,B=0,A=0),
	AutoSwitchPriority=3
	InventoryGroup=3
	PickupMessage="You got the GES Bio Rifle"
	ItemName="GES Bio Rifle"
	PlayerViewOffset=(X=1.92,Y=-0.75,Z=-1.15),
	PlayerViewMesh=LodMesh'UnrealI.BRifle'
	PickupViewMesh=LodMesh'UnrealI.BRiflePick'
	ThirdPersonMesh=LodMesh'UnrealI.BRifle3'
	StatusIcon=Texture'UseGB'
	Icon=Texture'UseGB'
	Mesh=LodMesh'UnrealI.BRiflePick'
	CollisionRadius=28.00
	CollisionHeight=15.00
}