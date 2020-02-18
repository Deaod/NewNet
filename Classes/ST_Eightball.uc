// ===============================================================
// Stats.ST_UT_Eightball: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_Eightball extends ST_UnrealWeapons;

var Actor NN_LockedTarget;
var name LastState;
var int RocketsLoaded, ClientRocketsLoaded;
var bool bFireLoad,bTightWad, bInstantRocket, bAlwaysInstant, bClientDone, bRotated, bPendingLock;
var Actor LockedTarget, NewTarget, OldTarget;

replication
{
	reliable if ( bNetOwner && Role == ROLE_Authority )
		bInstantRocket, NN_LockedTarget;
	reliable if ( Role < ROLE_Authority )
		ServerForceFire, ServerForceAltFire, ServerFireRockets;
}

function BecomeItem()
{
	local TournamentPlayer TP;

	Super.BecomeItem();
	TP = TournamentPlayer(Instigator);
	bInstantRocket = bAlwaysInstant || ( (TP != None) && TP.bInstantRocket );
}

simulated function PostRender( canvas Canvas )
{
	local float XScale;

	Super.PostRender(Canvas);
	bOwnsCrossHair = bLockedOn;
	if ( bOwnsCrossHair )
	{
		// if locked on, draw special crosshair
		XScale = FMax(1.0, Canvas.ClipX/640.0);
		Canvas.SetPos(0.5 * (Canvas.ClipX - Texture'Crosshair6'.USize * XScale), 0.5 * (Canvas.ClipY - Texture'Crosshair6'.VSize * XScale));
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.DrawIcon(Texture'Crosshair6', 1.0);
		Canvas.Style = 1;	
	}
}
function float RateSelf( out int bUseAltMode )
{
	local float EnemyDist, Rating;
	local bool bRetreating;
	local vector EnemyDir;
	local Pawn P;

	// don't recommend self if out of ammo
	if ( AmmoType.AmmoAmount <=0 )
		return -2;

	// by default use regular mode (rockets)
	bUseAltMode = 0;
	P = Pawn(Owner);
	if ( P.Enemy == None )
		return AIRating;

	// if standing on a lift, make sure not about to go around a corner and lose sight of target
	// (don't want to blow up a rocket in bot's face)
	if ( (P.Base != None) && (P.Base.Velocity != vect(0,0,0))
		&& !P.CheckFutureSight(0.1) )
		return 0.1;

	EnemyDir = P.Enemy.Location - Owner.Location; 
	EnemyDist = VSize(EnemyDir);
	Rating = AIRating;

	// don't pick rocket launcher is enemy is too close
	if ( EnemyDist < 360 )
	{
		if ( P.Weapon == self )
		{
			// don't switch away from rocket launcher unless really bad tactical situation
			if ( (EnemyDist > 230) || ((P.Health < 50) && (P.Health < P.Enemy.Health - 30)) )
				return Rating;
		}
		return 0.05 + EnemyDist * 0.001;
	}

	// increase rating for situations for which rocket launcher is well suited
	if ( P.Enemy.IsA('StationaryPawn') )
		Rating += 0.4;

	// rockets are good if higher than target, bad if lower than target
	if ( Owner.Location.Z > P.Enemy.Location.Z + 120 )
		Rating += 0.25;
	else if ( P.Enemy.Location.Z > Owner.Location.Z + 160 )
		Rating -= 0.35;
	else if ( P.Enemy.Location.Z > Owner.Location.Z + 80 )
		Rating -= 0.05;

	// decide if should use alternate fire (grenades) instead
	if ( (Owner.Physics == PHYS_Falling) || Owner.Region.Zone.bWaterZone )
		bUseAltMode = 0;
	else if ( EnemyDist < -1.5 * EnemyDir.Z )
		bUseAltMode = int( FRand() < 0.5 );
	else
	{
		// grenades are good covering fire when retreating
		bRetreating = ( ((EnemyDir/EnemyDist) Dot Owner.Velocity) < -0.7 );
		bUseAltMode = 0;
		if ( bRetreating && (EnemyDist < 800) && (FRand() < 0.4) )
			bUseAltMode = 1;
	}
	return Rating;
}

// return delta to combat style while using this weapon
function float SuggestAttackStyle()
{
	local float EnemyDist;

	// recommend backing off if target is too close
	EnemyDist = VSize(Pawn(Owner).Enemy.Location - Owner.Location);
	if ( EnemyDist < 600 )
	{
		if ( EnemyDist < 300 )
			return -1.5;
		else
			return -0.7;
	}
	else
		return -0.2;
}

simulated function Tick( float Delta )
{
	Super.Tick( Delta );
	
	if (!bNewNet)
		return;
	
	if (Role == ROLE_Authority && NN_LockedTarget != LockedTarget)
		NN_LockedTarget = LockedTarget;
}

