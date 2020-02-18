class h4x_Rifle expands h4x_SniperRifle;

#exec AUDIO IMPORT FILE="Sounds\BLAM.WAV" NAME="BLAM" GROUP="h4xRifle"
#EXEC texture IMPORT NAME=crosshair FILE=Textures\crosshair.pcx MIPS=0 FLAGS=2 GROUP=h4xRifle
#exec AUDIO IMPORT NAME=zoomstart FILE=Sounds\zoomstart.WAV GROUP=h4xRifle
#exec AUDIO IMPORT NAME=zoomstop FILE=Sounds\zoomstop.WAV GROUP=h4xRifle

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

simulated function PostRender( canvas Canvas )
{
   local PlayerPawn P;
   //local float HudScale;
	local float Scale;
        local float Xlength;
        local float range;
        local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
        local actor Other;
        local float radpitch;

 Super.PostRender(Canvas);
   P = PlayerPawn(Owner);
   if ( (P != None) && (P.DesiredFOV != P.DefaultFOV) )
   {
	bOwnsCrossHair = true;

      if ( Level.bHighDetailMode )
         Canvas.Style = ERenderStyle.STY_Normal;
      else
         Canvas.Style = ERenderStyle.STY_Normal;

      // Square
      Canvas.SetPos( 3*Canvas.ClipX/7, 3*Canvas.ClipY/7 );
      Canvas.DrawTile( Texture'crosshair', Canvas.ClipX/7, Canvas.ClipY/7, 0, 0, 256, 193 );
	  Canvas.DrawColor.R = 255;

      // Top Line
      Canvas.SetPos( 200*Canvas.ClipX/401, Canvas.ClipY/229*(90-P.DesiredFOV)+0.6*Canvas.ClipY/28 );
      Canvas.DrawTile( Texture'crosshair', Canvas.ClipX/401, Canvas.ClipY/28, 0, 20, 3, 10 );
	  Canvas.DrawColor.R = 255;

      // Bottom Line
      Canvas.SetPos( 200*Canvas.ClipX/401, 15.35*Canvas.ClipY/28 + Canvas.ClipY/229*P.DesiredFOV );
      Canvas.DrawTile( Texture'crosshair', Canvas.ClipX/401, Canvas.ClipY/28, 0, 20, 3, 10 );
	  Canvas.DrawColor.R = 255;

      // Left Line
      Canvas.SetPos( Canvas.ClipX/229*(90-P.DesiredFOV)+0.6*Canvas.ClipX/28, 200*Canvas.ClipY/401 );
      Canvas.DrawTile( Texture'crosshair', Canvas.ClipX/28, Canvas.ClipY/401, 10, 0, 10, 3 );
	  Canvas.DrawColor.R = 255;

      // Right Line
      Canvas.SetPos( 15.35*Canvas.ClipX/28 + Canvas.ClipX/229*P.DesiredFOV, 200*Canvas.ClipY/401 );
      Canvas.DrawTile( Texture'crosshair', Canvas.ClipX/28, Canvas.ClipY/401, 10, 0, 10, 3 );
	  Canvas.DrawColor.R = 255;

      // Dot
   //   Canvas.SetPos( (9*Canvas.ClipX/19) + (Canvas.ClipX/P.DesiredFOV/6), (9*Canvas.ClipY/19) + (Canvas.ClipY/P.DesiredFOV/6) );
   //   Canvas.DrawTile( Texture'crosshair',
   //      (Canvas.ClipX/19) - (Canvas.ClipX/P.DesiredFOV/3), (Canvas.ClipY/19) - (Canvas.ClipY/P.DesiredFOV/3), 0, 202, 53, 53 );
      Canvas.SetPos( 199.5*Canvas.ClipX/401, 199.5*Canvas.ClipY/401 );
      Canvas.DrawTile( Texture'crosshair', 2*Canvas.ClipX/401, 2*Canvas.ClipY/401, 0, 202, 53, 53 );
	  Canvas.DrawColor.R = 255;

      // Top Gradient
      Canvas.SetPos( 200*Canvas.ClipX/401, 4*Canvas.ClipY/9 );
      Canvas.DrawTile( Texture'crosshair', Canvas.ClipX/401, Canvas.ClipY/1360*(90-P.DesiredFOV), 129, 197, 3, 54 );

      // Left Gradient
      Canvas.SetPos( 4*Canvas.ClipX/9, 200*Canvas.ClipY/401 );
      Canvas.DrawTile( Texture'crosshair', Canvas.ClipX/1360*(90-P.DesiredFOV), Canvas.ClipY/401, 69, 200, 54, 3 );

      //Bottom Gradient
      Canvas.SetPos( 200*Canvas.ClipX/401, 5*Canvas.ClipY/9 - Canvas.ClipY/1360*(90-P.DesiredFOV) );
      Canvas.DrawTile( Texture'crosshair', Canvas.ClipX/401, Canvas.ClipY/1360*(90-P.DesiredFOV), 144, 199, 3, 54 );

      //Right Gradient
      Canvas.SetPos( 5*Canvas.ClipX/9 - Canvas.ClipX/1360*(90-P.DesiredFOV), 200*Canvas.ClipY/401 );
      Canvas.DrawTile( Texture'crosshair', Canvas.ClipX/1360*(90-P.DesiredFOV), Canvas.ClipY/401, 163, 199, 54, 3 );

  // Calc range
        	XLength=255.0;
		GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
		if ((Pawn(Owner).ViewRotation.Pitch >= 0) && (Pawn(Owner).ViewRotation.Pitch <= 18000))
			radpitch = float(Pawn(Owner).ViewRotation.Pitch) / float(182) * (Pi/float(180));
		else
			radpitch = float(Pawn(Owner).ViewRotation.Pitch - 65535) / float(182) * (Pi/float(180));

		StartTrace = Owner.Location + Pawn(Owner).EyeHeight*Z*cos(radpitch);
	    	AdjustedAim = pawn(owner).AdjustAim(1000000, StartTrace, 2.75*AimError, False, False);
		EndTrace = StartTrace +(20000 * vector(AdjustedAim));
		Other = Pawn(Owner).TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
		range = Vsize(StartTrace-HitLocation)/48-0.25;

         // Range Display
		Canvas.SetPos( 202*Canvas.ClipX/401-75, 4*Canvas.ClipY/7 + Canvas.ClipY/401 );
		Canvas.Font = Font'Botpack.WhiteFont';
		Canvas.DrawColor.R = 255;
		Canvas.DrawColor.G = 0;
		Canvas.DrawColor.B = 0;
        Canvas.DrawText( "ZSZ"$int(range)$"."$int(10 * range -10 * int(range))$"");

		// Magnification Display
		Canvas.SetPos( 202*Canvas.ClipX/401, 4*Canvas.ClipY/7 + Canvas.ClipY/401 );
		Canvas.Font = Font'Botpack.WhiteFont';
		Canvas.DrawColor.R = 255;
		Canvas.DrawColor.G = 0;
		Canvas.DrawColor.B = 0;
		Scale = P.DefaultFOV/P.DesiredFOV;
		Canvas.DrawText("ZOOM x"$int(Scale)$"."$int(10 * Scale - 10 * int(Scale)));
	}
	else
		bOwnsCrossHair = false;
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
			NN_TraceFire();
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
	PlayOwnedSound(Misc1Sound, SLOT_Misc, 1.0*Pawn(Owner).SoundDampening,,, Level.TimeDilation-0.1);
	GotoState('Zooming');
	return true;
}

