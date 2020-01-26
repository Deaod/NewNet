// ===============================================================
// Stats.ST_SniperRifle: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_SniperRifle extends SniperRifle;

var zp_Interface zzS;
var zp_Interface zzC;
var bool zp_Enabled;
var float SniperSpeed;

replication
{
	reliable if ( Role < 4 )
		xx_;
	reliable if ( Role == 4 )
		rSetOffset;
}

simulated event Spawned ()
{
	if ( zzC == None )
	{
		zzC=Spawn(Class'zp_Client');
		zzC.GotoState('zp_Gun');
		zzC.zzW=self;
	}
}

simulated event Destroyed ()
{
	if ( zzC != None )
	{
		zzC.Destroy();
	}
	if ( zzS != None )
	{
		zzS.Destroy();
	}
	Super.Destroyed();
}

function SetHand (float hand)
{
	Super.SetHand(hand);
	rSetOffset(FireOffset.Y);
}

simulated function rSetOffset (float Y)
{
	if ( (Owner != None) && Owner.IsA('PlayerPawn') )
	{
		zzC.AdjustKeyBindings(PlayerPawn(Owner));
	}
	FireOffset.Y=Y;
}

function Fire (float V)
{
	if ( zzS.HasZPDisabled() )
	{
		Super.Fire(V);
	}
}

simulated function bool ClientFire (float V)
{
	if ( zzC.HasZPDisabled() )
	{
		return Super.ClientFire(V);
	}
	zzC.xxFire(V);
	return False;
}

function SetSwitchPriority (Pawn Other)
{
	zzS.SetSwitchPriority(Other);
}

state Idle
{
	function Fire (float Value)
	{
		Global.Fire(Value);
	}
	
}

function xx_ (int zzId, float zzTime, bool zzHeadShot)
{
	local Vector zzMomentum;
	local Vector zzHitLocation;
	local Actor zzVictim;

	zzS.xxServerFire(zzId,zzTime,zzHitLocation,zzVictim);
	if ( zzVictim == None )
	{
		return;
	}
	zzMomentum=Normal(zzHitLocation - Owner.Location);
	if ( zzHeadShot )
	{
		zzHitLocation=zzVictim.Location;
		zzHitLocation.Z += 0.70 * zzVictim.CollisionHeight;
		zzVictim.TakeDamage(100,Pawn(Owner),zzHitLocation,35000 * zzMomentum,AltDamageType);
	}
	else
	{
		zzVictim.TakeDamage(45,Pawn(Owner),zzHitLocation,30000 * zzMomentum,MyDamageType);
	}
}

simulated function PlaySelect()
{
	bForceFire = false;
	bForceAltFire = false;
	bCanClientFire = false;
	if ( !IsAnimating() || (AnimSequence != 'Select') )
		PlayAnim('Select',1.35 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000,0.0);
	Owner.PlaySound(SelectSound, SLOT_Misc, Pawn(Owner).SoundDampening);
}

simulated function TweenDown()
{
	if ( IsAnimating() && (AnimSequence != '') && (GetAnimGroup(AnimSequence) == 'Select') )
		TweenAnim( AnimSequence, AnimFrame * 0.4 );
	else
		PlayAnim('Down', 1.35 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000, 0.05);
}

simulated function PlayFiring()
{
	local int r;

	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*3.0);
	if (SniperSpeed > 0)
		PlayAnim(FireAnims[Rand(5)], 0.5 * SniperSpeed + 0.5 * FireAdjust, 0.05);
	else
		PlayAnim(FireAnims[Rand(5)], 0.5 * class'UTPure'.default.SniperSpeed + 0.5 * FireAdjust, 0.05);

	if ( (PlayerPawn(Owner) != None) 
		&& (PlayerPawn(Owner).DesiredFOV == PlayerPawn(Owner).DefaultFOV) )
		bMuzzleFlash++;
}

defaultproperties
{
	zp_Enabled=True
}