function Fire( float Value )
{
	local TournamentPlayer TP;

	bPointing=True;
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
	{
		TP = TournamentPlayer(Instigator);
		bCanClientFire = true;
		bInstantRocket = bAlwaysInstant || ( (TP != None) && TP.bInstantRocket );
		if ( bInstantRocket )
		{
			bFireLoad = True;
			RocketsLoaded = 1;
			GotoState('');
			GotoState('FireRockets', 'Begin');
		}
		else if ( Instigator.IsA('Bot') )
		{
			if ( LockedTarget != None )
			{
				bFireLoad = True;
				RocketsLoaded = 1;
				Instigator.bFire = 0;
				bPendingLock = true;
				GotoState('');
				GotoState('FireRockets', 'Begin');
				return;
			}
			else if ( (NewTarget != None) && !NewTarget.IsA('StationaryPawn')
				&& (FRand() < 0.8)
				&& (VSize(Instigator.Location - NewTarget.Location) > 400 + 400 * (1.25 - TimerCounter) + 1300 * FRand()) )
			{
				Instigator.bFire = 0;
				bPendingLock = true;
				GotoState('Idle','PendingLock');
				return;
			}
			else if ( !Bot(Owner).bNovice 
					&& (FRand() < 0.7)
					&& IsInState('Idle') && (Instigator.Enemy != None)
					&& ((Instigator.Enemy == Instigator.Target) || (Instigator.Target == None))
					&& !Instigator.Enemy.IsA('StationaryPawn')
					&& (VSize(Instigator.Location - Instigator.Enemy.Location) > 700 + 1300 * FRand())
					&& (VSize(Instigator.Location - Instigator.Enemy.Location) < 2000) )
			{
				NewTarget = CheckTarget();
				OldTarget = NewTarget;
				if ( NewTarget == Instigator.Enemy )
				{
					if ( TimerCounter > 0.6 )
						SetTimer(1.0, true);
					Instigator.bFire = 0;
					bPendingLock = true;
					GotoState('Idle','PendingLock');
					return;
				}
			}
			bPendingLock = false;
			GotoState('NormalFire');
		}
		else
			GotoState('NormalFire');
	}
}

simulated function bool ClientFire( float Value )
{
	local bbPlayer bbP;
	
	//if (Owner.IsA('Bot'))
		//return Super.ClientFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false;
		bbP.xxNN_Fire(bbP.zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
		
		bPointing=True;
		if ( AmmoType == None )
		{
			// ammocheck
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			
			bCanClientFire = true;
			bInstantRocket = bAlwaysInstant || ( (bbP != None) && bbP.bInstantRocket );
			if ( bInstantRocket )
			{
				bFireLoad = True;
				RocketsLoaded = 1;
				GotoState('');
				GotoState('NN_FireRockets', 'Begin');
			}
			else
				GotoState('NN_NormalFire');
			
			return true;
		}
	}
	else if ( bCanClientFire && ((Role == ROLE_Authority) || (AmmoType == None) || (AmmoType.AmmoAmount > 0)) )
	{
		GotoState('ClientFiring');
		return true;
	}
	return false;
}

simulated function FiringRockets()
{
	PlayRFiring();
	bClientDone = true;
	Disable('Tick');
}

function AltFire( float Value )
{
	bPointing=True;
	bCanClientFire = true;
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(1) )
		GoToState('AltFiring');
}

simulated function bool ClientAltFire( float Value )
{
	local bbPlayer bbP;
	
	//if (Owner.IsA('Bot'))
		//return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false;
		bbP.xxNN_AltFire(bbP.zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
		
		if ( AmmoType == None )
		{
			// ammocheck
			GiveAmmo(Pawn(Owner));
		}
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			GotoState('NN_AltFiring');
			return true;
		}
	}
	else if ( bCanClientFire && ((Role == ROLE_Authority) || (AmmoType == None) || (AmmoType.AmmoAmount > 0)) )
	{
		GotoState('NN_AltFiring');
		return true;
	}
	return false;
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

simulated function RotateRocket()
{
}

exec function ServerForceFire(bool bF)
{
	bForceFire = bF;
}
exec function ServerForceAltFire(bool bF)
{
	bForceAltFire = bF;
}
exec function ServerFireRockets( int ProjIndex, bool bPrimary, int RoxLoaded, float ClientLocX, float ClientLocY, float ClientLocZ, int ViewPitch, int ViewYaw, int ViewRoll, optional int ClientFRVI, optional bool bInstant )
{
	local bbPlayer bbP;
	local int Diff;
	
	if (Owner.IsA('Bot'))
		return;
	
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
	bbP.zzbNN_ReleasedFire = true;
	
	if (!bInstant)
	{
		Diff = RoxLoaded - RocketsLoaded;
		if (Diff > 0)
			AmmoType.UseAmmo(Diff);
	}
	RocketsLoaded = RoxLoaded;
	bFireLoad = bPrimary;
	
	GotoState('FireRockets');
}

///////////////////////////////////////////////////////

