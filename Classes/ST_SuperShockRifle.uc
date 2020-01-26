// ===============================================================
// Stats.ST_SuperShockRifle: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_SuperShockRifle extends SuperShockRifle;

#exec Audio Import FILE=Sounds\SSSound.wav Name=SSSound

var ST_Mutator STM;
var bool bNewNet;				// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;
var bool bAltFired;
var float LastFiredTime;

var bool TeamShockEffects;
var() sound 	FFireSound;
var class<TournamentWeapon> OrgClass;
var Class<NN_WeaponFunctions> nnWF;

replication
{
	reliable if( Role==ROLE_Authority )
		TeamShockEffects;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	TeamShockEffects = class'UTPure'.Default.TeamShockEffects;

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

simulated function yModInit()
{
	if (bbPlayer(Owner) != None && Owner.ROLE == ROLE_AutonomousProxy)
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

simulated function bool ClientFire(float Value)
{
	local bbPlayer bbP;
	
	//if (Owner.IsA('Bot'))
		//return Super.ClientFire(Value);
	
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
	
/* 	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	} */
	
	bbP = bbPlayer(Owner);
	bAltFired = false;
	if (bbP != None && bNewNet && Value < 1)
		return;
	bbPlayer(Owner).xxAddFired(26);
	Super.Fire(Value);
}

simulated function PlayFiring()
{
	if(TeamShockEffects)
	{
		PlayOwnedSound(FFireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
	}
	else
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
	if (Level.NetMode == NM_Client)
		LoopAnim('Fire1', 0.20 + 0.20 * FireAdjust,0.05);
	else
		LoopAnim('Fire1', 0.22 + 0.22 * FireAdjust,0.05);
}

simulated function PlayAltFiring()
{
	if(TeamShockEffects)
	{
		PlayOwnedSound(FFireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
	}
	else
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
	LoopAnim('Fire1', 0.20 + 0.20 * FireAdjust,0.05);
}

function AltFire( float Value )
{
	bAltFired = true;
	Super.AltFire(Value);
}

state ClientFiring
{
	simulated function bool ClientFire(float Value)
	{
		local float MinTapTime;
		
		if (Owner.IsA('Bot'))
			return Super.ClientFire(Value);
		
		if (bNewNet)
			MinTapTime = 0.7;
		else
			MinTapTime = 0.2;
		
		if ( Level.TimeSeconds - TapTime < MinTapTime )
			return false;
		bForceFire = bForceFire || ( bCanClientFire && (Pawn(Owner) != None) && (AmmoType.AmmoAmount > 0) );
		return bForceFire;
	}
}
/* 
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
 */
simulated function NN_TraceFire()
{
	local vector HitLocation, HitDiff, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;
	local bool zzbNN_Combo;
	local bbPlayer bbP;
	local Pawn P;
	local bbPlayer zzbbP;
	local actor zzOther;
	local int oRadius,oHeight;
	local vector zzX,zzY,zzZ,zzStartTrace,zzEndTrace,zzHitLocation,zzHitNormal;
	
	//if (Owner.IsA('Bot'))
		//return;
	
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
		
		zzbbP = bbPlayer(Other);
		if (zzbbP != None)
		{
			GetAxes(GV,zzX,zzY,zzZ);
			zzStartTrace = Owner.Location + CDO + yMod * zzY + FireOffset.Z * zzZ;
			zzEndTrace = zzStartTrace + (100000 * vector(GV));
			oRadius = zzbbP.CollisionRadius;
			oHeight = zzbbP.CollisionHeight;
			zzbbP.SetCollisionSize(zzbbP.CollisionRadius * 0.85, zzbbP.CollisionHeight * 0.85);
			zzOther = bbP.NN_TraceShot(zzHitLocation,zzHitNormal,zzEndTrace,zzStartTrace,Pawn(Owner));
			zzbbP.SetCollisionSize(oRadius, oHeight);
		}
	}
	
	zzbNN_Combo = NN_ProcessTraceHit(Other, HitLocation, HitNormal, vector(GV),Y,Z);
	if (zzbNN_Combo)
		bbP.xxNN_Fire(ST_ShockProjBlue(Other).zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, true);
	else
		bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, false);
	if (Other == bbP.zzClientTTarget)
		bbP.zzClientTTarget.TakeDamage(0, Pawn(Owner), HitLocation, 60000.0*vector(GV), MyDamageType);
}

simulated function bool NN_ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local bool zzbNN_Combo;
	
	//if (Owner.IsA('Bot'))
		//return false;
	
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
			if(Pawn(Owner) != None && (Pawn(Owner).PlayerReplicationInfo != None))
			{
				if(TeamShockEffects)
				{
					Switch(Pawn(Owner).PlayerReplicationInfo.Team)
					{
						Case 0:
							Spawn(class'UT_RedRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
							break;
						Case 1:
							Spawn(class'UT_BlueRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
							break;
						Case 2:
							Spawn(class'UT_GreenRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
							break;
						Case 3:
							Spawn(class'UT_GoldRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
							break;
						default:
							Spawn(class'UT_BlueRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
							break;
					}
				}
				else
					Spawn(class'ut_SuperRing2',,, HitLocation+HitNormal*8,rotator(HitNormal));

			if (bbPlayer(Owner) != None && (Pawn(Owner) != None) && (Pawn(Owner).PlayerReplicationInfo != None))
			{
				if(TeamShockEffects)
				{
					Switch(Pawn(Owner).PlayerReplicationInfo.Team)
					{
						case 0:
							bbPlayer(Owner).xxClientDemoFix(None, class'UT_RedRingExplosion2',HitLocation+HitNormal*8,,, rotator(HitNormal));
							break;
						case 1:
							bbPlayer(Owner).xxClientDemoFix(None, class'UT_BlueRingExplosion2',HitLocation+HitNormal*8,,, rotator(HitNormal));
							break;
						case 2:
							bbPlayer(Owner).xxClientDemoFix(None, class'UT_GreenRingExplosion2',HitLocation+HitNormal*8,,, rotator(HitNormal));
							break;
						case 3:
							bbPlayer(Owner).xxClientDemoFix(None, class'UT_GoldRingExplosion2',HitLocation+HitNormal*8,,, rotator(HitNormal));
							break;
						default:
							bbPlayer(Owner).xxClientDemoFix(None, class'UT_BlueRingExplosion2',HitLocation+HitNormal*8,,, rotator(HitNormal));
							break;
					}
				}
				else
					bbPlayer(Owner).xxClientDemoFix(None, class'ut_SuperRing2',HitLocation+HitNormal*8,,, rotator(HitNormal));
			}
		}
	}
	return zzbNN_Combo;
}

simulated function NN_SpawnEffect(vector HitLocation, vector SmokeLocation, vector HitNormal)
{
	local SuperShockBeam Smoke,shock;
	local RedShockBeam RedBeam;
	local BlueShockBeam BlueBeam;
	local GreenShockBeam GreenBeam;
	local GoldShockBeam GoldBeam;
	local Vector DVector;
	local int NumPoints;
	local rotator SmokeRotation;
	
	//if (Owner.IsA('Bot'))
		//return;

	DVector = HitLocation - SmokeLocation;
	NumPoints = VSize(DVector)/135.0;
	if ( NumPoints < 1 )
		return;
	SmokeRotation = rotator(DVector);
	SmokeRotation.roll = Rand(65535);
	
	if(Pawn(Owner) != None && (Owner != None) && (Pawn(Owner).PlayerReplicationInfo != None))
	{
		if(TeamShockEffects)
		{
			Switch(Pawn(Owner).PlayerReplicationInfo.Team)
			{
				Case 0:
					RedBeam = Spawn(class'NN_RedShockBeam',Owner,,SmokeLocation,SmokeRotation);
					RedBeam = Spawn(class'RedShockBeamEffect',Owner,,SmokeLocation,SmokeRotation);
					RedBeam.MoveAmount = DVector/NumPoints;
					RedBeam.NumPuffs = NumPoints - 1;
					break;
				Case 1:
					BlueBeam = Spawn(class'NN_BlueShockBeam',Owner,,SmokeLocation,SmokeRotation);
					BlueBeam = Spawn(class'BlueShockBeamEffect',Owner,,SmokeLocation,SmokeRotation);
					BlueBeam.MoveAmount = DVector/NumPoints;
					BlueBeam.NumPuffs = NumPoints - 1;
					break;
				Case 2:
					GreenBeam = Spawn(class'NN_GreenShockBeam',Owner,,SmokeLocation,SmokeRotation);
					GreenBeam = Spawn(class'GreenShockBeamEffect',Owner,,SmokeLocation,SmokeRotation);
					GreenBeam.MoveAmount = DVector/NumPoints;
					GreenBeam.NumPuffs = NumPoints - 1;
					break;
				Case 3:
					GoldBeam = Spawn(class'NN_GoldShockBeam',Owner,,SmokeLocation,SmokeRotation);
					GoldBeam = Spawn(class'GoldShockBeamEffect',Owner,,SmokeLocation,SmokeRotation);
					GoldBeam.MoveAmount = DVector/NumPoints;
					GoldBeam.NumPuffs = NumPoints - 1;
					break;
				Case 4:
					BlueBeam = Spawn(class'NN_BlueShockBeam',Owner,,SmokeLocation,SmokeRotation);
					BlueBeam = Spawn(class'BlueShockBeamEffect',Owner,,SmokeLocation,SmokeRotation);
					BlueBeam.MoveAmount = DVector/NumPoints;
					BlueBeam.NumPuffs = NumPoints - 1;
					break;
				default:
					BlueBeam = Spawn(class'NN_BlueShockBeam',Owner,,SmokeLocation,SmokeRotation);
					BlueBeam = Spawn(class'BlueShockBeamEffect',Owner,,SmokeLocation,SmokeRotation);
					BlueBeam.MoveAmount = DVector/NumPoints;
					BlueBeam.NumPuffs = NumPoints - 1;
			}
		}
		else
		{
			Smoke = Spawn(class'NN_SuperShockBeam',Owner,,SmokeLocation,SmokeRotation);
			Smoke.MoveAmount = DVector/NumPoints;
			Smoke.NumPuffs = NumPoints - 1;	
		}
	}
	if (bbPlayer(Owner) != None && (bbPlayer(Owner).PlayerReplicationInfo != None))
	{
		if(TeamShockEffects)
		{
			Switch(bbPlayer(Owner).PlayerReplicationInfo.Team)
			{
				Case 0:
					bbPlayer(Owner).xxClientDemoFix(None, class'NN_RedShockBeam',SmokeLocation,,,SmokeRotation);
					bbPlayer(Owner).xxClientDemoFix(None, class'RedShockBeamEffect',SmokeLocation,,,SmokeRotation);
					break;
				Case 1:
					bbPlayer(Owner).xxClientDemoFix(None, class'NN_BlueShockBeam',SmokeLocation,,,SmokeRotation);
					bbPlayer(Owner).xxClientDemoFix(None, class'BlueShockBeamEffect',SmokeLocation,,,SmokeRotation);
					break;
				Case 2:
					bbPlayer(Owner).xxClientDemoFix(None, class'NN_GreenShockBeam',SmokeLocation,,,SmokeRotation);
					bbPlayer(Owner).xxClientDemoFix(None, class'GreenShockBeamEffect',SmokeLocation,,,SmokeRotation);
					break;
				Case 3:
					bbPlayer(Owner).xxClientDemoFix(None, class'NN_GoldShockBeam',SmokeLocation,,,SmokeRotation);
					bbPlayer(Owner).xxClientDemoFix(None, class'GoldShockBeamEffect',SmokeLocation,,,SmokeRotation);
					break;
				Case 4:
					bbPlayer(Owner).xxClientDemoFix(None, class'NN_BlueShockBeam',SmokeLocation,,,SmokeRotation);
					bbPlayer(Owner).xxClientDemoFix(None, class'BlueShockBeamEffect',SmokeLocation,,,SmokeRotation);
					break;
				default:
					bbPlayer(Owner).xxClientDemoFix(None, class'NN_BlueShockBeam',SmokeLocation,,,SmokeRotation);
					bbPlayer(Owner).xxClientDemoFix(None, class'BlueShockBeamEffect',SmokeLocation,,,SmokeRotation);
					break;

			}
		}
		else
			bbPlayer(Owner).xxClientDemoFix(None, class'NN_SuperShockBeam',SmokeLocation,,,SmokeRotation);
	}
}

function TraceFire( float Accuracy )
{
	local bbPlayer bbP;
	local actor NN_Other;
	local bool bShockCombo;
	local NN_ShockProjOwnerHidden NNSP;
	local vector NN_HitLoc, HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	
	//if (Owner.IsA('Bot'))
	//{
		//Super.TraceFire(Accuracy);
		//return;
	//}

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
	local Pawn PawnOwner;
	
	//if (Owner.IsA('Bot'))
	//{
		//Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		//return;
	//}

	yModInit();

	PawnOwner = Pawn(Owner);

	if (STM != None)
		STM.PlayerFire(PawnOwner, 8);		// 8 = Super Shock

	if (Other==None)
	{
		HitNormal = -X;
		HitLocation = Owner.Location + X*10000.0;
	}

	SpawnEffect(HitLocation, Owner.Location + CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * Y + FireOffset.Z * Z);

	if ( NN_ShockProjOwnerHidden(Other)!=None )
	{
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);		// 5 = Shock Beam
		Other.SetOwner(Owner);
		NN_ShockProjOwnerHidden(Other).SuperDuperExplosion();
		return;
	}
	else if ( ST_ShockProj(Other)!=None )
	{
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);		// 5 = Shock Beam
		ST_ShockProj(Other).SuperDuperExplosion();
		return;
	}
	else if (bNewNet && !bAltFired)
	{
		if(Pawn(Owner) != None && (Pawn(Owner).PlayerReplicationInfo != None))
		{
			if(TeamShockEffects)
			{
				Switch(Pawn(owner).PlayerReplicationInfo.Team)
				{
					case 0:
						DoRingExplosion_RED(PlayerPawn(Owner), HitLocation, HitNormal);	
						break;
					case 1:
						DoRingExplosion_BLUE(PlayerPawn(Owner), HitLocation, HitNormal);	
						break;
					case 2:
						DoRingExplosion_GREEN(PlayerPawn(Owner), HitLocation, HitNormal);
						break;
					case 3:
						DoRingExplosion_GOLD(PlayerPawn(Owner), HitLocation, HitNormal);
						break;
					case 4:
						DoRingExplosion_BLUE(PlayerPawn(Owner), HitLocation, HitNormal);
						break;
					default:
						DoRingExplosion_BLUE(PlayerPawn(Owner), HitLocation, HitNormal);
						break;
				}
			}
			else
				DoSuperRing2(PlayerPawn(Owner), HitLocation, HitNormal);
		}	
	}
	else
	{
		if(Pawn(Owner) != None && (Pawn(Owner).PlayerReplicationInfo != None))
		{
			if(TeamShockEffects)
			{
				Switch(Pawn(Owner).PlayerReplicationInfo.Team)
				{
					case 0:
						Spawn(class'UT_RedRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
						break;
					case 1:
						Spawn(class'UT_BlueRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
						break;
					case 2:
						Spawn(class'UT_GreenRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
						break;
					case 3:
						Spawn(class'UT_GoldRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
						break;
					case 4:
						Spawn(class'UT_BlueRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
						break;
					default:
						Spawn(class'UT_BlueRingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
						break;
				}
			}
			else
				Spawn(class'ut_SuperRing2',,, HitLocation+HitNormal*8,rotator(HitNormal));
		}
	}
	
	if ( (Other != self) && (Other != Owner) && (Other != None) ) 
	{
		if (STM != None)
			STM.PlayerHit(PawnOwner, 8, (PawnOwner.Physics == PHYS_Falling) && (Other.Physics == PHYS_Falling));
						// 8 = Super Shock, Special if Both players are off the ground.
		Other.TakeDamage(HitDamage, PawnOwner, HitLocation, 60000.0*X, MyDamageType);
		if (STM != None)
			STM.PlayerClear();
	}
}

simulated function DoSuperRing2(PlayerPawn Pwner, vector HitLocation, vector HitNormal)
{
	local PlayerPawn P;
	local Actor CR;
	
	//if (Owner.IsA('Bot'))
		//return;

	if (RemoteRole < ROLE_Authority) {
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
			if (P != Pwner) {
				CR = P.Spawn(class'ut_SuperRing2',P,, HitLocation+HitNormal*8,rotator(HitNormal));
				CR.bOnlyOwnerSee = True;
			}
	}
}

simulated function DoRingExplosion_RED(PlayerPawn Pwner, vector HitLocation, vector HitNormal)
{
	local PlayerPawn P;
	local Actor CR;
	
	//if (Owner.IsA('Bot'))
		//return;

	if (RemoteRole < ROLE_Authority) {
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
			if (P != Pwner) {
				CR = P.Spawn(class'UT_RedRingExplosion2',P,, HitLocation+HitNormal*8,rotator(HitNormal));
				CR.bOnlyOwnerSee = True;
			}
	}
}

simulated function DoRingExplosion_BLUE(PlayerPawn Pwner, vector HitLocation, vector HitNormal)
{
	local PlayerPawn P;
	local Actor CR;
	
	//if (Owner.IsA('Bot'))
		//return;

	if (RemoteRole < ROLE_Authority) {
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
			if (P != Pwner) {
				CR = P.Spawn(class'UT_BlueRingExplosion2',P,, HitLocation+HitNormal*8,rotator(HitNormal));
				CR.bOnlyOwnerSee = True;
			}
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

simulated function DoRingExplosion_GOLD(PlayerPawn Pwner, vector HitLocation, vector HitNormal)
{
	local PlayerPawn P;
	local Actor CR;
	
	///if (Owner.IsA('Bot'))
		//return;

	if (RemoteRole < ROLE_Authority) {
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
			if (P != Pwner) {
				CR = P.Spawn(class'UT_GoldRingExplosion2',P,, HitLocation+HitNormal*8,rotator(HitNormal));
				CR.bOnlyOwnerSee = True;
			}
	}
}

function SpawnEffect(vector HitLocation, vector SmokeLocation)
{
	local SuperShockBeam Smoke,shock;
	local RedShockBeam RedBeam;
	local BlueShockBeam BlueBeam;
	local GreenShockBeam GreenBeam;
	local GoldShockBeam GoldBeam;
	local Vector DVector;
	local int NumPoints;
	local rotator SmokeRotation;
	
	//if (Owner.IsA('Bot'))
	//{
		//Super.SpawnEffect(HitLocation, SmokeLocation);
		//return;
	//}

	DVector = HitLocation - SmokeLocation;
	NumPoints = VSize(DVector)/135.0;
	if ( NumPoints < 1 )
		return;
	SmokeRotation = rotator(DVector);
	SmokeRotation.roll = Rand(65535);
	
	if (bNewNet && !bAltFired)
	{
		if(Pawn(Owner) != None && (Pawn(Owner).PlayerReplicationInfo != None))
		{
			if(TeamShockEffects)
			{
				Switch(Pawn(Owner).PlayerReplicationInfo.Team)
				{
					Case 0:
						RedBeam = Spawn(class'NN_RedShockBeamOwnerHidden',Owner,,SmokeLocation,SmokeRotation);
						RedBeam = Spawn(class'RedShockBeamEffectOH',Owner,,SmokeLocation,SmokeRotation);
						RedBeam.MoveAmount = DVector/NumPoints;
						RedBeam.NumPuffs = NumPoints - 1;
						break;
					Case 1:
						BlueBeam = Spawn(class'NN_BlueShockBeamOwnerHidden',Owner,,SmokeLocation,SmokeRotation);
						BlueBeam = Spawn(class'BlueShockBeamEffectOH',Owner,,SmokeLocation,SmokeRotation);
						BlueBeam.MoveAmount = DVector/NumPoints;
						BlueBeam.NumPuffs = NumPoints - 1;
						break;
					Case 2:
						GreenBeam = Spawn(class'NN_GreenShockBeamOwnerHidden',Owner,,SmokeLocation,SmokeRotation);
						GreenBeam = Spawn(class'GreenShockBeamEffectOH',Owner,,SmokeLocation,SmokeRotation);
						GreenBeam.MoveAmount = DVector/NumPoints;
						GreenBeam.NumPuffs = NumPoints - 1;
						break;
					Case 3:
						GoldBeam = Spawn(class'NN_GoldShockBeamOwnerHidden',Owner,,SmokeLocation,SmokeRotation);
						GoldBeam = Spawn(class'GoldShockBeamEffectOH',Owner,,SmokeLocation,SmokeRotation);
						GoldBeam.MoveAmount = DVector/NumPoints;
						GoldBeam.NumPuffs = NumPoints - 1;
						break;
					Case 4:
						BlueBeam = Spawn(class'NN_BlueShockBeamOwnerHidden',Owner,,SmokeLocation,SmokeRotation);
						BlueBeam = Spawn(class'BlueShockBeamEffectOH',Owner,,SmokeLocation,SmokeRotation);
						BlueBeam.MoveAmount = DVector/NumPoints;
						BlueBeam.NumPuffs = NumPoints - 1;
						break;
					default:
						BlueBeam = Spawn(class'NN_BlueShockBeamOwnerHidden',Owner,,SmokeLocation,SmokeRotation);
						BlueBeam = Spawn(class'BlueShockBeamEffectOH',Owner,,SmokeLocation,SmokeRotation);
						BlueBeam.MoveAmount = DVector/NumPoints;
						BlueBeam.NumPuffs = NumPoints - 1;
						break;
				}
			}
			else
			{
				Smoke = Spawn(class'NN_SuperShockBeamOwnerHidden',Owner,,SmokeLocation,SmokeRotation);
				Smoke.MoveAmount = DVector/NumPoints;
				Smoke.NumPuffs = NumPoints - 1;
			}
		}
	}
	else
	{
			if (bbPlayer(Owner) != None && (Pawn(Owner) != None) && (Pawn(Owner).PlayerReplicationInfo != None))
			{
				if(TeamShockEffects)
				{
					Switch(Pawn(Owner).PlayerReplicationInfo.Team)
					{
					Case 0:
						RedBeam = Spawn(class'NN_RedShockBeam',,,SmokeLocation,SmokeRotation);
						RedBeam = Spawn(class'RedShockBeamEffect',,,SmokeLocation,SmokeRotation);
						RedBeam.MoveAmount = DVector/NumPoints;
						RedBeam.NumPuffs = NumPoints - 1;
						break;
					Case 1:
						BlueBeam = Spawn(class'NN_BlueShockBeam',,,SmokeLocation,SmokeRotation);
						BlueBeam = Spawn(class'BlueShockBeamEffect',,,SmokeLocation,SmokeRotation);						
						BlueBeam.MoveAmount = DVector/NumPoints;
						BlueBeam.NumPuffs = NumPoints - 1;
						break;
					Case 2:
						GreenBeam = Spawn(class'NN_GreenShockBeam',,,SmokeLocation,SmokeRotation);
						GreenBeam = Spawn(class'GreenShockBeamEffect',,,SmokeLocation,SmokeRotation);
						GreenBeam.MoveAmount = DVector/NumPoints;
						GreenBeam.NumPuffs = NumPoints - 1;
						break;
					Case 3:
						GoldBeam = Spawn(class'NN_GoldShockBeam',,,SmokeLocation,SmokeRotation);
						GoldBeam = Spawn(class'GoldShockBeamEffect',,,SmokeLocation,SmokeRotation);
						GoldBeam.MoveAmount = DVector/NumPoints;
						GoldBeam.NumPuffs = NumPoints - 1;
						break;
					Case 4:
						BlueBeam = Spawn(class'NN_BlueShockBeam',,,SmokeLocation,SmokeRotation);
						BlueBeam = Spawn(class'BlueShockBeamEffect',,,SmokeLocation,SmokeRotation);						
						BlueBeam.MoveAmount = DVector/NumPoints;
						BlueBeam.NumPuffs = NumPoints - 1;
						break;
					default:
						BlueBeam = Spawn(class'NN_BlueShockBeam',,,SmokeLocation,SmokeRotation);
						BlueBeam = Spawn(class'BlueShockBeamEffect',,,SmokeLocation,SmokeRotation);						
						BlueBeam.MoveAmount = DVector/NumPoints;
						BlueBeam.NumPuffs = NumPoints - 1;
						break;
				}
			}
			else
			{
				Smoke = Spawn(class'NN_SuperShockBeam',Owner,,SmokeLocation,SmokeRotation);
				Smoke.MoveAmount = DVector/NumPoints;
				Smoke.NumPuffs = NumPoints - 1;
			}
		}
	}
//	Log("MoveAmount="$Smoke.MoveAmount);
//	Log("NumPuffs="$Smoke.NumPuffs);
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'SuperShockRifle');
}

simulated function PlaySelect ()
{
	Class'NN_WeaponFunctions'.static.PlaySelect( self);
	if(TeamShockEffects)
	{
		SetTeamSkins();
	}
}

simulated function TweenDown ()
{
	Class'NN_WeaponFunctions'.static.TweenDown( self);
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

simulated function SetTeamSkins()
{
	Class'NNTeamShock'.static.SetTeamSkins( self);
}

defaultproperties
{
     bNewNet=True
     PickupViewMesh=LodMesh'Botpack.SASMD2hand'
     FFireSound=Sound'SSSound'
     PickupViewScale=1.750000
	 FireOffset=(X=10.000000,Y=-7.000000,Z=-9.000000)
	 nnWF=Class'NN_WeaponFunctions'
}
