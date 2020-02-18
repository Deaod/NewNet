class ST_HyperLeecher extends ST_WildcardsWeapons;

var Rotator LastGV;
var name LastState;
var float ChargeSize, Count;
var bool bBurst;

replication
{
	reliable if ( Role < ROLE_Authority )
		ServerForceFire, ServerForceAltFire, ServerShootLoad;
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

	default.SelectSound = OrgClass.default.SelectSound;
	SelectSound = default.SelectSound;

	default.AmmoName = OrgClass.default.AmmoName;
	AmmoName = default.AmmoName;

	default.bMeshEnviroMap = OrgClass.default.bMeshEnviroMap;
	bMeshEnviroMap = default.bMeshEnviroMap;

	default.Texture = OrgClass.default.Texture;
	Texture = default.Texture;

 	if ( Role == ROLE_Authority )
	{
		Spawn(class'ST_HyperLeecherLoader').TW = OrgClass;
	}
}

function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (ROLE == ROLE_Authority)
	{
		if (bNewNet)
		{
			ProjectileClass = Class'NN_UT_BioGelOwnerHidden';
			AltProjectileClass = Class'NN_BioGlobOwnerHidden';
		}
	}
}

simulated function PlayIdleAnim()
{
	if ( Mesh == PickupViewMesh )
		return;
	if ( (Owner != None) && (VSize(Owner.Velocity) > 10) )
		PlayAnim('Walking',0.3,0.3);
	else 
		TweenAnim('Still', 1.0);
	Enable('AnimEnd');
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
		// only use if enemy not too far and retreating
		if ( !bRetreating )
			return 0;

		return AIRating;
	}

	bUseAltMode = int( FRand() < 0.3 );

	if ( bRetreating || (EnemyDir.Z < -0.7 * EnemyDist) )
		return (AIRating + 0.18);
	return AIRating;
}

// return delta to combat style
function float SuggestAttackStyle()
{
	return -0.3;
}

function float SuggestDefenseStyle()
{
	return -0.4;
}

function AltFire( float Value )
{
	bPointing=True;
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) ) 
	{
		GoToState('AltFiring');
		bCanClientFire = true;
		ClientAltFire(Value);
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
	local ST_UT_BioGel ST_Proj;
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
			// ammocheck
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
			ST_Proj = ST_UT_BioGel(Proj);
			if (ST_Proj != None)
				ST_Proj.zzNN_ProjIndex = ProjIndex;
			
			bbP.xxNN_Fire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			bbP.xxClientDemoFix(Proj, class'UT_BioGel', Start, Proj.Velocity, Proj.Acceleration, AdjustedAim);
		}
	}
		
	return Super.ClientFire(Value);
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
		PlayAltFiring();
		if ( Role < ROLE_Authority )
			GotoState('ClientAltFiring');
		bResult = true;
		
		bbP.xxNN_AltFire(-2, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
		
	}
	InstFlash = Default.InstFlash;
	
	return bResult;
}

function Fire( float Value )
{
	local bbPlayer bbP;
	local NN_UT_BioGelOwnerHidden NNBG;
	
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	
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
			NNBG = NN_UT_BioGelOwnerHidden(ProjectileFire(class'NN_UT_BioGelOwnerHidden', ProjectileSpeed, bWarnTarget));
			//NNBG.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
			bbP = bbPlayer(Owner);
			if (bbP != None)
				NNBG.zzNN_ProjIndex = bbP.xxNN_AddProj(NNBG);
		}
		else
			ProjectileFire(ProjectileClass, ProjectileSpeed, bWarnTarget);
	}
}

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
	AdjustedAim = pawn(owner).AdjustToss(ProjSpeed, Start, 0, True, bWarn);	
	return Spawn(ProjClass,Owner,, Start,AdjustedAim);
}

