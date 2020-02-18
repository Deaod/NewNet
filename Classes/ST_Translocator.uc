// ===============================================================
// Stats.ST_Translocator: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_Translocator extends Translocator;

// Right handed version
#exec MESH  IMPORT MESH=TranslocatorR ANIVFILE=MODELS\Translocator_a.3D DATAFILE=MODELS\Translocator_d.3D UNMIRROR=1
#exec MESH ORIGIN MESH=TranslocatorR X=0 Y=0 Z=0 YAW=-64 PITCH=0 ROLL=-5
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=All	 	 STARTFRAME=0  NUMFRAMES=110
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=Throw     STARTFRAME=32 NUMFRAMES=19
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=PreReset  STARTFRAME=46 NUMFRAMES=5
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=Idle      STARTFRAME=51 NUMFRAMES=2 RATE=3
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=Still     STARTFRAME=51 NUMFRAMES=2 RATE=3
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=Down 	 STARTFRAME=66 NUMFRAMES=7
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=Select	 STARTFRAME=18 NUMFRAMES=12
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=Thrown	 STARTFRAME=53 NUMFRAMES=12
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=ThrownFrame	STARTFRAME=52 NUMFRAMES=1
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=Down2 	STARTFRAME=77 NUMFRAMES=7
#exec MESH SEQUENCE MESH=TranslocatorR SEQ=Idle2	STARTFRAME=88 NUMFRAMES=19

#exec MESHMAP SCALE MESHMAP=TranslocatorR X=0.0065 Y=0.0045 Z=0.011
#exec MESHMAP SETTEXTURE MESHMAP=TranslocatorR NUM=0 TEXTURE=tloc1
#exec MESHMAP SETTEXTURE MESHMAP=TranslocatorR NUM=1 TEXTURE=tloc2
#exec MESHMAP SETTEXTURE MESHMAP=TranslocatorR NUM=2 TEXTURE=tloc3
#exec MESHMAP SETTEXTURE MESHMAP=TranslocatorR NUM=3 TEXTURE=tloc4

var bool bNewNet;		// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;
var bool bClientTTargetOut, bPlayTeleportEffect;
var NN_TranslocatorTarget zzClientTTarget;
var() mesh PlayerViewMeshL;

