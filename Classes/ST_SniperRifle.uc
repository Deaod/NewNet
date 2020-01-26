// ===============================================================
// Stats.ST_SniperRifle: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_SniperRifle extends SniperRifle;

var ST_Mutator STM;
var bool bNewNet;		// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;
var float HitDamage;
var float HeadDamage;
var float BodyHeight;
var float SniperSpeed;
var Projectile Tracked;
var bool bBotSpecialMove;
var float TapTime;

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
		else if (bbP.bAltFire != 0 && !IsInState('ClientAltFiring'))
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

simulated function bool ClientFire(float Value)
{
	local bbPlayer bbP;
	
	//if (Owner.IsA('Bot'))
		//return Super.ClientFire(Value);
	
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
	if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
		return false;
	return Super.ClientAltFire(Value);
}

function Fire ( float Value )
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;
	Super.Fire(Value);
}

function AltFire( float Value )
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
	{
		Super.AltFire(Value);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;
	Super.AltFire(Value);
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
}

simulated function NN_TraceFire()
{
	local vector HitLocation, HitDiff, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local bool bHeadshot;
	
	//if (Owner.IsA('Bot'))
		//return;
	
	yModInit();
	
	PawnOwner = Pawn(Owner);
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return;

//	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(GV,X,Y,Z);
	StartTrace = Owner.Location + CDO + yMod * Y + FireOffset.Z * Z;
	EndTrace = StartTrace + (100000 * vector(GV)); 
	
	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,PawnOwner);
	if (Other.IsA('Pawn'))
		HitDiff = HitLocation - Other.Location;
	
	bHeadshot = NN_ProcessTraceHit(Other, HitLocation, HitNormal, X,Y,Z,yMod);
	bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, bHeadshot);
}

simulated function bool NN_ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z, float yMod)
{
	local UT_Shellcase s;
	local Pawn PawnOwner;
	local float CH;
	
	//if (Owner.IsA('Bot'))
		//return false;

	PawnOwner = Pawn(Owner);

	NN_SpawnEffect(HitLocation, Owner.Location + CDO + (FireOffset.X + 20) * X + Y * yMod + FireOffset.Z * Z, HitNormal);

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
			if ((Other.GetAnimGroup(Other.AnimSequence) == 'Ducking') && (Other.AnimFrame > -0.03))
				CH = 0.3 * Other.CollisionHeight;
			else
				CH = Other.CollisionHeight;
			
			if (HitLocation.Z - Other.Location.Z > BodyHeight * CH)
				return true;
		}
		
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9);	
	}
	return false;
}