state ClientAltFiring
{
	simulated function Tick(float DeltaTime)
	{
		//SetLocation(Owner.Location);
		if ( ChargeSize < 4.1 )
		{
			Count += DeltaTime;
			if ( (Count > 0.5) && AmmoType.AmmoAmount > 0 )
			{
				ChargeSize += Count;
				Count = 0;
				if ( (PlayerPawn(Owner) == None) && (FRand() < 0.2) )
					GoToState('ClientShootLoad');
			}
		}
		if( (pawn(Owner).bAltFire==0) ) {
			GoToState('ClientShootLoad');
		}
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
			TweenAnim('Loaded', 0.5);
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
	ignores AnimEnd;

	function Tick( float DeltaTime )
	{
		//SetLocation(Owner.Location);
		if ( ChargeSize < 4.1 )
		{
			Count += DeltaTime;
			if ( (Count > 0.5) && AmmoType.UseAmmo(1) )
			{
				ChargeSize += Count;
				Count = 0;
				if ( (PlayerPawn(Owner) == None) && (FRand() < 0.2) )
					GoToState('ShootLoad');
			}
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
			TweenAnim('Loaded', 0.5);
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

	function Fire(float F) 
	{
	}

	function AltFire(float F) 
	{
	}

	function Timer()
	{
		local rotator R;
		local vector start, X,Y,Z;
		local bbPlayer bbP;
		local NN_BioGlobOwnerHidden NNBG;
		
		if (Owner.IsA('Bot'))
		{
			Super.Timer();
			return;
		}
		
		bbP = bbPlayer(Owner);
		
		yModInit();

		if (bbP == None || !bNewNet)
		{
			GetAxes(Pawn(Owner).ViewRotation,X,Y,Z);
			Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			R = Owner.Rotation;
			R.Yaw += 2000;
			R.Pitch -= 500;
			Spawn(class'NN_BioGlobOwnerHidden',Owner,, Start,R);
			
			R.Yaw -= 3000;
			R.Pitch += 750;
			Spawn(class'NN_BioGlobOwnerHidden',Owner,, Start,R);
		}
		else
		{
			GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
			if (Mover(bbP.Base) == None)
				Start = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			else
				Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			R = bbP.zzNN_ViewRot;
			R.Yaw += 2000;
			R.Pitch -= 500;
			NNBG = Spawn(class'NN_BioGlobOwnerHidden',Owner,, Start,R);
			NNBG.zzNN_ProjIndex = bbP.xxNN_AddProj(NNBG);
			
			R.Yaw -= 3000;
			R.Pitch += 750;
			NNBG = Spawn(class'NN_BioGlobOwnerHidden',Owner,, Start,R);
			NNBG.zzNN_ProjIndex = bbP.xxNN_AddProj(NNBG);
		}
	}

	function AnimEnd()
	{
		Finish();
	}

	function BeginState()
	{
		Local ST_BioGlob BG;
		local bbPlayer bbP;
		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}

		BG = ST_BioGlob(ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget));
		if (bbP != None)
			BG.zzNN_ProjIndex = bbP.xxNN_AddProj(BG);
		BG.DrawScale = 1.0 + 0.8 * ChargeSize;
		PlayAltBurst();
	}
	
Begin:
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
	
	simulated function bool ClientFire(float F) {
		if (Owner.IsA('Bot'))
			return Super.ClientFire(F);
		bForceFire = true;
		ServerForceFire();
	}
	simulated function bool ClientAltFire(float F) {
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(F);
		bForceAltFire = true;
		ServerForceAltFire();
	}
	
	simulated function Timer()
	{
		local rotator R;
		local vector start, X,Y,Z;
		local bbPlayer bbP;
		local ST_BioGlob BG;
		
		if (Owner.IsA('Bot'))
		{
			Super.Timer();
			return;
		}
		
		bbP = bbPlayer(Owner);
		if ( bbP == None || bbP.IsInState('Dying') || bbP.Weapon != Self )
			return;

		GetAxes(LastGV,X,Y,Z);
		Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z;
		R = LastGV;
		
		R.Yaw += 2000;
		R.Pitch -= 500;
		BG = ST_BioGlob(Spawn(Default.AltProjectileClass,Owner,, Start,R));
		BG.zzNN_ProjIndex = bbP.xxNN_AddProj(BG);
		bbP.xxClientDemoFix(BG, class'BioGlob', Start, BG.Velocity, BG.Acceleration, R);
		
		R.Yaw -= 3000;
		R.Pitch += 750;
		BG = ST_BioGlob(Spawn(Default.AltProjectileClass,Owner,, Start,R));
		BG.zzNN_ProjIndex = bbP.xxNN_AddProj(BG);
		bbP.xxClientDemoFix(BG, class'BioGlob', Start, BG.Velocity, BG.Acceleration, R);
	}

	simulated function AnimEnd()
	{
		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
		ClientFinish();
	}

	simulated function BeginState()
	{
		local Vector Start, X,Y,Z;
		local ST_BioGlob BG;
		local bbPlayer bbP;
		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}
		
		yModInit();

		bbP = bbPlayer(Owner);
		if ( bbP == None || bbP.IsInState('Dying') || bbP.Weapon != Self )
			return;
		
		LastGV = GV;
		GetAxes(GV,X,Y,Z);
		Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
		AdjustedAim = pawn(owner).AdjustToss(AltProjectileSpeed, Start, 0, True, bAltWarnTarget);
		
		ServerShootLoad(bbP.zzNN_ProjIndex, bbP.Location.X, bbP.Location.Y, bbP.Location.Z, GV.Pitch, GV.Yaw, GV.Roll, bbP.zzNN_FRVI);

		BG = ST_BioGlob(Spawn(Default.AltProjectileClass,Owner,, Start, AdjustedAim));
		BG.zzNN_ProjIndex = bbP.xxNN_AddProj(BG);
		BG.DrawScale = 1.0 + 0.8 * ChargeSize;
		bbP.xxClientDemoFix(BG, class'BioGlob', Start, BG.Velocity, BG.Acceleration, AdjustedAim, BG.DrawScale);
		
		PlayAltBurst();
	}

Begin:
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
	PlayOwnedSound(FireSound, SLOT_Misc, 1.7*Pawn(Owner).SoundDampening);	//shoot goop
	PlayAnim('Fire',5, 0.05);
}