state FireRockets
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

	function bool SplashJump()
	{
		return false;
	}

	function BeginState()
	{
		local vector FireLocation, StartLoc, X,Y,Z;
		local rotator FireRot, RandRot;
		local ST_RocketMk2 r;
		local ST_UT_SeekingRocket s;
		local ST_UT_Grenade g;
		local float Angle, RocketRad, R1, R2, R3, R4, R5, R6, R7;
		local pawn BestTarget, PawnOwner;
		local PlayerPawn PlayerOwner;
		local int DupRockets;
		local bool bMultiRockets;
		local bbPlayer bbP;
		local NN_rocketmk2OwnerHidden NNR;
		local NN_ut_SeekingRocketOwnerHidden NNS;
		local NN_ut_GrenadeOwnerHidden NNG;
/* 		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}
		 */
		bbP = bbPlayer(Owner);
		R1 = GetFRV();

		PawnOwner = Pawn(Owner);
		if ( PawnOwner == None )
			return;
		PlayerOwner = PlayerPawn(Owner);
		Angle = 0;
		DupRockets = RocketsLoaded - 1;
		if (DupRockets < 0) DupRockets = 0;
		if ( PlayerOwner == None )
			bTightWad = ( R1 * 4 < PawnOwner.skill );
			
		if (bbP == None || !bNewNet)
		{
			GetAxes(PawnOwner.ViewRotation,X,Y,Z);
			StartLoc = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}
		else
		{
			GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
			if (Mover(bbP.Base) == None)
				StartLoc = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			else
				StartLoc = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}

		if ( bFireLoad ) 		
			AdjustedAim = PawnOwner.AdjustAim(ProjectileSpeed, StartLoc, AimError, True, bWarnTarget);
		else 
			AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, StartLoc, AimError, True, bAltWarnTarget);	
			
		if (bbP == None || !bNewNet)
			AdjustedAim = Pawn(Owner).ViewRotation;
		else
			AdjustedAim = bbP.zzNN_ViewRot;
		
		if (!bNewNet)
			PawnOwner.PlayRecoil(FiringSpeed);
		PlayRFiring();
		Owner.MakeNoise(PawnOwner.SoundDampening);
		if ( !bFireLoad )
		{
			LockedTarget = None;
			bLockedOn = false;
		}
		else if ( LockedTarget != None )
		{
			BestTarget = Pawn(CheckTarget());
			if ( (LockedTarget!=None) && (LockedTarget != BestTarget) ) 
			{
				LockedTarget = None;
				bLockedOn=False;
			}
		}
		else 
			BestTarget = None;
		bPendingLock = false;
		bPointing = true;
		FireRot = AdjustedAim;
		RocketRad = 4;
		if (bTightWad || !bFireLoad) RocketRad=7;
		bMultiRockets = ( RocketsLoaded > 1 );
		While ( RocketsLoaded > 0 )
		{
			R2 = GetFRV();
			R3 = GetFRV();
			R4 = GetFRV();
			R5 = GetFRV();
			R6 = GetFRV();
			R7 = GetFRV();
			
			if ( bMultiRockets ) {
				Firelocation = StartLoc - (Sin(Angle)*RocketRad - 7.5)*Y + (Cos(Angle)*RocketRad - 7)*Z - X * 4 * R2;
			} else
				FireLocation = StartLoc;
			if (bFireLoad)
			{
				if ( Angle > 0 )
				{
					if ( Angle < 3 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw - Angle * 600;
					else if ( Angle > 3.5 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw + (Angle - 3)  * 600;
					else
						FireRot.Yaw = AdjustedAim.Yaw;
				}
				if ( LockedTarget != None )
				{
					if (bNewNet)
					{
						s = Spawn( class 'NN_ut_SeekingRocketOwnerHidden',Owner, '', FireLocation,FireRot);
						NNS = NN_ut_SeekingRocketOwnerHidden(s);
						//NNS.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
						if (bbP != None)
							NNS.zzNN_ProjIndex = bbP.xxNN_AddProj(NNS);
					}
					else
						s = Spawn( class 'ST_UT_SeekingRocket',, '', FireLocation,FireRot);
					s.Seeking = LockedTarget;
					s.NumExtraRockets = DupRockets;					
					if ( Angle > 0 )
						s.Velocity *= (0.9 + 0.2 * R3);			
				}
				else 
				{
					if (bNewNet)
					{
						r = Spawn( class'NN_rocketmk2OwnerHidden',Owner, '', FireLocation,FireRot);
						NNR = NN_rocketmk2OwnerHidden(r);
						NNR.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
						if (bbP != None)
							NNR.zzNN_ProjIndex = bbP.xxNN_AddProj(NNR);
					}
					else
						r = Spawn( class'ST_RocketMk2',, '', FireLocation,FireRot);
					r.NumExtraRockets = DupRockets;
					if (RocketsLoaded>4 && bTightWad) r.bRing=True;
					if ( Angle > 0 )
						r.Velocity *= (0.9 + 0.2 * R4);			
				}
			}
			else 
			{
				if (bNewNet)
				{
					g = Spawn( class 'NN_ut_GrenadeOwnerHidden',Owner, '', FireLocation,AdjustedAim);
					NNG = NN_ut_GrenadeOwnerHidden(g);
					//NNG.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
					if (bbP != None)
						NNG.zzNN_ProjIndex = bbP.xxNN_AddProj(NNG);
				}
				else
					g = Spawn( class 'ST_UT_Grenade',Owner, '', FireLocation,AdjustedAim);
				g.NumExtraGrenades = DupRockets;
				if ( DupRockets > 0 )
				{
					RandRot.Pitch = R5 * 1500 - 750;
					RandRot.Yaw = R6 * 1500 - 750;
					RandRot.Roll = R7 * 1500 - 750;
					g.Velocity = g.Velocity >> RandRot;
				}
			}

			Angle += 1.0484; //2*3.1415/6;
			RocketsLoaded--;
		}
		bTightWad=False;
	}
	simulated function AnimEnd()
	{
		if (AmmoType.AmmoAmount > 0)
		{	
			PlayRotating();
			RocketsLoaded = 1;
			bRotated = true;
		}
		Finish();
	}
}