simulated function NN_SpawnEffect(vector HitLocation, vector SmokeLocation, vector HitNormal)
{
	local RedSniperTrace st;
	local BlueSniperTrace bst;
	local GreenSniperTrace gst;
	local GoldSniperTrace gost;
	local Vector DVector;
	local int NumPoints;
	local rotator SmokeRotation;

	//if (Owner.IsA('Bot'))
		//return;

	DVector = HitLocation - SmokeLocation;
	NumPoints = VSize(DVector)/150;
	if ( NumPoints < 1 )
		return;
	SmokeRotation = rotator(DVector);
	SmokeRotation.roll = Rand(65535);

	if(Pawn(Owner) != None && Owner != None)
	{
		if(class'IndiaSettings'.default.bSniperTraceEffects)
		{
			if(Pawn(Owner).PlayerReplicationInfo.Team == 0)
			{
				st = Spawn(class'NN_RedSniperTrace',Owner,,SmokeLocation,SmokeRotation);
				st.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
				st.NumPuffs = NumPoints - 1;
			}
			else if(Pawn(Owner).PlayerReplicationInfo.Team == 1)
			{
				bst = Spawn(class'NN_BlueSniperTrace',Owner,,SmokeLocation,SmokeRotation);
				bst.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
				bst.NumPuffs = NumPoints - 1;
			}
			else if(Pawn(Owner).PlayerReplicationInfo.Team == 2)
			{
				gst = Spawn(class'NN_GreenSniperTrace',Owner,,SmokeLocation,SmokeRotation);
				gst.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
				gst.NumPuffs = NumPoints - 1;
			}
			else if(Pawn(Owner).PlayerReplicationInfo.Team == 3)
			{
				gost = Spawn(class'NN_GoldSniperTrace',Owner,,SmokeLocation,SmokeRotation);
				gost.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
				gost.NumPuffs = NumPoints - 1;
			}
			else if(Pawn(Owner).PlayerReplicationInfo.Team >= 4)
			{
				st = Spawn(class'NN_RedSniperTrace',Owner,,SmokeLocation,SmokeRotation);
				st.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
				st.NumPuffs = NumPoints - 1;
			}
		}
	}

	if (bbPlayer(Owner) != None)
	{
		if(class'IndiaSettings'.default.bSniperTraceEffects)
		{
			if(Pawn(Owner).PlayerReplicationInfo.Team == 0)
			{
				bbPlayer(Owner).xxClientDemoFix(None, class'NN_RedSniperTrace',SmokeLocation,,,SmokeRotation);
			}
			else if(Pawn(Owner).PlayerReplicationInfo.Team == 1)
			{
				bbPlayer(Owner).xxClientDemoFix(None, class'NN_BlueSniperTrace',SmokeLocation,,,SmokeRotation);
			}
			else if(Pawn(Owner).PlayerReplicationInfo.Team == 2)
			{
				bbPlayer(Owner).xxClientDemoFix(None, class'NN_GreenSniperTrace',SmokeLocation,,,SmokeRotation);
			}
			else if(Pawn(Owner).PlayerReplicationInfo.Team == 3)
			{
				bbPlayer(Owner).xxClientDemoFix(None, class'NN_GoldSniperTrace',SmokeLocation,,,SmokeRotation);
			}
			else if(Pawn(Owner).PlayerReplicationInfo.Team >= 4)
			{
				bbPlayer(Owner).xxClientDemoFix(None, class'NN_RedSniperTrace',SmokeLocation,,,SmokeRotation);
			}
		}
	}
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
	
	//if (Owner.IsA('Bot'))
	//{
		//Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		//return;
	//}

	//if(Owner.IsA('Bot'))
	//{
		//GetAxes(Pawn(Owner).ViewRotation, X, Y, Z);
	//}
	//if (bbP == None || !bNewNet)
	//{
		//Super.ProcessTraceHit(Other, HitLocation, HitNormal, X,Y,Z);
		//return;
	//}

	PawnOwner = Pawn(Owner);
	POther = Pawn(Other);
	PPOther = PlayerPawn(Other);
	if (STM != None)
		STM.PlayerFire(PawnOwner, 18);		// 18 = Sniper

	if (Other==None)
	{
		HitNormal = -X;
		HitLocation = Owner.Location + X*10000.0;
	}
	
	bbP = bbPlayer(Owner);

	if(Owner.IsA('Bot') || Instigator != Owner)
		SpawnEffect(HitLocation, Owner.Location + CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * Y + FireOffset.Z * Z);

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
		
		if ( bbP.zzbNN_Special || !bNewNet &&
			Other.bIsPawn && (HitLocation.Z - Other.Location.Z > BodyHeight * Other.CollisionHeight) 
			&& (instigator.IsA('PlayerPawn') || (instigator.IsA('Bot') && !Bot(Instigator).bNovice)) )
			//&& !PPOther.bIsCrouching && PPOther.GetAnimGroup(PPOther.AnimSequence) != 'Ducking' )
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

function SpawnEffect(vector HitLocation, vector SmokeLocation)
{
	local RedSniperTrace2 Rings;
	local BlueSniperTrace2 BRings;
	local GreenSniperTrace2 GRings;
	local GoldSniperTrace2 GoRings;
	local Vector DVector;
	local int NumPoints;
	local rotator SmokeRotation;

	//if (Owner.IsA('Bot'))
	//{
		//return;
	//}

	DVector = HitLocation - SmokeLocation;
	NumPoints = VSize(DVector)/150;
	if ( NumPoints < 1 )
		return;
	SmokeRotation = rotator(DVector);
	SmokeRotation.roll = Rand(65535);
	
	if(bNewNet)
	{
		if(Pawn(Owner) != None)
		{
			if(class'IndiaSettings'.default.bSniperTraceEffects)
			{
				if(Pawn(Owner).PlayerReplicationInfo.Team == 0)
				{
					Rings = Spawn(class'RedSniperTrace2',,,SmokeLocation,SmokeRotation);
					Rings.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
					Rings.NumPuffs = NumPoints - 1;
				}
				else if(Pawn(Owner).PlayerReplicationInfo.Team == 1)
				{
					BRings = Spawn(class'BlueSniperTrace2',,,SmokeLocation,SmokeRotation);
					BRings.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
					BRings.NumPuffs = NumPoints - 1;
				}
				else if(Pawn(Owner).PlayerReplicationInfo.Team == 2)
				{
					GRings = Spawn(class'GreenSniperTrace2',,,SmokeLocation,SmokeRotation);
					GRings.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
					GRings.NumPuffs = NumPoints - 1;
				}
				else if(Pawn(Owner).PlayerReplicationInfo.Team == 3)
				{
					GoRings = Spawn(class'GoldSniperTrace2',,,SmokeLocation,SmokeRotation);
					GoRings.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
					GoRings.NumPuffs = NumPoints - 1;
				}
				else if(Pawn(Owner).PlayerReplicationInfo.Team >= 4)
				{
					Rings = Spawn(class'RedSniperTrace2',,,SmokeLocation,SmokeRotation);
					Rings.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
					Rings.NumPuffs = NumPoints - 1;
				}
			}
		}
	}
	/*else
	{
		Rings = Spawn(class'NN_RedSniperTraceOwnerHidden',,,SmokeLocation,SmokeRotation);
		Rings.MoveAmount = Normal(DVector) * 10000; //Multiply because sending it over net
		Rings.NumPuffs = NumPoints - 1;
	}*/
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
	
	if (bbP.zzNN_HitActor.IsA('bbPlayer') && !bbPlayer(bbP.zzNN_HitActor).xxCloseEnough(bbP.zzNN_HitLoc))
		bbP.zzNN_HitActor = None;
	
	Owner.MakeNoise(bbP.SoundDampening);
	GetAxes(bbP.zzNN_ViewRot,X,Y,Z);
	GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
	
	/*StartTrace = Owner.Location + bbP.Eyeheight * Z; 
	AdjustedAim = bbP.AdjustAim(1000000, StartTrace, 2*AimError, False, False);	
	X = vector(AdjustedAim);
	EndTrace = StartTrace + 10000 * X;*/

	StartTrace = Owner.Location + CalcDrawOffset() + FireOffset.Y * Y + FireOffset.Z * Z; 
	EndTrace = StartTrace + Accuracy * (FRand() - 0.5 )* Y * 1000
		+ Accuracy * (FRand() - 0.5 ) * Z * 1000 ;

	if ( bBotSpecialMove && (Tracked != None)
		&& (((Owner.Acceleration == vect(0,0,0)) && (VSize(Owner.Velocity) < 40)) ||
			(Normal(Owner.Velocity) Dot Normal(Tracked.Velocity) > 0.95)) )
		EndTrace += MaxTargetRange * Normal(Tracked.Location - StartTrace);
	else
	{
		AdjustedAim = pawn(owner).AdjustAim(1000000, StartTrace, 2.75*AimError, False, False);	
		EndTrace += (MaxTargetRange * vector(AdjustedAim)); 
	}

	Tracked = None;
	bBotSpecialMove = false;
	
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
	if(Pawn(Owner) != None)
	{
		if(Class'IndiaSettings'.default.bFWS)
			PlayAnim('Select',1000.00);
		else	
			PlayAnim('Select',1.35 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000,0.0);
	}
	Owner.PlaySound(SelectSound, SLOT_Misc, Pawn(Owner).SoundDampening);	
}

simulated function TweenDown()
{
	if(Pawn(Owner) != None)
	{
		if(Class'IndiaSettings'.default.bFWS)
			PlayAnim('Down',1000.00);
		else	
			PlayAnim('Down',1.35 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000,0.05);
	}
}

simulated function PlayFiring()
{
	local int r;

	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*3.0);
	if (SniperSpeed > 0)
		PlayAnim(FireAnims[Rand(5)], 0.53 * SniperSpeed + 0.53 * FireAdjust, 0.05);
	else
		PlayAnim(FireAnims[Rand(5)], 0.53 * class'UTPure'.default.SniperSpeed + 0.53 * FireAdjust, 0.05);

	if ( (PlayerPawn(Owner) != None) 
		&& (PlayerPawn(Owner).DesiredFOV == PlayerPawn(Owner).DefaultFOV) )
		bMuzzleFlash++;
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

defaultproperties
{
     bNewNet=True
     BodyHeight=0.660000
}
