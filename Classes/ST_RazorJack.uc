//=============================================================================
// ST_RazorJack.
//=============================================================================
class ST_RazorJack extends ST_UnrealWeapons;

var bool ClientAnimDone, bFirstFire;

simulated function bool ClientFire(float Value)
{
	local Vector Start, X,Y,Z;
	local Projectile Proj;
	local ST_RB ST_Proj;
	local int ProjIndex;
	local bbPlayer bbP;

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
			
			Proj = Spawn(class'ST_RB', Owner,, Start, AdjustedAim);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			ST_Proj = ST_RB(Proj);
			if (ST_Proj != None)
				ST_Proj.zzNN_ProjIndex = ProjIndex;
			
			bbP.xxNN_Fire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			bbP.xxClientDemoFix(Proj, class'RB', Start, Proj.Velocity, Proj.Acceleration, AdjustedAim);
		}
	}
	return Super.ClientFire(Value);
}

simulated function bool ClientAltFire( float Value )
{
 	local Vector Start, X,Y,Z;
	local Projectile Proj;
	local ST_RBAlt ST_Proj;
	local int ProjIndex;
	local bbPlayer bbP;

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
		
			Proj = Spawn(class'ST_RBAlt', Owner,, Start, AdjustedAim);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			ST_Proj = ST_RBAlt(Proj);
			if (ST_Proj != None)
				ST_Proj.zzNN_ProjIndex = ProjIndex;
			
			bbP.xxNN_AltFire(ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation);
			bbP.xxClientDemoFix(Proj, class'RBAlt', Start, Proj.Velocity, Proj.Acceleration, AdjustedAim);
		}
	}
	return Super.ClientAltFire(Value);
}

function Fire( float Value )
{
	local bbPlayer bbP;
	local NN_RBOwnerHidden r;
	
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
			r = NN_RBOwnerHidden(ProjectileFire(class'NN_RBOwnerHidden', ProjectileSpeed, bWarnTarget));
			r.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
			if (bbP != None)
				r.zzNN_ProjIndex = bbP.xxNN_AddProj(r);
		}
		else
		{
			if ( bRapidFire || (FiringSpeed > 0) )
				Pawn(Owner).PlayRecoil(FiringSpeed);
			ProjectileFire(class'ST_RB', ProjectileSpeed, bWarnTarget);
		}
	}
}