simulated function PlayFiring()
{
	PlayOwnedSound(AltFireSound, SLOT_None, 1.7*Pawn(Owner).SoundDampening);	//fast fire goop
	//LoopAnim('Fire',0.65 + 0.4 * FireAdjust, 0.05);
	PlayAnim('Fire', 2.5, 0.05);
}

simulated function PlayAltFiring()
{
	PlayOwnedSound(Sound'Botpack.BioRifle.BioAltRep', SLOT_Misc, 1.3*Pawn(Owner).SoundDampening);	 //loading goop	
	PlayAnim('Charging',0.24,0.05);
}

defaultproperties
{
	ProjectileClass=Class'ST_UT_BioGel'
	AltProjectileClass=Class'ST_BioGlob'
	AmmoName=Class'ST_HyperLeecherAmmo'
	PickupAmmoCount=100
	PickupMessage="You Found The Hyper Leecher"
	ItemName="Hyper Leecher"
	WeaponDescription="Classification: Toxic Rifle\n\nPrimary Fire: Wads of Tarydium byproduct are lobbed at a medium rate of fire.\n\nSecondary Fire: When trigger is held down, the BioRifle will create a much larger wad of byproduct. When this wad is launched, it will burst into smaller wads which will adhere to any surfaces.\n\nTechniques: Byproducts will adhere to walls, floors, or ceilings. Chain reactions can be caused by covering entryways with this lethal green waste."
	InstFlash=-0.150000
	InstFog=(X=139.000000,Y=218.000000,Z=72.000000)
	AmmoName=Class'Botpack.BioAmmo'
	bAltWarnTarget=True
	bRapidFire=True
	FiringSpeed=1.000000
	FireOffset=(X=12.000000,Y=-11.000000,Z=-6.000000)
	AIRating=0.600000
	RefireRate=0.900000
	AltRefireRate=0.700000
	FireSound=Sound'UnrealI.BioRifle.GelShot'
	AltFireSound=Sound'UnrealI.BioRifle.GelShot'
	CockingSound=Sound'UnrealI.BioRifle.GelLoad'
	SelectSound=Sound'UnrealI.BioRifle.GelSelect'
	DeathMessage="%o drank a glass of %k's dripping green load."
	NameColor=(R=0,B=0)
	AutoSwitchPriority=3
	InventoryGroup=3
	PlayerViewOffset=(X=1.700000,Y=-0.850000,Z=-0.950000)
	PlayerViewMesh=LodMesh'Botpack.BRifle2'
	BobDamping=0.972000
	PickupViewMesh=LodMesh'Botpack.BRifle2Pick'
	ThirdPersonMesh=LodMesh'Botpack.BRifle23'
	StatusIcon=Texture'Botpack.Icons.UseBio'
	PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
	Icon=Texture'Botpack.Icons.UseBio'
	Mesh=LodMesh'Botpack.BRifle2Pick'
	CollisionHeight=19.000000
}