function Fire( float Value )
{
	local bbPlayer bbP;
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;
		
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
	}
}

function AltFire( float Value )
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;
	PlayOwnedSound(Misc1Sound, SLOT_Misc, 1.0*Pawn(Owner).SoundDampening,,, Level.TimeDilation-0.1);
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
	local vector realLoc;
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

	PawnOwner = Pawn(Owner);
	POther = Pawn(Other);
	PPOther = PlayerPawn(Other);
	realLoc = Owner.Location + CalcDrawOffset();
	DoShellCase(PlayerPawn(Owner), realLoc + 20 * X + FireOffset.Y * Y + Z, X,Y,Z);

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
			if (HeadDamage > 0)
				Other.TakeDamage(HeadDamage, PawnOwner, HitLocation, 35000 * X, AltDamageType); // was 100 (150) dmg
			else
				Other.TakeDamage(class'UTPure'.default.HeadshotDamage, PawnOwner, HitLocation, 35000 * X, AltDamageType);
		}
		else
		{
			if (HitDamage > 0)
				Other.TakeDamage(HitDamage,  PawnOwner, HitLocation, 30000.0*X, MyDamageType);	 // was 45 (67) dmg
			else
				Other.TakeDamage(class'UTPure'.default.SniperDamagePri,  PawnOwner, HitLocation, 30000.0*X, MyDamageType);
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
			{
				s.DrawScale = 2.0;
				s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.2+0.2)*Y + (FRand()*0.3+1.0) * Z)*160);              
			}
			}
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

