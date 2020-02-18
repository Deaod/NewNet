//=============================================================================
// ST_FlakCannon.
//=============================================================================
class ST_FlakCannon extends ST_UnrealWeapons;

var bool bEjected;

function float SuggestAttackStyle()
{
	local bot B;

	B = Bot(Owner);
	if ( (B != None) && B.bNovice )
		return 0.2;
	return 0.4;
}

function float SuggestDefenseStyle()
{
	return -0.3;
}

function float RateSelf( out int bUseAltMode )
{
	local float EnemyDist, rating;
	local vector EnemyDir;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;
	if ( Pawn(Owner).Enemy == None )
	{
		bUseAltMode = 0;
		return AIRating;
	}
	EnemyDir = Pawn(Owner).Enemy.Location - Owner.Location;
	EnemyDist = VSize(EnemyDir);
	rating = FClamp(AIRating - (EnemyDist - 450) * 0.001, 0.2, AIRating);
	if ( Pawn(Owner).Enemy.IsA('StationaryPawn') )
	{
		bUseAltMode = 0;
		return AIRating + 0.3;
	}
	if ( EnemyDist > 900 )
	{
		bUseAltMode = 0;
		if ( EnemyDist > 2000 )
		{
			if ( EnemyDist > 3500 )
				return 0.2;
			return (AIRating - 0.3);
		}			
		if ( EnemyDir.Z < -0.5 * EnemyDist )
		{
			bUseAltMode = 1;
			return (AIRating - 0.3);
		}
	}
	else if ( (EnemyDist < 750) && (Pawn(Owner).Enemy.Weapon != None) && Pawn(Owner).Enemy.Weapon.bMeleeWeapon )
	{
		bUseAltMode = 0;
		return (AIRating + 0.3);
	}
	else if ( (EnemyDist < 340) || (EnemyDir.Z > 30) )
	{
		bUseAltMode = 0;
		return (AIRating + 0.2);
	}
	else
		bUseAltMode = int( FRand() < 0.65 );
	return rating;
}

simulated function bool ClientFire( float Value )
{
	local Vector Start, X,Y,Z;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local ST_UTChunk Proj;
	local int ProjIndex;

	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Value < 1)
			return false;
		
		yModInit();
		PawnOwner = Pawn(Owner);

		if ( AmmoType == None )
		{
			GiveAmmo(PawnOwner);
		}
		if (AmmoType.AmmoAmount > 0)
		{
			bbP.xxNN_Fire(bbP.zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, None, vect(0,0,0), vect(0,0,0), false, bbP.zzFRVI);
			
			Instigator = Pawn(Owner);
			bCanClientFire = true;
			bPointing=True;
			PawnOwner.PlayRecoil(FiringSpeed);

			GetAxes(GV,X,Y,Z);
			Start = Owner.Location + CDO;
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));	
			Start = Start + FireOffset.X * X + yMod * Y + FireOffset.Z * Z;	
			
			Proj = Spawn( class 'ST_UTChunk1',Owner, '', Start, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk2',Owner, '', Start - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk3',Owner, '', Start + 2 * Y + Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y + Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk4',Owner, '', Start - Y, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start - Y, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk1',Owner, '', Start + 2 * Y - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk2',Owner, '', Start, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk3',Owner, '', Start + Y - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + Y - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTChunk4',Owner, '', Start + 2 * Y + Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y + Z, Proj.Velocity, Proj.Acceleration, GV);
			
			GoToState('NormalFire');
		}
	}
	return Super.ClientFire(Value);
}