state NN_FireRockets
{
	simulated function bool ClientFire(float F) {
		if (Owner.IsA('Bot'))
			return Super.ClientFire(F);
		if (Left(AnimSequence, 4) != "Fire" && F > 0)
		{
			bForceFire = true;
			ServerForceFire(true);
		}
	}
	simulated function bool ClientAltFire(float F) {
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(F);
		if (Left(AnimSequence, 4) != "Fire" && F > 0)
		{
			bForceAltFire = true;
			ServerForceAltFire(true);
		}
	}

	simulated function ForceFire()
	{
		bForceFire = true;
	}

	simulated function ForceAltFire()
	{
		bForceAltFire = true;
	}

	simulated function bool SplashJump()
	{
		return false;
	}

	simulated function BeginState()
	{
		local vector FireLocation, StartLoc, X,Y,Z;
		local rotator FireRot, RandRot;
		local float Angle, RocketRad, R1, R2, R3, R4, R5, R6, R7;
		local pawn BestTarget, PawnOwner;
		local PlayerPawn PlayerOwner;
		local int DupRockets, ProjIndex;
		local bool bMultiRockets;
		local ST_UT_SeekingRocket s;
		local ST_RocketMk2 r;
		local ST_UT_Grenade g;
		local bbPlayer bbP;
/* 		
		if (Owner.IsA('Bot'))
		{
			Super.BeginState();
			return;
		}
 */
		PawnOwner = Pawn(Owner);
		bbP = bbPlayer(Owner);
		if ( bbP == None || bbP.IsInState('Dying') || bbP.Weapon != Self )
			return;
		
		yModInit();
		
		ServerFireRockets(bbP.zzNN_ProjIndex, bFireLoad, RocketsLoaded, bbP.Location.X, bbP.Location.Y, bbP.Location.Z, GV.Pitch, GV.Yaw, GV.Roll, bbP.zzNN_FRVI, bAlwaysInstant || bbP.bInstantRocket);
		
		R1 = NN_GetFRV();
		
		PawnOwner.PlayRecoil(FiringSpeed);
		PlayerOwner = PlayerPawn(Owner);
		Angle = 0;
		DupRockets = RocketsLoaded - 1;
		if (DupRockets < 0) DupRockets = 0;
		if ( PlayerOwner == None )
			bTightWad = ( R1 * 4 < PawnOwner.skill );

		GetAxes(GV,X,Y,Z);
		StartLoc = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z;

		if ( bFireLoad ) 		
			AdjustedAim = PawnOwner.AdjustAim(ProjectileSpeed, StartLoc, AimError, True, bWarnTarget);
		else 
			AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, StartLoc, AimError, True, bAltWarnTarget);	
			
		if ( PlayerOwner != None )
			AdjustedAim = GV;
		
		PlayRFiring();		
		Owner.MakeNoise(PawnOwner.SoundDampening);
		if ( !bFireLoad )
		{
			NN_LockedTarget = None;
			bLockedOn = false;
		}
		else if ( NN_LockedTarget == None )
			BestTarget = None;
		bPendingLock = false;
		bPointing = true;
		FireRot = AdjustedAim;
		RocketRad = 4;
		if (bTightWad || !bFireLoad) RocketRad=7;
		bMultiRockets = ( RocketsLoaded > 1 );
		
		//bbP.ClientMessage("Client ("$(Level.NetMode==NM_Client)$"):"@RocketsLoaded);
		While ( RocketsLoaded > 0 )
		{
			R2 = NN_GetFRV();
			R3 = NN_GetFRV();
			R4 = NN_GetFRV();
			R5 = NN_GetFRV();
			R6 = NN_GetFRV();
			R7 = NN_GetFRV();
			
			if ( bMultiRockets )
				Firelocation = StartLoc - (Sin(Angle)*RocketRad - 7.5)*Y + (Cos(Angle)*RocketRad - 7)*Z - X * 4 * R2;
			else
				FireLocation = StartLoc;
			if (bFireLoad)
			{
				if ( Angle > 0 )
				{
					if ( Angle < 3 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw - Angle * 600;
					else if ( Angle > 3.5 && !bTightWad)
						FireRot.Yaw = AdjustedAim.Yaw + (Angle - 3)  * 600;
					else
						FireRot.Yaw = AdjustedAim.Yaw;
				}
				
				if ( NN_LockedTarget != None )
				{
					s = Spawn( class 'ST_UT_SeekingRocket',Owner, '', FireLocation,FireRot);
					s.Seeking = NN_LockedTarget;
					s.NumExtraRockets = DupRockets;					
					if ( Angle > 0 )
						s.Velocity *= (0.9 + 0.2 * R3);
					ProjIndex = bbP.xxNN_AddProj(s);
					s.zzNN_ProjIndex = ProjIndex;
                    bbP.xxClientDemoFix(S, class'UT_SeekingRocket', FireLocation, S.Velocity, S.Acceleration, FireRot,, NN_LockedTarget);
				}
				else 
				{
					r = Spawn( class'ST_RocketMk2',Owner, '', FireLocation,FireRot);
					r.NumExtraRockets = DupRockets;
					if (RocketsLoaded>4 && bTightWad) r.bRing=True;
					if ( Angle > 0 )
						r.Velocity *= (0.9 + 0.2 * R4);
					ProjIndex = bbP.xxNN_AddProj(r);
					r.zzNN_ProjIndex = ProjIndex;
                    bbP.xxClientDemoFix(R, class'RocketMk2', FireLocation, R.Velocity, R.Acceleration, FireRot);
				}
			}
			else 
			{
				g = Spawn( class 'ST_UT_Grenade',Owner, '', FireLocation, AdjustedAim);
				g.NumExtraGrenades = DupRockets;
				if ( DupRockets > 0 )
				{
					RandRot.Pitch = R5 * 1500 - 750;
					RandRot.Yaw = R6 * 1500 - 750;
					RandRot.Roll = R7 * 1500 - 750;
					g.Velocity = g.Velocity >> RandRot;
				}
				ProjIndex = bbP.xxNN_AddProj(g);
				g.zzNN_ProjIndex = ProjIndex;
                bbP.xxClientDemoFix(G, class'UT_Grenade', FireLocation, G.Velocity, G.Acceleration, G.Rotation);
			}

			Angle += 1.0484; //2*3.1415/6;
			RocketsLoaded--;
		}
		bTightWad=False;
	}
	simulated function AnimEnd()
	{
		if (AmmoType.AmmoAmount > 0)
		{	
			PlayRotating();
			RocketsLoaded = 1;
			bRotated = true;
		}
		NN_Finish();
	}
}