simulated function NN_TraceFire()
{
	local vector HitLocation, HitDiff, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local bool bHeadshot;
	
	if (Owner.IsA('Bot'))
		return;
	
	yModInit();
	
	PawnOwner = Pawn(Owner);
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return;

	GetAxes(GV,X,Y,Z);
	StartTrace = Owner.Location + bbP.Eyeheight * vect(0,0,1);
	EndTrace = StartTrace + (100000 * vector(GV));

	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,PawnOwner);
	if (Other.IsA('Pawn'))
		HitDiff = HitLocation - Other.Location;
	
	bHeadshot = NN_ProcessTraceHit(Other, HitLocation, HitNormal, X,Y,Z,yMod);
	bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, bHeadshot);
}

function TraceFire( float Accuracy )
{
	local bbPlayer bbP;
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

	if (bbP == None)
	{
		if (bbP.zzNN_HitActor.IsA('bbPlayer') && !bbPlayer(bbP.zzNN_HitActor).xxCloseEnough(bbP.zzNN_HitLoc))
		bbP.zzNN_HitActor = None;
	}
	
	Owner.MakeNoise(bbP.SoundDampening);
	GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
	StartTrace = Owner.Location + bbP.Eyeheight * vect(0,0,1);
	AdjustedAim = bbP.AdjustAim(1000000, StartTrace, 2*AimError, False, False);	
	X = vector(AdjustedAim);
	EndTrace = StartTrace + 100000 * X;
	
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
			if ( (PlayerPawn(Owner) != None) && PlayerPawn(Owner).Player.IsA('ViewPort') )
				PlayerPawn(Owner).StopZoom();
                                PlayOwnedSound(Misc2Sound, SLOT_Misc, 1.0*Pawn(Owner).SoundDampening,,, Level.TimeDilation-0.1);
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

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'SniperRifle');
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
     AmmoName=Class'h4x_Bullets'
     PickupAmmoCount=500
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
     FireSound=Sound'BLAM'
     AltFireSound=Sound'UnrealShare.AutoMag.shot'
     DeathMessage="%k fucked %o up"
     NameColor=(R=0,G=0,B=255,A=0)
     bDrawMuzzleFlash=True
     MuzzleScale=1.000000
     FlashY=0.110000
     FlashO=0.010000
     FlashC=0.030000
     FlashLength=0.010000
     FlashS=256
	 MFTexture=Texture'MuzzleFlash2'
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
	 MuzzleFlashStyle=STY_Translucent
     MuzzleFlashMesh=LodMesh'Botpack.muzzsr3'
     MuzzleFlashScale=0.100000
     MuzzleFlashTexture=Texture'Muzzy3'
     PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
     Icon=Texture'Botpack.Icons.UseRifle'
     Rotation=(Roll=-1536)
     Mesh=LodMesh'Botpack.RiflePick'
     bNoSmooth=False
     CollisionRadius=32.000000
     CollisionHeight=8.000000
	 Misc1Sound=Sound'zoomstart'
     Misc2Sound=Sound'zoomstop'
	 SelectSound=Sound'RiflePickup'
}