simulated function bool ClientAltFire( float Value )
{
	local Vector Start, X,Y,Z;
	local Pawn PawnOwner;
	local ST_FlakSlug Proj;
	local int ProjIndex;
	local bbPlayer bbP;

	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Value < 1)
			return false;
		
		yModInit();
		PawnOwner = Pawn(Owner);

		if ( AmmoType == None )
		{
			GiveAmmo(PawnOwner);
		}
		if (AmmoType.AmmoAmount > 0)
		{
			bbP.xxNN_AltFire(bbP.zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, None, vect(0,0,0), vect(0,0,0), false, bbP.zzFRVI);
			
			Instigator = Pawn(Owner);
			PawnOwner.PlayRecoil(FiringSpeed);
			bPointing=True;
			bCanClientFire = true;
			
			PawnOwner = Pawn(Owner);
			GetAxes(GV,X,Y,Z);
			Start = PawnOwner.Location + CDO;
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));	
			Start = Start + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
			AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, Start, AimError, True, bAltWarnTarget);
				
			Proj = Spawn(class'ST_FlakSlug',Owner,, Start,AdjustedAim);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'FlakSlug', Start, Proj.Velocity, Proj.Acceleration, AdjustedAim);
		}
	}
	return Super.ClientAltFire(Value);
}

function Fire( float Value )
{
	local Vector Start, X,Y,Z;
	local Bot B;
	local ST_UTChunkInfo CI;
	local NN_UTChunkOwnerHidden COH;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local float OwnerPing;
	
	if (Owner.IsA('Bot'))
	{
		Super(UT_FlakCannon).Fire(Value);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;

	PawnOwner = Pawn(Owner);

	if ( AmmoType == None )
	{
		GiveAmmo(PawnOwner);
	}
	if (AmmoType.UseAmmo(1))
	{
		bCanClientFire = true;
		bPointing=True;
		B = Bot(PawnOwner);
		PawnOwner.MakeNoise(2.0 * PawnOwner.SoundDampening);
		if (bbP == None || !bNewNet)
		{
			Start = PawnOwner.Location + CalcDrawOffset();
			AdjustedAim = PawnOwner.AdjustAim(AltProjectileSpeed, Start, AimError, True, bWarnTarget);
			GetAxes(AdjustedAim,X,Y,Z);
			Start = Start + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z;	
		}
		else
		{
			AdjustedAim = bbP.zzNN_ViewRot;
			GetAxes(AdjustedAim,X,Y,Z);
			if (Mover(bbP.Base) == None)
				Start = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			else
				Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}
		if (bNewNet)
			Spawn(class'NN_WeaponLightOwnerHidden',Owner,'',Start+X*20,rot(0,0,0));		
		else
		{
			PawnOwner.PlayRecoil(FiringSpeed);
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));		
		}
		CI = Spawn(class'ST_UTChunkInfo', PawnOwner);
		OwnerPing = float(Owner.ConsoleCommand("GETPING"));

		if (bNewNet)
		{
			COH = Spawn( class 'NN_UTChunk1OwnerHidden',Owner, '', Start, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTChunk2OwnerHidden',Owner, '', Start - Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTChunk3OwnerHidden',Owner, '', Start + 2 * Y + Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTChunk4OwnerHidden',Owner, '', Start - Y, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTChunk1OwnerHidden',Owner, '', Start + 2 * Y - Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTChunk2OwnerHidden',Owner, '', Start, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
		}
		else
		{
			CI.AddChunk(Spawn( class 'ST_UTChunk1',Owner, '', Start, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTChunk2',Owner, '', Start - Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTChunk3',Owner, '', Start + 2 * Y + Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTChunk4',Owner, '', Start - Y, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTChunk1',Owner, '', Start + 2 * Y - Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTChunk2',Owner, '', Start, AdjustedAim));
		}
		if ( (B == None) || !B.bNovice || ((B.Enemy != None) && (B.Enemy.Weapon != None) && B.Enemy.Weapon.bMeleeWeapon) )
		{
			if (bNewNet)
			{
				COH = Spawn( class 'NN_UTChunk3OwnerHidden',Owner, '', Start + Y - Z, AdjustedAim);
				COH.NN_OwnerPing = OwnerPing;
				CI.AddChunk(COH);
				
				COH = Spawn( class 'NN_UTChunk4OwnerHidden',Owner, '', Start + 2 * Y + Z, AdjustedAim);
				COH.NN_OwnerPing = OwnerPing;
				CI.AddChunk(COH);
				
			}
			else
			{
				CI.AddChunk(Spawn( class 'ST_UTChunk3',Owner, '', Start + Y - Z, AdjustedAim));
				CI.AddChunk(Spawn( class 'ST_UTChunk4',Owner, '', Start + 2 * Y + Z, AdjustedAim));
			}
		}
		else if ( B.Skill > 1 )
			CI.AddChunk(Spawn( class 'ST_UTChunk3',Owner, '', Start + Y - Z, AdjustedAim));
		
		ClientFire(Value);
		GoToState('NormalFire');
	}
}

function AltFire( float Value )
{
	local Vector Start, X,Y,Z;
	local ST_FlakSlug Slug;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local NN_FlakSlugOwnerHidden NNFS;
	
	if (Owner.IsA('Bot'))
	{
		Super(UT_FlakCannon).AltFire(Value);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;

	PawnOwner = Pawn(Owner);

	if ( AmmoType == None )
	{
		GiveAmmo(PawnOwner);
	}
	if (AmmoType.UseAmmo(1))
	{
		bPointing=True;
		bCanClientFire = true;
		PawnOwner.MakeNoise(PawnOwner.SoundDampening);

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
		AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, Start, AimError, True, bAltWarnTarget);	
		ClientAltFire(Value);
		if (bNewNet) {
			Spawn(class'NN_WeaponLightOwnerHidden',Owner,'',Start+X*20,rot(0,0,0));
			NNFS = Spawn(class'NN_FlakSlugOwnerHidden',Owner,, Start,AdjustedAim);
			if (bbP != None)
				NNFS.zzNN_ProjIndex = bbP.xxNN_AddProj(NNFS);
		} else {
			PawnOwner.PlayRecoil(FiringSpeed);
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));
			Slug = Spawn(class'ST_FlakSlug',,, Start,AdjustedAim);
		}
		GoToState('AltFiring');
	}
}