function setHand(float Hand)
{
	Super(TournamentWeapon).SetHand(Hand);
	if (Hand == 1)
		Mesh = PlayerViewMeshL;
	else
		Mesh = PlayerViewMesh;
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
		//else if (bbP.bAltFire != 0 && !IsInState('ClientAltFiring'))
		//	ClientAltFire(1);
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
		
		if (  zzClientTTarget == None )
		{
			if ( Level.TimeSeconds - 0.5 > FireDelay )
			{
				bPointing=True;
				bCanClientFire = true;
				Pawn(Owner).PlayRecoil(FiringSpeed);
				ClientThrowTarget();
				PlayFiring();
				FireDelay = Level.TimeSeconds + 0.1;

				bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			}
		}
		else if ( zzClientTTarget.SpawnTime < Level.TimeSeconds - 0.8 )
		{
			if ( zzClientTTarget.Disrupted() )
			{
				Pawn(Owner).PlaySound(sound'TDisrupt', SLOT_None, 4.0);
				Pawn(Owner).PlaySound(sound'TDisrupt', SLOT_Misc, 4.0);
				Pawn(Owner).PlaySound(sound'TDisrupt', SLOT_Interact, 4.0);
				Pawn(Owner).gibbedBy(zzClientTTarget.disruptor);
			}
			else
			{
				Owner.PlaySound(AltFireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
				bClientTTargetOut = false;
				zzClientTTarget.Destroy();
				zzClientTTarget = None;
				FireDelay = Level.TimeSeconds;
				TweenAnim('ThrownFrame', 0.27);
			}
			
			bbP.xxNN_Fire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
		}

		GotoState('ClientFiring');
	}
	
	return Super.ClientFire(Value);
}
/*
simulated function ClientSpawnEffect(vector Start, vector Dest)
{
	local actor e;

	e = Spawn(class'TranslocOutEffect',,,start, Owner.Rotation);
	e.Mesh = Owner.Mesh;
	e.Animframe = Owner.Animframe;
	e.Animsequence = Owner.Animsequence;
	e.Velocity = 900 * Normal(Dest - Start);
}
*/
simulated function ClientTranslocate()
{
	local vector Dest, Start;
	local Bot B;
	local Pawn P;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return;
	
	bbP = bbPlayer(Owner);
	
	if (zzClientTTarget == None || bbP == none)
		return;
	
	bBotMoveFire = false;
	PlayAnim('Thrown', 1.2,0.1);
	Dest = zzClientTTarget.Location;
	if ( zzClientTTarget.Physics == PHYS_None )
		Dest += vect(0,0,40);

	Start = Pawn(Owner).Location;
	zzClientTTarget.SetCollision(false,false,false);
	if ( Pawn(Owner).SetLocation(Dest) )
	{
		if ( !Owner.Region.Zone.bWaterZone )
			Owner.SetPhysics(PHYS_Falling);
		if ( zzClientTTarget.Disrupted() )
		{
			//ClientSpawnEffect(Start, Dest);
			Pawn(Owner).gibbedBy(zzClientTTarget.disruptor);
			return;
		}

		if ( !FastTrace(Pawn(Owner).Location, zzClientTTarget.Location) )
		{
			Pawn(Owner).SetLocation(Start);
			Owner.PlaySound(AltFireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
		}	
		else 
		{ 
			Owner.Velocity.X = 0;
			Owner.Velocity.Y = 0;
			B = Bot(Owner);
			if ( B == None )
			{
				// bots must re-acquire this player
				for ( P=Level.PawnList; P!=None; P=P.NextPawn )
					if ( (P.Enemy == Owner) && P.IsA('Bot') )
						Bot(P).LastAcquireTime = Level.TimeSeconds;
			}
			
			foreach VisibleCollidingActors( class 'Pawn', P, bbP.CollisionRadius * bbP.TeleRadius / 100, bbP.Location )
				if ( P != bbP && (!bbP.GameReplicationInfo.bTeamGame || bbP.PlayerReplicationInfo.Team != P.PlayerReplicationInfo.Team) && ((VSize(P.Location - bbP.Location)) < ((P.CollisionRadius + bbP.CollisionRadius) * bbP.CollisionHeight)) )
					bbP.xxNN_TransFrag(P);
			
			//ClientSpawnEffect(Start, Dest);
		}
	}
	else 
	{
		Owner.PlaySound(AltFireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
	}

	if ( zzClientTTarget != None )
	{
		bClientTTargetOut = false;
		zzClientTTarget.Destroy();
		zzClientTTarget = None;
	}
	bPointing=True;
}

simulated function ClientThrowTarget()
{
	local Vector Start, X,Y,Z;
	
	if (Owner.IsA('Bot'))
		return;
	
	if (bbPlayer(Owner) == None)
		return;
	
	yModInit();

	if ( Owner.IsA('Bot') )
		bBotMoveFire = true;
	Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 		
	GV = Pawn(Owner).AdjustToss(TossForce, Start, 0, true, true); 
	GetAxes(GV,X,Y,Z);
	zzClientTTarget = Spawn(class'NN_TranslocatorTarget',Owner,, Start);
	bbPlayer(Owner).zzClientTTarget = zzClientTTarget;
	if (zzClientTTarget!=None)
	{
		bClientTTargetOut = true;
		zzClientTTarget.Master = self;
		if ( Owner.IsA('Bot') )
			zzClientTTarget.SetCollisionSize(0,0); 
		zzClientTTarget.Throw(Pawn(Owner), MaxTossForce, Start);
	}
	else GotoState('Idle');
    bbPlayer(Owner).xxClientDemoFix(zzClientTTarget, Class'TranslocatorTarget', Start, zzClientTTarget.Velocity, zzClientTTarget.Acceleration, zzClientTTarget.Rotation);
}

simulated function bool ClientAltFire( float Value )
{
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false;
		
		GotoState('ClientFiring');
		if ( zzClientTTarget != None )
		{
			yModInit();
			
			Instigator = Pawn(Owner);
			ClientTranslocate();
		}
		bbP.xxNN_AltFire(-1, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
	}
		
	return Super.ClientAltFire(Value);
}

function ThrowTarget()
{
	local Vector Start, X,Y,Z;	
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
	{
		Super.ThrowTarget();
		return;
	}
	
	yModInit();
	
	bbP = bbPlayer(Owner);

	if (Level.Game.LocalLog != None)
		Level.Game.LocalLog.LogSpecialEvent("throw_translocator", Pawn(Owner).PlayerReplicationInfo.PlayerID);
	if (Level.Game.WorldLog != None)
		Level.Game.WorldLog.LogSpecialEvent("throw_translocator", Pawn(Owner).PlayerReplicationInfo.PlayerID);

	if ( Owner.IsA('Bot') )
		bBotMoveFire = true;
	if (bbP == None || !bNewNet)
	{
		Pawn(Owner).ViewRotation = Pawn(Owner).AdjustToss(TossForce, Start, 0, true, true); 
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
	if (bbP != None && bNewNet)
	{
		TTarget = Spawn(class'NN_TranslocatorTargetOwnerHidden',Owner,, Start);
		bbP.TTarget = TTarget;
	}
	else
		TTarget = Spawn(class'TranslocatorTarget',,, Start);
	if (TTarget!=None)
	{
		bTTargetOut = true;
		TTarget.Master = self;
		if ( Owner.IsA('Bot') )
			TTarget.SetCollisionSize(0,0); 
		TTarget.Throw(Pawn(Owner), MaxTossForce, Start);
	}
	else GotoState('Idle');
}

function Fire( float Value )
{
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	if ( bBotMoveFire )
		return;
	if ( TTarget == None )
	{
		if ( bNewNet && Value > 0 || !bNewNet && ((Level.TimeSeconds - 0.5) > FireDelay) )
		{
			bPointing=True;
			bCanClientFire = true;
			ClientFire(value);
			if (!bNewNet)
				Pawn(Owner).PlayRecoil(FiringSpeed);
			ThrowTarget();
			FireDelay = Level.TimeSeconds + 0.1;
		}
	}
	else if ( (bNewNet && Value > 0 || !bNewNet) && (TTarget.SpawnTime < (Level.TimeSeconds - 0.8)) )
	{
		if ( TTarget.Disrupted() )
		{
			if (Level.Game.LocalLog != None)
				Level.Game.LocalLog.LogSpecialEvent("translocate_gib", Pawn(Owner).PlayerReplicationInfo.PlayerID);
			if (Level.Game.WorldLog != None)
				Level.Game.WorldLog.LogSpecialEvent("translocate_gib", Pawn(Owner).PlayerReplicationInfo.PlayerID);

			Pawn(Owner).PlaySound(sound'TDisrupt', SLOT_None, 4.0);
			Pawn(Owner).PlaySound(sound'TDisrupt', SLOT_Misc, 4.0);
			Pawn(Owner).PlaySound(sound'TDisrupt', SLOT_Interact, 4.0);
			Pawn(Owner).gibbedBy(TTarget.disruptor);
			return;
		}
		if (!bNewNet)
			Owner.PlaySound(AltFireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
		bTTargetOut = false;
		TTarget.Destroy();
		TTarget = None;
		FireDelay = Level.TimeSeconds;
	}

	GotoState('NormalFire');
}

function Translocate()
{
	local vector Dest, Start;
	local Bot B;
	local Pawn P;
	local bbPlayer bbP;
	local bool bSuccess;
	
	if (Owner.IsA('Bot'))
	{
		Super.Translocate();
		return;
	}

	bBotMoveFire = false;
	PlayAnim('Thrown', 1.2, 0.1);
	Dest = TTarget.Location;
	if ( TTarget.Physics == PHYS_None )
		Dest += vect(0,0,40);
		
	if ( Level.Game.IsA('DeathMatchPlus') 
		&& !DeathMatchPlus(Level.Game).AllowTranslocation(Pawn(Owner), Dest) )
		return;

	Start = Pawn(Owner).Location;
	TTarget.SetCollision(false,false,false);
	
	bbP = bbPlayer(Owner);
	if ( bNewNet && bbP != None )
		bSuccess = bbP.xxNewSetLocation(bbP.zzNN_ClientLoc, bbP.zzNN_ClientVel, PHYS_Falling) && VSize(Start - bbP.zzNN_ClientLoc) > 20;
	else
		bSuccess = Pawn(Owner).SetLocation(Dest);
	
	if (bSuccess)
	{
		if ( !Owner.Region.Zone.bWaterZone )
			Owner.SetPhysics(PHYS_Falling);
		if ( TTarget.Disrupted() )
		{
			if (Level.Game.LocalLog != None)
				Level.Game.LocalLog.LogSpecialEvent("translocate_gib", Pawn(Owner).PlayerReplicationInfo.PlayerID);
			if (Level.Game.WorldLog != None)
				Level.Game.WorldLog.LogSpecialEvent("translocate_gib", Pawn(Owner).PlayerReplicationInfo.PlayerID);

			SpawnEffect(Start, Dest);
			Pawn(Owner).gibbedBy(TTarget.disruptor);
			return;
		}

		if ( !FastTrace(Pawn(Owner).Location, TTarget.Location) )
		{
			if (Level.Game.LocalLog != None)
				Level.Game.LocalLog.LogSpecialEvent("translocate_fail", Pawn(Owner).PlayerReplicationInfo.PlayerID);
			if (Level.Game.WorldLog != None)
				Level.Game.WorldLog.LogSpecialEvent("translocate_fail", Pawn(Owner).PlayerReplicationInfo.PlayerID);

			Pawn(Owner).SetLocation(Start);
			Owner.PlaySound(AltFireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
		}	
		else 
		{ 
			if (Level.Game.LocalLog != None)
				Level.Game.LocalLog.LogSpecialEvent("translocate", Pawn(Owner).PlayerReplicationInfo.PlayerID);
			if (Level.Game.WorldLog != None)
				Level.Game.WorldLog.LogSpecialEvent("translocate", Pawn(Owner).PlayerReplicationInfo.PlayerID);
			
			Owner.Velocity.X = 0;
			Owner.Velocity.Y = 0;
			
			if (bbP != None && bNewNet && bPlayTeleportEffect)
				bbP.PlayTeleportEffect(true, true);
			
			B = Bot(Owner);
			if ( B != None )
			{
				if ( TTarget.DesiredTarget.IsA('NavigationPoint') )
					B.MoveTarget = TTarget.DesiredTarget;
				B.bJumpOffPawn = true;
				if ( !Owner.Region.Zone.bWaterZone )
					B.SetFall();
			}
			else
			{
				// bots must re-acquire this player
				for ( P=Level.PawnList; P!=None; P=P.NextPawn )
					if ( (P.Enemy == Owner) && P.IsA('Bot') )
						Bot(P).LastAcquireTime = Level.TimeSeconds;
			}
			
			SpawnEffect(Start, Dest);
		}
	} 
	else 
	{
		Owner.PlaySound(AltFireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
		if (Level.Game.LocalLog != None)
			Level.Game.LocalLog.LogSpecialEvent("translocate_fail", Pawn(Owner).PlayerReplicationInfo.PlayerID);
		if (Level.Game.WorldLog != None)
			Level.Game.WorldLog.LogSpecialEvent("translocate_fail", Pawn(Owner).PlayerReplicationInfo.PlayerID);
	}

	if ( TTarget != None )
	{
		bTTargetOut = false;
		TTarget.Destroy();
		TTarget = None;
	}
	bPointing=True;
}

simulated function PlayIdleAnim()
{
	if (Owner.IsA('Bot'))
	{
		Super.PlayIdleAnim();
		return;
	}
	if ( Mesh == PickupViewMesh )
		return;
	if (bNewNet) {
		if ( bClientTTargetOut )
			LoopAnim('Idle', 0.4);
		else  
			LoopAnim('Idle2',0.2,0.1);
	} else {
		if ( bTTargetOut )
			LoopAnim('Idle', 0.4);
		else  
			LoopAnim('Idle2',0.2,0.1);
	}
	Enable('AnimEnd');
}

state NormalFire
{
	ignores AnimEnd;

	simulated function bool PutDown()
	{
		if (Owner.IsA('Bot'))
			return Super.PutDown();
		GotoState('DownWeapon');
		return True;
	}
	
	function Fire( float F )
	{
		if (Owner.IsA('Bot'))
		{
			Super.Fire(F);
			return;
		}
		if (F > 0 && bbPlayer(Owner) != None)
			Global.Fire(F);
	}
	
	function AltFire( float F )
	{
		if (Owner.IsA('Bot'))
		{
			Super.AltFire(F);
			return;
		}
		if (F > 0 && bbPlayer(Owner) != None)
			Global.AltFire(F);
	}

Begin:
	if ( Owner.IsA('Bot') )
		Bot(Owner).SwitchToBestWeapon();
	Sleep(0.1);
	if ( (Pawn(Owner).bFire != 0) && (Pawn(Owner).bAltFire != 0) && bbPlayer(Owner) != None && !bbPlayer(Owner).bNoRevert )
	 	ReturnToPreviousWeapon();
	GotoState('Idle');
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

state ClientFiring
{
	simulated function bool ClientFire(float Value)
	{
		if (Owner.IsA('Bot'))
			return Super.ClientFire(Value);
		if (bNewNet && Role < ROLE_Authority)
			return Global.ClientFire(Value);
		else
			return false;
	}

	simulated function bool ClientAltFire(float Value)
	{
		if (Owner.IsA('Bot'))
			return Super.ClientAltFire(Value);
		if (bNewNet && Role < ROLE_Authority)
			return Global.ClientAltFire(Value);
		else
			return false;
	}
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'Translocator');
}

simulated function AnimEnd ()
{
	Class'NN_WeaponFunctions'.static.AnimEnd( self);
}

simulated function PlaySelect ()
{
	local float PScale;

	Class'NN_WeaponFunctions'.static.PlaySelect( self);
	PScale = Pawn(Owner).PlayerReplicationInfo.Ping;
	PScale = FMax(PScale,1.0);
	PScale /= 1000;
	bForceFire = false;
	bForceAltFire = false;
	Owner.PlaySound(SelectSound, SLOT_Misc, Pawn(Owner).SoundDampening);	
	if (bNewNet && !Owner.IsA('Bot')) {
		if ( bClientTTargetOut )
			TweenAnim('ThrownFrame', 0.27);
		else
			PlayAnim('Select',1.5 + PScale,0.00);
	} else {
		if ( bTTargetOut )
			TweenAnim('ThrownFrame', 0.27);
		else
			PlayAnim('Select',1.5 + PScale,0.00);
	}		
}

simulated function TweenDown()
{
	if (Owner.IsA('Bot'))
	{
		Super.TweenDown();
		return;
	}
	if ( IsAnimating() && (AnimSequence != '') && (GetAnimGroup(AnimSequence) == 'Select') )
		TweenAnim( AnimSequence, AnimFrame * 0.36 );
	else if (bNewNet)
	{
		if ( bClientTTargetOut ) PlayAnim('Down2', 1.1, 0.05);
		else PlayAnim('Down', 1.5 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000, 0.05);
	}
	else
	{
		if ( bTTargetOut ) PlayAnim('Down2', 1.1, 0.05);
		else PlayAnim('Down', 1.5 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000, 0.05);
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

auto state Pickup
{
	ignores AnimEnd;
	
	simulated function Landed(Vector HitNormal)
	{
		Super(Inventory).Landed(HitNormal);
	}
}

defaultproperties
{
     bNewNet=True
     bPlayTeleportEffect=True
	 PlayerViewMeshL=Transloc
	 PlayerViewMesh=TranslocatorR
}
