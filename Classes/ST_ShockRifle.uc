class ST_ShockRifle extends ShockRifle;

var ST_Mutator STM;
var bool bNewNet;								// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;
var float LastFiredTime;
var Class<NN_WeaponFunctions> nnWF;

// For Special Shock Beam
var int HitCounter;

var bool TeamShockEffects;

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
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Level.TimeSeconds - LastFiredTime < 0.4)
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

simulated function NN_TraceFire()
{
	local vector HitLocation, HitDiff, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;
	local bool zzbNN_Combo;
	local bbPlayer bbP;
	local Pawn P;
	
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
	
	//for (P = Level.PawnList; P != None; P = P.NextPawn)
	//	P.SetCollisionSize(P.CollisionRadius * ShockRadius / 100, P.CollisionHeight);

	Other = bbP.NN_TraceShot(HitLocation,HitNormal,EndTrace,StartTrace,Pawn(Owner));
	if (Other.IsA('Pawn'))
		HitDiff = HitLocation - Other.Location;
	
	zzbNN_Combo = NN_ProcessTraceHit(Other, HitLocation, HitNormal, vector(GV),Y,Z);
	if(bbP != None && (bbP.PlayerReplicationInfo != None))
	{
		if(TeamShockEffects)
		{
			Switch(bbP.PlayerReplicationInfo.Team)
			{
				Case 0:
					if (zzbNN_Combo)
						bbP.xxNN_Fire(ST_ShockProjRed(Other).zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, true);
					else
						bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, false);
					break;
				Case 1:
					if (zzbNN_Combo)
						bbP.xxNN_Fire(ST_ShockProjBlue(Other).zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, true);
					else
						bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, false);
					break;
				Case 2:
					if (zzbNN_Combo)
						bbP.xxNN_Fire(ST_ShockProjGreen(Other).zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, true);
					else
						bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, false);
					break;
				Case 3:
					if (zzbNN_Combo)
						bbP.xxNN_Fire(ST_ShockProjGold(Other).zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, true);
					else
						bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, false);
					break;
				default:
					if (zzbNN_Combo)
						bbP.xxNN_Fire(ST_ShockProjBlue(Other).zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, true);
					else
						bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, false);
					break;
			}
		}
		else
		{
			if (zzbNN_Combo)
				bbP.xxNN_Fire(ST_ShockProj(Other).zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, true);
			else
				bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation, Other, HitLocation, HitDiff, false);
		}
	}
	if (Other == bbP.zzClientTTarget)
		bbP.zzClientTTarget.TakeDamage(0, Pawn(Owner), HitLocation, 60000.0*vector(GV), MyDamageType);
	
	//for (P = Level.PawnList; P != None; P = P.NextPawn)
	//	P.SetCollisionSize(P.Default.CollisionRadius, P.CollisionHeight);
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

	//if(Pawn(Owner) != None && (Pawn(Owner).PlayerReplicationInfo != None))
	//{
		if ( ST_ShockProjRed(Other)!=None )
		{
			ST_ShockProjRed(Other).NN_SuperExplosion(Pawn(Owner));
			zzbNN_Combo = true;
		}
		else if ( ST_ShockProjBlue(Other)!=None )
		{
			ST_ShockProjBlue(Other).NN_SuperExplosion(Pawn(Owner));
			zzbNN_Combo = true;
		}
		else if ( ST_ShockProjGreen(Other)!=None )
		{
			ST_ShockProjGreen(Other).NN_SuperExplosion(Pawn(Owner));
			zzbNN_Combo = true;
		}
		else if ( ST_ShockProjGold(Other)!=None )
		{
			ST_ShockProjGold(Other).NN_SuperExplosion(Pawn(Owner));
			zzbNN_Combo = true;
		}
		else if ( ST_ShockProj(Other)!=None )
		{
			ST_ShockProj(Other).NN_SuperExplosion(Pawn(Owner));
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
					Spawn(class'UT_RingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));

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
					bbPlayer(Owner).xxClientDemoFix(None, class'UT_RingExplosion2',HitLocation+HitNormal*8,,, rotator(HitNormal));
			}
		}
	}
	
	//if (Other.IsA('Mover'))
	//	bbPlayer(Owner).xxMover_TakeDamage(Mover(Other), HitDamage, Pawn(Owner), HitLocation, 60000.0 * X, MyDamageType);

	//if ( (Other != self) && (Other != Owner) && (bbPlayer(Other) != None) ) 
	//	bbPlayer(Other).NN_Momentum( 60000.0*X );
	return zzbNN_Combo;
}