state NN_NormalFire
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
	}
	simulated function bool ClientAltFire(float F) 
	{
	}
	
	simulated function bool SplashJump()
	{
		return true;
	}

	simulated function Tick( float DeltaTime )
	{
		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}
		
		if ( (PlayerPawn(Owner) == None) 
			&& ((Pawn(Owner).MoveTarget != Pawn(Owner).Target) 
				|| (LockedTarget != None)
				|| (Pawn(Owner).Enemy == None)
				|| ( Mover(Owner.Base) != None )
				|| ((Owner.Physics == PHYS_Falling) && (Owner.Velocity.Z < 5))
				|| (VSize(Owner.Location - Pawn(Owner).Target.Location) < 400)
				|| !Pawn(Owner).CheckFutureSight(0.15)) )
			Pawn(Owner).bFire = 0;

		if( pawn(Owner).bFire==0 || RocketsLoaded > 5 || AmmoType.AmmoAmount == 0)  // If Fire button down, load up another
 			GoToState('NN_FireRockets');
	}
	
	simulated function AnimEnd()
	{
/* 		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		} */
		if ( RocketsLoaded == 6 || AmmoType.AmmoAmount == 0 )
		{
			GotoState('NN_FireRockets');
			return;
		}
		RocketsLoaded++;
		AmmoType.UseAmmo(1);
		if (pawn(Owner).bAltFire!=0) bTightWad=True;
		NewTarget = CheckTarget();
		if ( Pawn(NewTarget) != None )
			Pawn(NewTarget).WarnTarget(Pawn(Owner), ProjectileSpeed, vector(Pawn(Owner).ViewRotation));	
		if ( LockedTarget != None )
		{
			If ( NewTarget != LockedTarget ) 
			{
				LockedTarget = None;
				Owner.PlaySound(Misc2Sound, SLOT_None, Pawn(Owner).SoundDampening);
				bLockedOn=False;
			}
			else if (LockedTarget != None)
				Owner.PlaySound(Misc1Sound, SLOT_None, Pawn(Owner).SoundDampening);
		}
		bPointing = true;
		Owner.MakeNoise(0.6 * Pawn(Owner).SoundDampening);		
		RotateRocket();
	}

	simulated function BeginState()
	{
		Super.BeginState();
		if (Owner.IsA('Bot'))
			return;
		bFireLoad = True;
		RocketsLoaded = 1;
		RotateRocket();
	}

	simulated function RotateRocket()
	{
		if (Owner.IsA('Bot'))
			return;
		if ( AmmoType.AmmoAmount <= 0 ) 
		{
			GotoState('NN_FireRockets');
			return;
		}
		if ( AmmoType.AmmoAmount == 1 )
			Owner.PlaySound(Misc2Sound, SLOT_None, Pawn(Owner).SoundDampening); 
		PlayRotating();
	}
				
Begin:
	Sleep(0.0);
	FinishAnim();
	NN_Finish();
}