simulated function PlayFiring()
{
	PlayAnim( 'Fire', 0.9, 0.05);
	PlayOwnedSound(FireSound, SLOT_Misc,Pawn(Owner).SoundDampening*4.0);	
}

simulated function PlayAltFiring()
{
	PlayAnim('AltFire', 1.3, 0.05);
	PlayOwnedSound(AltFireSound, SLOT_Misc,Pawn(Owner).SoundDampening*4.0);
}

simulated function PlayReloading()
{
	PlayAnim('Loading',0.65, 0.05);
	Owner.PlayOwnedSound(CockingSound, SLOT_None,0.5*Pawn(Owner).SoundDampening);		
}

simulated function PlayFastReloading()
{
	PlayAnim('Loading',1.4, 0.05);
	Owner.PlayOwnedSound(CockingSound, SLOT_None,0.5*Pawn(Owner).SoundDampening);		
}

simulated function PlayEjecting()
{
	PlayAnim('Eject',1.5, 0.05);
	Owner.PlayOwnedSound(Misc3Sound, SLOT_None,0.6*Pawn(Owner).SoundDampening);
}

simulated function PlayPostSelect()
{
	PlayAnim('Loading', 1.3, 0.05);
	Owner.PlayOwnedSound(Misc2Sound, SLOT_None,1.3*Pawn(Owner).SoundDampening);	
}

simulated function TweenDown()
{
	if ( GetAnimGroup(AnimSequence) == 'Select' )
		TweenAnim( AnimSequence, AnimFrame * 0.4 );
	else
	{
		if (AmmoType.AmmoAmount<=0)
			PlayAnim('Down2',1.0, 0.05);
		else
			PlayAnim('Down',1.0, 0.05);
	}
}