simulated function NN_SpawnEffect(vector HitLocation, vector SmokeLocation, vector HitNormal)
{
	local ShockBeam Smoke,shock;
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
					break;
			}
		}
		else
		{
			Smoke = Spawn(class'NN_ShockBeam',Owner,,SmokeLocation,SmokeRotation);
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
			bbPlayer(Owner).xxClientDemoFix(None, class'NN_ShockBeam',SmokeLocation,,,SmokeRotation);
	}
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
	if ( bbP != None )
	{
		bbPlayer(Owner).xxAddFired(8);
	}
	Super.Fire(Value);
}

function AltFire( float Value )
{
	local actor HitActor;
	local vector HitLocation, HitNormal, Start;
	local bbPlayer bbP;
	local NN_ShockProjOwnerHidden NNSP;
	local NN_ShockProjRedOwnerHidden RNNSP;
	local NN_ShockProjBlueOwnerHidden BNNSP;
	local NN_ShockProjGreenOwnerHidden GNNSP;
	local NN_ShockProjGoldOwnerHidden GoNNSP;
	
	/*if (Owner.IsA('Bot'))
	{
		Super.AltFire(Value);
		return;
	}*/
	
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
		if ( bbP != None )
		{
			bbPlayer(Owner).xxAddFired(8);
		}
		GotoState('AltFiring');
		bCanClientFire = true;
		if ( Owner.IsA('Bot') )
		{
			if ( Bot(Owner).IsInState('TacticalMove') && (Bot(Owner).Target == Pawn(Owner).Enemy)
			 && (Bot(Owner).Physics == PHYS_Walking) && !Bot(Owner).bNovice
			 && (FRand() * 6 < Pawn(Owner).Skill) )
				Pawn(Owner).SpecialFire();
		}
		bPointing=True;
		ClientAltFire(value);
		if (bNewNet)
		{
			if(Pawn(Owner) != None && (Pawn(Owner).PlayerReplicationInfo != None))
			{
				if(TeamShockEffects)
				{
					Switch(Pawn(Owner).PlayerReplicationInfo.Team)
					{
						case 0:
							RNNSP = NN_ShockProjRedOwnerHidden(ProjectileFire(Class'NN_ShockProjRedOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
							if (RNNSP != None)
							{
								RNNSP.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
								if (bbP != None)
									RNNSP.zzNN_ProjIndex = bbP.xxNN_AddProj(RNNSP);
							}
							break;
						case 1:
							BNNSP = NN_ShockProjBlueOwnerHidden(ProjectileFire(Class'NN_ShockProjBlueOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
							if (BNNSP != None)
							{
								BNNSP.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
								if (bbP != None)
									BNNSP.zzNN_ProjIndex = bbP.xxNN_AddProj(BNNSP);
							}
							break;
						case 2:
							GNNSP = NN_ShockProjGreenOwnerHidden(ProjectileFire(Class'NN_ShockProjGreenOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
							if (GNNSP != None)
							{
								GNNSP.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
								if (bbP != None)
									GNNSP.zzNN_ProjIndex = bbP.xxNN_AddProj(GNNSP);
							}
							break;
						case 3:
							GoNNSP = NN_ShockProjGoldOwnerHidden(ProjectileFire(Class'NN_ShockProjGoldOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
							if (GoNNSP != None)
							{
								GoNNSP.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
								if (bbP != None)
									GoNNSP.zzNN_ProjIndex = bbP.xxNN_AddProj(GoNNSP);
							}
							break;
						default:
							BNNSP = NN_ShockProjBlueOwnerHidden(ProjectileFire(Class'NN_ShockProjBlueOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
							if (BNNSP != None)
							{
								BNNSP.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
								if (bbP != None)
									BNNSP.zzNN_ProjIndex = bbP.xxNN_AddProj(BNNSP);
							}
							break;
					}
				}
				else
				{
					NNSP = NN_ShockProjOwnerHidden(ProjectileFire(Class'NN_ShockProjOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
					if (NNSP != None)
					{
						NNSP.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
						if (bbP != None)
							NNSP.zzNN_ProjIndex = bbP.xxNN_AddProj(NNSP);
					}
				}
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
						Case 0:
							Pawn(Owner).PlayRecoil(FiringSpeed);
							ProjectileFire(Class'ST_ShockProjRed', AltProjectileSpeed, bAltWarnTarget);
							break;
						Case 1:
							Pawn(Owner).PlayRecoil(FiringSpeed);
							ProjectileFire(Class'ST_ShockProjBlue', AltProjectileSpeed, bAltWarnTarget);
							break;
						Case 2:
							Pawn(Owner).PlayRecoil(FiringSpeed);
							ProjectileFire(Class'ST_ShockProjGreen', AltProjectileSpeed, bAltWarnTarget);
							break;
						Case 3:
							Pawn(Owner).PlayRecoil(FiringSpeed);
							ProjectileFire(Class'ST_ShockProjGold', AltProjectileSpeed, bAltWarnTarget);
							break;
						default:
							Pawn(Owner).PlayRecoil(FiringSpeed);
							ProjectileFire(Class'ST_ShockProjBlue', AltProjectileSpeed, bAltWarnTarget);
							break;
					}
				}
				else
				{
					Pawn(Owner).PlayRecoil(FiringSpeed);
					ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget);
				}
			}
		}
	}
}

state ClientFiring
{
	simulated function bool ClientFire(float Value)
	{
		local float MinTapTime;
		
		if (Owner.IsA('Bot'))
			return Super.ClientFire(Value);
		
		if (bNewNet)
			MinTapTime = 0.4;
		else
			MinTapTime = 0.2;
		
		if ( Level.TimeSeconds - TapTime < MinTapTime )
			return false;
		bForceFire = bForceFire || ( bCanClientFire && (Pawn(Owner) != None) && (AmmoType.AmmoAmount > 0) );
		return bForceFire;
	}

	simulated function bool ClientAltFire(float Value)
	{
		local float MinTapTime;
		
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(Value);
		
		if (bNewNet)
			MinTapTime = 0.4;
		else
			MinTapTime = 0.2;
		
		if ( Level.TimeSeconds - TapTime < MinTapTime )
			return false;
		bForceAltFire = bForceAltFire || ( bCanClientFire && (Pawn(Owner) != None) && (AmmoType.AmmoAmount > 0) );
		return bForceAltFire;
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
		}			
		Super.AnimEnd();
	}
}

state ClientAltFiring
{	
	simulated function AnimEnd()
	{
		Super.AnimEnd();
		if (Owner.IsA('Bot'))
			return;
		if (!bNewNet || Level.NetMode != NM_Client)
			return;
		if ( bForceFire || (PlayerPawn(Owner).bFire != 0) )
			Global.ClientFire(1);
		else if ( bForceAltFire || (PlayerPawn(Owner).bAltFire != 0) )
			Global.ClientAltFire(1);
	}
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

function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;
	local PlayerPawn PlayerOwner;
	local bbPlayer bbP;
	
	//if (Owner.IsA('Bot'))
		//return Super.ProjectileFire(ProjClass, ProjSpeed, bWarn);

	PlayerOwner = PlayerPawn(Owner);
	bbP = bbPlayer(Owner);
	
	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	if (bNewNet && bbP != None)
	{
		if (Level.TimeSeconds - LastFiredTime < 0.4)
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
	local ST_ShockProj ST_Proj;
	local ST_ShockProjRed ST_ProjRed;
	local ST_ShockProjBlue ST_ProjBlue;
	local ST_ShockProjGreen ST_ProjGreen;
	local ST_ShockProjGold ST_ProjGold;
	local int ProjIndex;
	local bbPlayer bbP;
	
	//if (Owner.IsA('Bot'))
		//return None;
	
	yModInit();
	
	bbP = bbPlayer(Owner);
	if (bbP == None || (Level.TimeSeconds - LastFiredTime) < 0.4)
		return None;
		
	GetAxes(GV,X,Y,Z);
	Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
	if ( PlayerOwner != None )
		PlayerOwner.ClientInstantFlash( -0.4, vect(450, 190, 650));
	
	LastFiredTime = Level.TimeSeconds;
	Proj = Spawn(ProjClass,Owner,, Start,GV);
	if(bbP != None && bbP.PlayerReplicationInfo != None)
	{
		if(TeamShockEffects)
		{
			Switch(bbP.PlayerReplicationInfo.Team)
			{
				case 0:
					ST_ProjRed = ST_ShockProjRed(Proj);
					ProjIndex = bbP.xxNN_AddProj(Proj);
					if (ST_ProjRed != None)
						ST_ProjRed.zzNN_ProjIndex = ProjIndex;
					bbP.xxNN_AltFire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
					bbP.xxClientDemoFix(ST_ProjRed, Class'ShockProj', Start, ST_ProjRed.Velocity, Proj.Acceleration, GV);
					break;
				case 1:
					ST_ProjBlue = ST_ShockProjBlue(Proj);
					ProjIndex = bbP.xxNN_AddProj(Proj);
					if (ST_ProjBlue != None)
						ST_ProjBlue.zzNN_ProjIndex = ProjIndex;
					bbP.xxNN_AltFire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
					bbP.xxClientDemoFix(ST_ProjBlue, Class'ShockProj', Start, ST_ProjBlue.Velocity, Proj.Acceleration, GV);
					break;
				case 2:
					ST_ProjGreen = ST_ShockProjGreen(Proj);
					ProjIndex = bbP.xxNN_AddProj(Proj);
					if (ST_ProjGreen != None)
						ST_ProjGreen.zzNN_ProjIndex = ProjIndex;
					bbP.xxNN_AltFire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
					bbP.xxClientDemoFix(ST_ProjGreen, Class'ShockProj', Start, ST_ProjGreen.Velocity, Proj.Acceleration, GV);
					break;
				case 3:
					ST_ProjGold = ST_ShockProjGold(Proj);
					ProjIndex = bbP.xxNN_AddProj(Proj);
					if (ST_ProjGold != None)
						ST_ProjGold.zzNN_ProjIndex = ProjIndex;
					bbP.xxNN_AltFire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
					bbP.xxClientDemoFix(ST_ProjGold, Class'ShockProj', Start, ST_ProjGold.Velocity, Proj.Acceleration, GV);
					break;
				default:
					ST_ProjBlue = ST_ShockProjBlue(Proj);
					ProjIndex = bbP.xxNN_AddProj(Proj);
					if (ST_ProjBlue != None)
						ST_ProjBlue.zzNN_ProjIndex = ProjIndex;
					bbP.xxNN_AltFire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
					bbP.xxClientDemoFix(ST_ProjBlue, Class'ShockProj', Start, ST_ProjBlue.Velocity, Proj.Acceleration, GV);
					break;
			}
		}
		else
		{
			ST_Proj = ST_ShockProj(Proj);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			if (ST_Proj != None)
				ST_Proj.zzNN_ProjIndex = ProjIndex;
			bbP.xxNN_AltFire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			bbP.xxClientDemoFix(ST_Proj, Class'ShockProj', Start, ST_Proj.Velocity, Proj.Acceleration, GV);
		}
	}
}

simulated function bool ClientAltFire(float Value)
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Level.TimeSeconds - LastFiredTime < 0.4)
			return false;
		if ( AmmoType.AmmoAmount > 0 )
		{
			Instigator = Pawn(Owner);
			GotoState('AltFiring');
			bCanClientFire = true;
			Pawn(Owner).PlayRecoil(FiringSpeed);
			bPointing=True;
			if(bbP != None && bbP.PlayerReplicationInfo != None)
			{
				if(TeamShockEffects)
				{
					Switch(bbP.PlayerReplicationInfo.Team)
					{
						case 0:
							NN_ProjectileFire(Class'ST_ShockProjRed', AltProjectileSpeed, bAltWarnTarget);
							break;
						case 1:
							NN_ProjectileFire(Class'ST_ShockProjBlue', AltProjectileSpeed, bAltWarnTarget);
							break;
						case 2:
							NN_ProjectileFire(Class'ST_ShockProjGreen', AltProjectileSpeed, bAltWarnTarget);
							break;
						case 3:
							NN_ProjectileFire(Class'ST_ShockProjGold', AltProjectileSpeed, bAltWarnTarget);
							break;
						default:
							NN_ProjectileFire(Class'ST_ShockProjBlue', AltProjectileSpeed, bAltWarnTarget);
							break;
					}
				}
				else 
				{
					NN_ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget);	
				}
				LastFiredTime = Level.TimeSeconds;
			}
		}
	}
	return Super.ClientAltFire(Value);
}

function TraceFire( float Accuracy )
{
	local bbPlayer bbP;
	local actor NN_Other;
	local bool bShockCombo;
	local NN_ShockProjOwnerHidden NNSP;
	local NN_ShockProjRedOwnerHidden RNNSP;
	local NN_ShockProjBlueOwnerHidden BNNSP;
	local NN_ShockProjGreenOwnerHidden GNNSP;
	local NN_ShockProjGoldOwnerHidden GoNNSP;
	local vector NN_HitLoc, HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	
	//if (Owner.IsA('Bot'))
	//{
		//Super.TraceFire(Accuracy);
		//return;
	//}

	bbP = bbPlayer(Owner);
	if (bbP == None || !bNewNet)
	{
		Super.TraceFire(Accuracy);
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

		ForEach AllActors(class'NN_ShockProjRedOwnerHidden', RNNSP)
			if (RNNSP.zzNN_ProjIndex == bbP.zzNN_ProjIndex)
				NN_Other = RNNSP;

		ForEach AllActors(class'NN_ShockProjBlueOwnerHidden', BNNSP)
			if (BNNSP.zzNN_ProjIndex == bbP.zzNN_ProjIndex)
				NN_Other = BNNSP;

		ForEach AllActors(class'NN_ShockProjGreenOwnerHidden', GNNSP)
			if (GNNSP.zzNN_ProjIndex == bbP.zzNN_ProjIndex)
				NN_Other = GNNSP;

		ForEach AllActors(class'NN_ShockProjGoldOwnerHidden', GoNNSP)
			if (GoNNSP.zzNN_ProjIndex == bbP.zzNN_ProjIndex)
				NN_Other = GoNNSP;
		
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
	local PlayerPawn PlayerOwner;
	local Pawn PawnOwner;
	
	//if (Owner.IsA('Bot'))
	//{
		//Super.ProcessTraceHit(Other, HitLocation, HitNormal, X, Y, Z);
		//return;
	//}

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

	if ( NN_ShockProjOwnerHidden(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxAddFired(9);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);
		Other.SetOwner(Owner);
		NN_ShockProjOwnerHidden(Other).SuperExplosion();
		return;
	}
	else if ( NN_ShockProjRedOwnerHidden(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxAddFired(9);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);
		Other.SetOwner(Owner);
		NN_ShockProjRedOwnerHidden(Other).SuperExplosion();
		return;
	}
	else if ( NN_ShockProjBlueOwnerHidden(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxAddFired(9);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);
		Other.SetOwner(Owner);
		NN_ShockProjBlueOwnerHidden(Other).SuperExplosion();
		return;
	}
	else if ( NN_ShockProjGreenOwnerHidden(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxAddFired(9);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);
		Other.SetOwner(Owner);
		NN_ShockProjGreenOwnerHidden(Other).SuperExplosion();
		return;
	}
	else if ( NN_ShockProjGoldOwnerHidden(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxAddFired(9);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);
		Other.SetOwner(Owner);
		NN_ShockProjGoldOwnerHidden(Other).SuperExplosion();
		return;
	}
	else if ( ST_ShockProj(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxAddFired(9);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);
		ST_ShockProj(Other).SuperExplosion();
		return;
	}
	else if ( ST_ShockProjRed(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxAddFired(9);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);
		ST_ShockProjRed(Other).SuperExplosion();
		return;
	}
	else if ( ST_ShockProjBlue(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxAddFired(9);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);
		ST_ShockProjBlue(Other).SuperExplosion();
		return;
	}
	else if ( ST_ShockProjGreen(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxAddFired(9);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);
		ST_ShockProjGreen(Other).SuperExplosion();
		return;
	}
	else if ( ST_ShockProjGold(Other)!=None )
	{
		AmmoType.UseAmmo(1);
		if (bbPlayer(Owner) != None)
			bbPlayer(Owner).xxAddFired(9);
		if (STM != None)
			STM.PlayerUnfire(PawnOwner, 5);
		ST_ShockProjGold(Other).SuperExplosion();
		return;
	}
	else if (bNewNet)
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
				DoRingExplosion2(PlayerPawn(Owner), HitLocation, HitNormal);
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
				Spawn(class'UT_RingExplosion2',,, HitLocation+HitNormal*8,rotator(HitNormal));
		}
	}

	if ( (Other != self) && (Other != Owner) && (Other != None) ) 
	{
		if (STM != None)
			STM.PlayerHit(PawnOwner, 5, False);			// 5 = Shock Beam
		Other.TakeDamage(HitDamage, PawnOwner, HitLocation, 60000.0*X, MyDamageType);
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

simulated function DoRingExplosion2(PlayerPawn Pwner, vector HitLocation, vector HitNormal)
{
	local PlayerPawn P;
	local Actor CR;
	
	//if (Owner.IsA('Bot'))
		//return;

	if (RemoteRole < ROLE_Authority) {
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
			if (P != Pwner) {
				CR = P.Spawn(class'UT_RingExplosion2',P,, HitLocation+HitNormal*8,rotator(HitNormal));
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
	local ShockBeam Smoke,shock;
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
	
	if (bNewNet)
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
				Smoke = Spawn(class'NN_ShockBeamOwnerHidden',Owner,,SmokeLocation,SmokeRotation);	
				Smoke.MoveAmount = DVector/NumPoints;
				Smoke.NumPuffs = NumPoints - 1;
			}
		}
	}
	else
	{
		Smoke = Spawn(class'ShockBeam',,,SmokeLocation,SmokeRotation);
		Smoke.MoveAmount = DVector/NumPoints;
		Smoke.NumPuffs = NumPoints - 1;	
	}
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'ShockRifle');
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

simulated function SetTeamSkins()
{
	Class'NNTeamShock'.static.SetTeamSkins( self);
}

defaultproperties
{
	AltProjectileClass=Class'ST_ShockProj'
	bNewNet=True
	FireOffset=(X=10.000000,Y=-7.000000,Z=-9.000000)
	nnWF=Class'NN_WeaponFunctions'
}