state NN_AltFiring
{
	simulated function bool ClientFire(float F) 
	{
	}

	simulated function bool ClientAltFire(float F) 
	{
	}

	simulated function ForceFire()
	{
		bForceFire = true;
	}

	simulated function ForceAltFire()
	{
		bForceAltFire = true;
	}

	simulated function Tick( float DeltaTime )
	{
/* 		if (Owner.IsA('Bot'))
		{
			Super.Tick(DeltaTime);
			return;
		}
		 */
		if( (pawn(Owner).bAltFire==0) || (RocketsLoaded > 5) || AmmoType.AmmoAmount == 0 )  // If if Fire button down, load up another
 			GoToState('NN_FireRockets');
	}
	
	simulated function AnimEnd()
	{
/* 		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		}
 */
		if ( RocketsLoaded == 6 || AmmoType.AmmoAmount == 0 )
		{
			GotoState('NN_FireRockets');
			return;
		}
		RocketsLoaded++;
		AmmoType.UseAmmo(1);		
		if ( (PlayerPawn(Owner) == None) && ((FRand() > 0.5) || (Pawn(Owner).Enemy == None)) )
			Pawn(Owner).bAltFire = 0;
		bPointing = true;
		Owner.MakeNoise(0.6 * Pawn(Owner).SoundDampening);		
		RotateRocket();
	}

	simulated function RotateRocket()
	{
		if (Owner.IsA('Bot'))
			return;
		if (AmmoType.AmmoAmount<=0)
		{ 
			GotoState('NN_FireRockets');
			return;
		}		
		PlayRotating();
	}

	simulated function BeginState()
	{
		Super.BeginState();
		if (Owner.IsA('Bot'))
			return;
		RocketsLoaded = 1;
		bFireLoad = False;
		RotateRocket();
	}
	
Begin:
	if (!Owner.IsA('Bot'))
	{
		bLockedOn = False;
		FinishAnim();
		NN_Finish();
	}
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

	if ( bChangeWeapon || AmmoType.AmmoAmount <= 0 )
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
	{
		Global.Fire(0);
		Global.ClientFire(0);
	}
	else if ( (PawnOwner.bAltFire!=0) || bForceAlt )
	{
		Global.AltFire(0);
		Global.ClientAltFire(0);
	}
	else 
		GotoState('Idle');
}

state NormalFire
{
	function bool SplashJump()
	{
		return true;
	}

	function Tick( float DeltaTime )
	{
		if (!bNewNet || Owner.IsA('Bot'))
			Super.Tick(DeltaTime);
	}
	
	function AnimEnd()
	{
/* 		if (Owner.IsA('Bot'))
		{
			Super.AnimEnd();
			return;
		} */
		if ( RocketsLoaded == 6 )
		{
			if (!bNewNet)
				GotoState('FireRockets');
			return;
		}
		else if (bbPlayer(Owner) != None && bNewNet && bbPlayer(Owner).bFire == 0)
		{
			GotoState('Idle');
			return;
		}
		RocketsLoaded++;
		AmmoType.UseAmmo(1);
		if (pawn(Owner).bAltFire!=0) bTightWad=True;
		NewTarget = CheckTarget();
		if ( Pawn(NewTarget) != None )
			Pawn(NewTarget).WarnTarget(Pawn(Owner), ProjectileSpeed, vector(Pawn(Owner).ViewRotation));	
		if ( LockedTarget != None )
		{
			If ( NewTarget != LockedTarget ) 
			{
				LockedTarget = None;
				Owner.PlaySound(Misc2Sound, SLOT_None, Pawn(Owner).SoundDampening);
				bLockedOn=False;
			}
			else if (LockedTarget != None)
				Owner.PlaySound(Misc1Sound, SLOT_None, Pawn(Owner).SoundDampening);
		}
		bPointing = true;
		Owner.MakeNoise(0.6 * Pawn(Owner).SoundDampening);		
		RotateRocket();
	}

	function BeginState()
	{
		Super.BeginState();
		bFireLoad = True;
		RocketsLoaded = 1;
		RotateRocket();
	}

	function RotateRocket()
	{
/* 		if (Owner.IsA('Bot'))
		{
			Super.RotateRocket();
			return;
		} */
		if ( PlayerPawn(Owner) == None )
		{
			if ( FRand() > 0.33 )
				Pawn(Owner).bFire = 0;
			if ( Pawn(Owner).bFire == 0 )
			{
				if (  !bNewNet || (bbPlayer(Owner) == None) )
				{
				  GotoState('FireRockets');
				  return;
				}
			}
		}
		if ( AmmoType.AmmoAmount <= 0 ) 
		{
			  if (  !bNewNet || (bbPlayer(Owner) == None) )
			  {
				GotoState('FireRockets');
				return;
			  }
		}
		if ( AmmoType.AmmoAmount == 1 )
			Owner.PlaySound(Misc2Sound, SLOT_None, Pawn(Owner).SoundDampening); 
		PlayRotating();
	}
Begin:
  Sleep(0.0);
}

state AltFiring
{
	function Tick( float DeltaTime )
	{
		if (!bNewNet || Owner.IsA('Bot'))
			Super.Tick(DeltaTime);
	}
	
	function AnimEnd()
	{
		if ( RocketsLoaded == 6 )
		{
			if (  !bNewNet || (bbPlayer(Owner) == None) )
			{
				GotoState('FireRockets');
				return;
			}
		}
		else if (bbPlayer(Owner) != None && bNewNet && bbPlayer(Owner).bAltFire == 0)
		{
			GotoState('Idle');
			return;
		}
		RocketsLoaded++;
		AmmoType.UseAmmo(1);		
		if ( (PlayerPawn(Owner) == None) && ((FRand() > 0.5) || (Pawn(Owner).Enemy == None)) )
			Pawn(Owner).bAltFire = 0;
		bPointing = true;
		Owner.MakeNoise(0.6 * Pawn(Owner).SoundDampening);		
		RotateRocket();
	}

	function RotateRocket()
	{
		if (AmmoType.AmmoAmount<=0)
		{ 
			  if (  !bNewNet || (bbPlayer(Owner) == None) )
			  {
				GotoState('FireRockets');
			  }
			  return;
		}
		PlayRotating();
	}

	function BeginState()
	{
		Super.BeginState();
		if (Owner.IsA('Bot'))
			return;
		RocketsLoaded = 1;
		bFireLoad = False;
		RotateRocket();
	}

Begin:
	if (!Owner.IsA('Bot'))
		bLockedOn = False;
}

