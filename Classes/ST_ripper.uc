// ===============================================================
// UTPureStats7A.ST_ripper: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_ripper extends ripper;

var bool bNewNet;				// Self-explanatory lol
var Rotator GV;
var Vector CDO;
var float yMod;

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
	local Vector Start, X,Y,Z;
	local Projectile Proj;
	local ST_Razor2 ST_Proj;
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
			Instigator = Pawn(Owner);
			GotoState('ClientFiring');
			bPointing=True;
			bCanClientFire = true;
			
			yModInit();

			GetAxes(GV,X,Y,Z);
			Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
			AdjustedAim = pawn(owner).AdjustAim(ProjectileSpeed, Start, AimError, True, bWarnTarget);	
			
			Proj = Spawn(class'ST_Razor2', Owner,, Start, AdjustedAim);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			ST_Proj = ST_Razor2(Proj);
			if (ST_Proj != None)
				ST_Proj.zzNN_ProjIndex = ProjIndex;
			
			bbP.xxNN_Fire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			bbP.xxClientDemoFix(Proj, class'Razor2', Start, Proj.Velocity, Proj.Acceleration, AdjustedAim);
		}
	}
	return Super.ClientFire(Value);
}

simulated function bool ClientAltFire( float Value )
{
	local Vector Start, X,Y,Z;
	local Projectile Proj;
	local ST_Razor2Alt ST_Proj;
	local int ProjIndex;
	local bbPlayer bbP;
	
	if (Owner.IsA('Bot'))
		return Super.ClientAltFire(Value);
	
	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self)
			return false;
		if ( AmmoType == None )
		{
			GiveAmmo(Pawn(Owner));
		}
		if (AmmoType.AmmoAmount > 0)
		{
			yModInit();

			Instigator = Pawn(Owner);
			GotoState('AltFiring');
			bCanClientFire = true;
			bPointing=True;
			Pawn(Owner).PlayRecoil(FiringSpeed);
			
			GetAxes(GV,X,Y,Z);
			Start = Owner.Location + CDO + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
			AdjustedAim = pawn(owner).AdjustAim(AltProjectileSpeed, Start, AimError, True, bAltWarnTarget);	
		
			Proj = Spawn(class'ST_Razor2Alt', Owner,, Start, AdjustedAim);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			ST_Proj = ST_Razor2Alt(Proj);
			if (ST_Proj != None)
				ST_Proj.zzNN_ProjIndex = ProjIndex;
			
			bbP.xxNN_AltFire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			bbP.xxClientDemoFix(Proj, class'Razor2Alt', Start, Proj.Velocity, Proj.Acceleration, AdjustedAim);
		}
	}
	return Super.ClientAltFire(Value);
}

function Fire( float Value )
{
	local bbPlayer bbP;
	local NN_Razor2OwnerHidden r;
	
	if (Owner.IsA('Bot'))
	{
		Super.Fire(Value);
		return;
	}
	
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
		if ( bInstantHit )
			TraceFire(0.0);
		else if (bNewNet)
		{
			r = NN_Razor2OwnerHidden(ProjectileFire(class'NN_Razor2OwnerHidden', ProjectileSpeed, bWarnTarget));
			r.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
			if (bbP != None)
				r.zzNN_ProjIndex = bbP.xxNN_AddProj(r);
		}
		else
		{
			if ( bRapidFire || (FiringSpeed > 0) )
				Pawn(Owner).PlayRecoil(FiringSpeed);
			ProjectileFire(class'ST_Razor2', ProjectileSpeed, bWarnTarget);
		}
	}
}

function AltFire( float Value )
{
	local bbPlayer bbP;
	local NN_Razor2AltOwnerHidden r;
	
	if (Owner.IsA('Bot'))
	{
		Super.AltFire(Value);
		return;
	}
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;

	if ( AmmoType == None )
	{
		GiveAmmo(Pawn(Owner));
	}
	if (AmmoType.UseAmmo(1))
	{
		GotoState('AltFiring');
		bCanClientFire = true;
		bPointing=True;
		ClientAltFire(Value);
		if (bNewNet)
		{
			r = NN_Razor2AltOwnerHidden(ProjectileFire(class'NN_Razor2AltOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
			r.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
			if (bbP != None)
				r.zzNN_ProjIndex = bbP.xxNN_AddProj(r);
		}
		else
		{
			Pawn(Owner).PlayRecoil(FiringSpeed);
			ProjectileFire(class'ST_Razor2Alt', AltProjectileSpeed, bAltWarnTarget);
		}
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
	AdjustedAim = pawn(owner).AdjustAim(ProjSpeed, Start, AimError, True, bWarn);	
	return Spawn(ProjClass,Owner,, Start,AdjustedAim);	
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

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'ripper');
}

simulated function PlaySelect ()
{
	Class'NN_WeaponFunctions'.static.PlaySelect( self);
}

simulated function TweenDown ()
{
	Class'NN_WeaponFunctions'.static.TweenDown( self);
}

simulated function AnimEnd ()
{
	Class'NN_WeaponFunctions'.static.AnimEnd( self);
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

simulated function PlayFiring()
{
	PlayAnim( 'Fire', 0.7 + 0.6 * FireAdjust, 0.05 );
	PlayOwnedSound(class'Razor2'.Default.SpawnSound, SLOT_None,4.2);
}

simulated function PlayAltFiring()
{
	PlayAnim('Fire', 0.4 + 0.3 * FireAdjust,0.05);
	PlayOwnedSound(class'Razor2Alt'.Default.SpawnSound, SLOT_None,4.2);
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
}