simulated function PlayIdleAnim()
{
	if ( Mesh == PickupViewMesh )
		return;
	LoopAnim('Sway',0.01,0.3);
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'UT_FlakCannon');
}

state ClientReload
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
		bForceFire = false;
		bForceAltFire = false;
	}

	simulated function BeginState()
	{
		bForceFire = false;
		bForceAltFire = false;
	}
}

state ClientFiring
{
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (Ammotype.AmmoAmount <= 0) )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if (bEjected)
		{
			PlayFastReloading();
			bEjected=False;
			GotoState('ClientReload');
		}
		else
		{
			PlayEjecting();
			bEjected=True;
		}
	}
		simulated function EndState()
		{
			bEjected = false;
		}
}

state ClientAltFiring
{
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (Ammotype.AmmoAmount <= 0) )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else
		{
			PlayReloading();
			GotoState('ClientReload');
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
	function EndState()
	{
		Super.EndState();
		OldFlashCount = FlashCount;
	}
/* 	function AnimEnd()
	{
		if ( (AnimSequence != 'Loading') && (AmmoType.AmmoAmount > 0) )
			PlayFastReloading();
		else
			Finish();
	}
 */
Begin:

      if ( (!bEjected) && (AnimSequence != 'Eject') && (AnimSequence != 'Loading') && (AmmoType.AmmoAmount > 0) )
	  {
		  FinishAnim();
		  PlayEjecting();
		  //bEjected=True; }
		  //if ( (bEjected) && (AnimSequence != 'Eject')&&(AmmoType.AmmoAmount > 0) )
		  FinishAnim();
		  PlayFastReloading();
		  FinishAnim();
      }
      Finish();
      bEjected=False;
}

state AltFiring
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
	function AnimEnd()
	{
		if ( (AnimSequence != 'Loading') && (AmmoType.AmmoAmount > 0) )
			PlayReloading();
		else
			Finish();
	}
		
Begin:
	FlashCount++;
}

defaultproperties
{
    WeaponDescription="Classification: Heavy Shrapnel\n\nPrimary Fire: Extremely fast spray of shrapnal, which ricochet off walls, ceilings, and floors.\n\nSecondary Fire: Large, Shrapnel-filled shell explodes on impact, spraying shrapnel in all directions. \n\nTechniques: The Flak Cannon is far more useful in close range combat situations."
    AmmoName=Class'ST_FlakBox'
    PickupAmmoCount=10
    bWarnTarget=True
    bAltWarnTarget=True
    bSplashDamage=True
    FireOffset=(X=10.00,Y=-12.00,Z=-15.00),
    shakemag=350.00
    shaketime=0.15
    shakevert=8.50
    AIRating=0.80
    FireSound=Sound'UnrealShare.flak.shot1'
    AltFireSound=Sound'UnrealShare.flak.Explode1'
    CockingSound=Sound'UnrealI.flak.load1'
    SelectSound=Sound'UnrealI.flak.pdown'
    Misc2Sound=Sound'UnrealI.flak.Hidraul2'
    Misc3Sound=Sound'UnrealShare.flak.Click'
    DeathMessage="%o was ripped to shreds by %k's %w."
    AutoSwitchPriority=8
    InventoryGroup=8
    PickupMessage="You got the Flak Cannon"
    ItemName="Flak Cannon"
    PlayerViewOffset=(X=2.10,Y=-1.50,Z=-1.25),
    PlayerViewMesh=LodMesh'UnrealI.flak'
    PlayerViewScale=1.20
    PickupViewMesh=LodMesh'UnrealI.FlakPick'
    ThirdPersonMesh=LodMesh'UnrealI.Flak3rd'
    StatusIcon=Texture'UseFC'
    Icon=Texture'UseFC'
    Mesh=LodMesh'UnrealI.FlakPick'
    CollisionRadius=27.00
    CollisionHeight=23.00
    LightBrightness=228
    LightHue=30
    LightSaturation=71
    LightRadius=14
}