function Actor CheckTarget()
{
	local Actor ETarget;
	local Vector Start, X,Y,Z;
	local float bestDist, bestAim;
	local Pawn PawnOwner;
	local rotator AimRot;
	local int diff;

	PawnOwner = Pawn(Owner);
	bPointing = false;
	if ( Owner.IsA('PlayerPawn') )
	{
		GetAxes(PawnOwner.ViewRotation,X,Y,Z);
		Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		bestAim = 0.93;
		ETarget = PawnOwner.PickTarget(bestAim, bestDist, X, Start);
	}
	else if ( PawnOwner.Enemy == None )
		return None; 
	else if ( Owner.IsA('Bot') && Bot(Owner).bNovice )
		return None;
	else if ( VSize(PawnOwner.Enemy.Location - PawnOwner.Location) < 2000 )
	{
		Start = Owner.Location + CalcDrawOffset() + FireOffset.Z * vect(0,0,1); 
		AimRot = rotator(PawnOwner.Enemy.Location - Start);
		diff = abs((AimRot.Yaw & 65535) - (PawnOwner.Rotation.Yaw & 65535));
		if ( (diff > 7200) && (diff < 58335) )
			return None;
		// check if can hold lock
		if ( !bPendingLock ) //not already locked
		{
			AimRot = rotator(PawnOwner.Enemy.Location + (3 - PawnOwner.Skill) * 0.3 * PawnOwner.Enemy.Velocity - Start);
			diff = abs((AimRot.Yaw & 65535) - (PawnOwner.Rotation.Yaw & 65535));
			if ( (diff > 16000) && (diff < 49535) )
				return None;
		}
							 
		// check line of sight
		ETarget = Trace(X,Y, PawnOwner.Enemy.Location, Start, false);
		if ( ETarget != None )
			return None;

		return PawnOwner.Enemy;
	}
	bPointing = (ETarget != None);
	Return ETarget;
}

///////////////////////////////////////////////////////
state Idle
{
	function Timer()
	{
/* 		if (Owner.IsA('Bot'))
		{
			Super.Timer();
			return;
		} */
		NewTarget = CheckTarget();
		if ( NewTarget == OldTarget )
		{
			LockedTarget = NewTarget;
			If (LockedTarget != None) 
			{
				bLockedOn=True;			
				Owner.MakeNoise(Pawn(Owner).SoundDampening);
				Owner.PlaySound(Misc1Sound, SLOT_None,Pawn(Owner).SoundDampening);
				if ( (Pawn(LockedTarget) != None) && (FRand() < 0.7) )
					Pawn(LockedTarget).WarnTarget(Pawn(Owner), ProjectileSpeed, vector(Pawn(Owner).ViewRotation));	
				if ( bPendingLock )
				{
					OldTarget = NewTarget;
					Pawn(Owner).bFire = 0;
					bFireLoad = True;
					RocketsLoaded = 1;
					if (!bNewNet)
						GotoState('FireRockets', 'Begin');
					return;
				}
			}
		}
		else if( (OldTarget != None) && (NewTarget == None) ) 
		{
			Owner.PlaySound(Misc2Sound, SLOT_None,Pawn(Owner).SoundDampening);
			bLockedOn = False;
		}
		else 
		{
			LockedTarget = None;
			bLockedOn = False;
		}
		OldTarget = NewTarget;
		bPendingLock = false;
	}

Begin:
	if (Pawn(Owner).bFire!=0 && !bNewNet) Fire(0.0);
	if (Pawn(Owner).bAltFire!=0 && !bNewNet) AltFire(0.0);	
	bPointing=False;
	if (AmmoType.AmmoAmount<=0 && bbPlayer(Owner) != None) 
		bbPlayer(Owner).SwitchToBestWeapon();  //Goto Weapon that has Ammo
	PlayIdleAnim();
	OldTarget = CheckTarget();
	SetTimer(1.25,True);
	LockedTarget = None;
	bLockedOn = False;
PendingLock:
	if ( bPendingLock )
		bPointing = true;
	if ( TimerRate <= 0 )
		SetTimer(1.0, true);
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
	simulated function Tick(float DeltaTime)
	{
		if ( (Pawn(Owner).bFire == 0) || (Ammotype.AmmoAmount <= 0) )
			FiringRockets();
	}
	
	simulated function AnimEnd()
	{
		if ( !bCanClientFire || (Pawn(Owner) == None) )
			GotoState('');
		else if ( bClientDone )
		{
			PlayRotating();
			GotoState('ClientReload');
		}
		else
		{
			if ( bInstantRocket || (ClientRocketsLoaded == 6) )
			{
				FiringRockets();
				return;
			}
			Enable('Tick');
			PlayRotating();
			ClientRocketsLoaded++;
		}
	}

	simulated function BeginState()
	{
		bFireLoad = true;
		if ( bInstantRocket )
		{
			ClientRocketsLoaded = 1;
			FiringRockets();
		}
		else
		{
			ClientRocketsLoaded = 1;
			PlayRotating();
			bRotated = true;
		}
	}

	simulated function EndState()
	{
		ClientRocketsLoaded = 0;
		bClientDone = false;
	}
}