function AltFire( float Value )
{
	local bbPlayer bbP;
	local NN_RBAltOwnerHidden r;
	
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
		if ( Owner.bHidden )
			CheckVisibility();
		GotoState('AltFiring');
		bCanClientFire = true;
		bPointing=True;
		ClientAltFire(Value);
		if (bNewNet)
		{
			r = NN_RBAltOwnerHidden(ProjectileFire(class'NN_RBAltOwnerHidden', AltProjectileSpeed, bAltWarnTarget));
			r.NN_OwnerPing = float(Owner.ConsoleCommand("GETPING"));
			if (bbP != None)
				r.zzNN_ProjIndex = bbP.xxNN_AddProj(r);
		}
		else
		{
			Pawn(Owner).PlayRecoil(FiringSpeed);
			ProjectileFire(class'ST_RBAlt', AltProjectileSpeed, bAltWarnTarget);
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
//////////////////////////////////////////////////////////////////////////

function float SuggestAttackStyle()
{
	return -0.2;
}

function float SuggestDefenseStyle()
{
	return -0.2;
}

simulated function tweentostill();

simulated function PlayFiring()
{
	PlayAnim('Fire', 0.7,0.05);
	PlayOwnedSound(class'RBAlt'.Default.SpawnSound, SLOT_None,4.2);
}

simulated function PlayAltFiring()
{
	PlayAnim('Fire', 0.5,0.05);
	PlayOwnedSound(class'RB'.Default.SpawnSound, SLOT_None,4.2);
	bFirstFire = true;
}
/* 
simulated function PlayRepeatFiring()
{
	PlayAnim('AltFire2', 0.4,0.05);
}
 */
simulated function PlayIdleAnim()
{
	if ( Mesh != PickupViewMesh )
		LoopAnim('Idle', 0.4);
}

state AltFiring
{
	//ignores animend;

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
	function bool SplashJump()
	{
		return true;
	}
/* 
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
		AdjustedAim.Roll += 12768;
		return Spawn(ProjClass,Owner,, Start,AdjustedAim);
	}

Begin:
	FinishAnim();
Repeater:
	ProjectileFire(AltProjectileClass,AltProjectileSpeed,bAltWarnTarget);
	PlayRepeatFiring();
	FinishAnim();
	if ( PlayerPawn(Owner) == None )
	{
		if ( (AmmoType != None) && (AmmoType.AmmoAmount<=0) )
		{
			Pawn(Owner).StopFiring();
			Pawn(Owner).SwitchToBestWeapon();
			if ( bChangeWeapon )
				GotoState('DownWeapon');
		}
		else if ( (Pawn(Owner).bAltFire == 0) || (FRand() > AltRefireRate) )
		{
			Pawn(Owner).StopFiring();
			GotoState('Idle');
		}
	}
	if ( (Pawn(Owner).bAltFire!=0) && (Pawn(Owner).Weapon==Self) && AmmoType.UseAmmo(1))
	{
		goto 'Repeater';
	}
	PlayAnim('AltFire3', 0.9,0.05);
	FinishAnim();
	PlayAnim('Load',0.2,0.05);  
	FinishAnim();  
	if ( Pawn(Owner).bFire!=0 && Pawn(Owner).Weapon==Self) 
		Global.Fire(0);
	else 
		GotoState('Idle');
 */
}
/* 
state ClientAltFiring
{
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || ((AmmoType != None) && (AmmoType.AmmoAmount <= 0)) )
		{
			if (!ClientAnimDone)
			{
				PlayAnim('AltFire3', 0.9,0.05);
				ClientAnimDone=true;
			}
			else
			{
				PlayAnim('Load',0.2,0.05);
				ClientAnimDone=False;
				GotoState('');
			}
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner).bFire != 0 )
		{
			if (!ClientAnimDone)
			{
				PlayAnim('AltFire3', 0.9,0.05);
				ClientAnimDone=true;
			}
			else
			{
				PlayAnim('Load',0.2,0.05);
				ClientAnimDone=False;
				Global.ClientFire(0);
			}
		}
		else if (bFirstFire || Pawn(Owner).bAltFire != 0 )
		{
			PlayRepeatFiring();
			bFirstFire = false;
		}
		else
		{
			if (!ClientAnimDone)
			{
				PlayAnim('AltFire3', 0.9,0.05);
				ClientAnimDone=true;
			}
			else
			{
				PlayAnim('Load',0.2,0.05);
				ClientAnimDone=False;
				GotoState('');
			}
		}
	}
}
 */
//////////////////////////////////////////////////////////////////////////

defaultproperties
{
    WeaponDescription="Classification: Skaarj Blade Launcher\n\nPrimary Fire: Single blades that richochet off walls, ceilings, and floors.\n\nSecondary Fire: Skilled users can make use of the weapons transmitted motion singles, allowing the user to alter the trajectory of the blade after it leaves the weapon.\n\nTechniques: Aim for the necks of your opponents."
	AmmoName=Class'ST_RazorAmmo'
    ProjectileClass=Class'RB'
    AltProjectileClass=Class'RBAlt'
    PickupAmmoCount=15
    FireOffset=(X=16.00,Y=-11.50,Z=-15.00),
    shakemag=120.00
    AIRating=0.50
    RefireRate=0.83
    AltRefireRate=0.83
    SelectSound=Sound'UnrealI.Razorjack.beam'
    DeathMessage="%k took a bloody chunk out of %o with the %w."
    AutoSwitchPriority=6
    InventoryGroup=6
    PickupMessage="You got the Razor Jack"
    ItemName="Razor Jack"
    PlayerViewOffset=(X=2.00,Y=-1.00,Z=-0.70),
    PlayerViewMesh=LodMesh'UnrealI.Razor'
    PickupViewMesh=LodMesh'UnrealI.RazPick'
    ThirdPersonMesh=LodMesh'UnrealI.Razor3rd'
    StatusIcon=Texture'UseRJ'
    Icon=Texture'UseRJ'
    Mesh=LodMesh'UnrealI.RazPick'
    CollisionRadius=28.00
    CollisionHeight=7.00
    Mass=17.00
}