state ClientAltFiring
{
	simulated function Tick(float DeltaTime)
	{
		if ( (Pawn(Owner).bAltFire == 0) || (Ammotype.AmmoAmount <= 0) )
			FiringRockets();
	}
	
	simulated function AnimEnd()
	{
		if ( !bCanClientFire || (Pawn(Owner) == None) )
			GotoState('');
		else if ( bClientDone )
		{
			PlayRotating();
			GotoState('ClientReload');
		}
		else
		{
			if ( ClientRocketsLoaded == 6 )
			{
				FiringRockets();
				return;
			}
			Enable('Tick');
			PlayRotating();
		}
	}

	simulated function BeginState()
	{
		bFireLoad = false;
		ClientRocketsLoaded = 1;
		PlayRotating();
	}

	simulated function EndState()
	{
		ClientRocketsLoaded = 0;
		bClientDone = false;
	}
}

simulated function PlayRFiring()
{
	if ( PlayerPawn(Owner) != None && (!bNewNet || Level.NetMode == NM_Client) )
	{
		PlayerPawn(Owner).shakeview(ShakeTime, ShakeMag*RocketsLoaded, ShakeVert);
		PlayerPawn(Owner).ClientInstantFlash( -0.4, vect(650, 450, 190));
	}
	if ( Affector != None )
		Affector.FireEffect();
	if ( !bFireLoad )
		PlayOwnedSound(AltFireSound, SLOT_None, 4.0*Pawn(Owner).SoundDampening);
		PlayAnim( 'Fire', 0.6, 0.05);
}
    
simulated function PlayRotating()
{
	if ( Owner == None )
		return;
	Owner.PlayOwnedSound(CockingSound, SLOT_None, Pawn(Owner).SoundDampening);
	PlayAnim('Loading', 1.1,0.0);
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'UT_Eightball');
}

simulated function PlaySelect ()
{
	RocketsLoaded = 0;
	ServerForceFire(false);
	ServerForceAltFire(false);
	Class'NN_WeaponFunctions'.static.PlaySelect( self);
}

simulated function tweentostill(); 

simulated function PlayIdleAnim()
{
	if ( Mesh != PickupViewMesh )
		LoopAnim('Idle', 0.02,0.5);
}

defaultproperties
{
    WeaponDescription="Classification: Heavy Ballistic\n\nPrimary Fire: Rocket Launcher.  Hold down fire button to load up multiple rockets.  To fire rockets in a tight circle, press both primary fire and secondary fire simultaneously and release the primary fire button as rockets are loading.\n\nSecondary Fire: Grenade Launcher. Hold down fire button to load multiple grenades.\n\nTechniques: Keeping this weapon pointed at an opponent will cause it to lock on, and while the gun is locked the next rocket fired will be a homing rocket.  Because the Eightball can load up multiple rockets, it fires when you release the fire button.  If you prefer, it can be configured to fire a rocket as soon as you press fire button down, at the expense of the multiple rocket load-up feature.  This is set in the Input Options menu."
    PickupAmmoCount=6
	AmmoName=Class'RocketPack'
    bWarnTarget=True
    bAltWarnTarget=True
    bSplashDamage=True
    bRecommendSplashDamage=True
    shakemag=350.00
    shaketime=0.20
    shakevert=7.50
    AIRating=0.70
    RefireRate=0.25
    AltRefireRate=0.25
    AltFireSound=Sound'UnrealShare.EightAltFire'
    CockingSound=Sound'UnrealShare.Loading'
    SelectSound=Sound'UnrealShare.Selecting'
    Misc1Sound=Sound'UnrealShare.SeekLock'
    Misc2Sound=Sound'UnrealShare.SeekLost'
    Misc3Sound=Sound'UnrealShare.BarrelMove'
    DeathMessage="%o was smacked down multiple times by %k's %w."
    AutoSwitchPriority=9
    InventoryGroup=9
    PickupMessage="You got the Eightball gun"
    ItemName="Eightball"
    PlayerViewOffset=(X=1.90,Y=-0.80,Z=-1.70),
	FireOffset=(X=30,Y=-13,Z=-10),
    PlayerViewMesh=LodMesh'UnrealShare.EightB'
	PlayerViewScale=1.05
    BobDamping=0.99
    PickupViewMesh=LodMesh'UnrealShare.EightPick'
    ThirdPersonMesh=LodMesh'UnrealShare.8Ball3rd'
    StatusIcon=Texture'UseE'
    Icon=Texture'UseE'
    Mesh=LodMesh'UnrealShare.EightPick'
    CollisionHeight=10.00
}