//=============================================================================
// asPulseGun.
//=============================================================================
class asPulseGun extends TournamentWeapon;

var float Angle, Count;
var PBolt PlasmaBeam;
var() sound DownSound;

simulated event RenderOverlays( canvas Canvas )
{
	Texture'Ammoled'.NotifyActor = Self;
	Super.RenderOverlays(Canvas);
	Texture'Ammoled'.NotifyActor = None;
}

simulated function Destroyed()
{
	if ( PlasmaBeam != None )
		PlasmaBeam.Destroy();

	Super.Destroyed();
}

simulated function AnimEnd()
{
	if ( (Level.NetMode == NM_Client) && (Mesh != PickupViewMesh) )
	{
		if ( AnimSequence == 'SpinDown' )
			AnimSequence = 'Idle';
		PlayIdleAnim();
	}
}
// set which hand is holding weapon
function setHand(float Hand)
{
	if ( Hand == 2 )
	{
		FireOffset.Y = 0;
		bHideWeapon = true;
		if ( PlasmaBeam != None )
			PlasmaBeam.bCenter = true;
		return;
	}
	else
		bHideWeapon = false;
	PlayerViewOffset = Default.PlayerViewOffset * 100;
	if ( Hand == 1 )
	{
		if ( PlasmaBeam != None )
		{
			PlasmaBeam.bCenter = false;
			PlasmaBeam.bRight = false;
		}
		FireOffset.Y = Default.FireOffset.Y;
		Mesh = mesh(DynamicLoadObject("Botpack.PulseGunL", class'Mesh'));
	}
	else
	{
		if ( PlasmaBeam != None )
		{
			PlasmaBeam.bCenter = false;
			PlasmaBeam.bRight = true;
		}
		FireOffset.Y = -1 * Default.FireOffset.Y;
		Mesh = mesh'PulseGunR';
	}
}

// return delta to combat style
function float SuggestAttackStyle()
{
	local float EnemyDist;

	EnemyDist = VSize(Pawn(Owner).Enemy.Location - Owner.Location);
	if ( EnemyDist < 1000 )
		return 0.4;
	else
		return 0;
}

function float RateSelf( out int bUseAltMode )
{
	local Pawn P;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;

	P = Pawn(Owner);
	if ( (P.Enemy == None) || (Owner.IsA('Bot') && Bot(Owner).bQuickFire) )
	{
		bUseAltMode = 0;
		return AIRating;
	}

	if ( P.Enemy.IsA('StationaryPawn') )
	{
		bUseAltMode = 0;
		return (AIRating + 0.4);
	}
	else
		bUseAltMode = int( 700 > VSize(P.Enemy.Location - Owner.Location) );

	AIRating *= FMin(Pawn(Owner).DamageScaling, 1.5);
	return AIRating;
}

simulated function PlayFiring()
{
	FlashCount++;
	AmbientSound = FireSound;
	SoundVolume = Pawn(Owner).SoundDampening*255;
	PlayAnim( 'shootLOOP', 1 + 0.5 * FireAdjust, 0.0);
	bWarnTarget = (FRand() < 0.2);
}

simulated function PlayAltFiring()
{
	
	AmbientSound = AltFireSound;
	if ( (AnimSequence == 'BoltLoop') || (AnimSequence == 'BoltStart') )		
		PlayAnim( 'boltloop');
	else
		PlayAnim( 'boltstart' );
}

function AltFire( float Value )
{
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if (AmmoType.UseAmmo(1))
	{
		GotoState('AltFiring');
		bCanClientFire = true;
		bPointing=True;
		Pawn(Owner).PlayRecoil(FiringSpeed);
		ClientAltFire(value);
		if ( PlasmaBeam == None )
		{
			PlasmaBeam = PBolt(ProjectileFire(AltProjectileClass, AltProjectileSpeed, bAltWarnTarget));
			if ( FireOffset.Y == 0 )
				PlasmaBeam.bCenter = true;
			else if ( Mesh == mesh'PulseGunR' )
				PlasmaBeam.bRight = false;
		}
	}
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	local Color C;
	local string Temp;
	
	Temp = String(AmmoType.AmmoAmount);

	while(Len(Temp) < 3) Temp = "0"$Temp;

	Tex.DrawTile( 30, 100, (Min(AmmoType.AmmoAmount,AmmoType.Default.AmmoAmount)*196)/AmmoType.Default.AmmoAmount, 10, 0, 0, 1, 1, Texture'AmmoCountBar', False );

	if(AmmoType.AmmoAmount < 10)
	{
		C.R = 255;
		C.G = 0;
		C.B = 0;	
	}
	else
	{
		C.R = 0;
		C.G = 0;
		C.B = 255;
	}

	Tex.DrawColoredText( 56, 14, Temp, Font'LEDFont', C );	
}

///////////////////////////////////////////////////////
state NormalFire
{
	ignores AnimEnd;

	function Projectile ProjectileFire(class<projectile> ProjClass, float ProjSpeed, bool bWarn)
	{
		local Vector Start, X,Y,Z;

		Owner.MakeNoise(Pawn(Owner).SoundDampening);
		GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
		Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		AdjustedAim = pawn(owner).AdjustAim(ProjSpeed, Start, AimError, True, bWarn);	
		Start = Start - Sin(Angle)*Y*4 + (Cos(Angle)*4 - 10.78)*Z;
		Angle += 1.8;
		return Spawn(ProjClass,,, Start,AdjustedAim);	
	}

	function Tick( float DeltaTime )
	{
		if (Owner==None) 
			GotoState('Pickup');
	}

	function BeginState()
	{
		Super.BeginState();
		Angle = 0;
		AmbientGlow = 200;
	}

	function EndState()
	{
		PlaySpinDown();
		AmbientSound = None;
		AmbientGlow = 0;	
		OldFlashCount = FlashCount;	
		Super.EndState();
	}

Begin:
	Sleep(0.18);
	Finish();
}

simulated function PlaySpinDown()
{
	if ( (Mesh != PickupViewMesh) && (Owner != None) )
	{
		PlayAnim('Spindown', 1.0, 0.0);
		Owner.PlayOwnedSound(DownSound, SLOT_None,1.0*Pawn(Owner).SoundDampening);
	}
}	

state ClientFiring
{
	simulated function Tick( float DeltaTime )
	{
		if ( (Pawn(Owner) != None) && (Pawn(Owner).bFire != 0) )
			AmbientSound = FireSound;
		else
			AmbientSound = None;
	}

	simulated function AnimEnd()
	{
		if ( (AmmoType != None) && (AmmoType.AmmoAmount <= 0) )
		{
			PlaySpinDown();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner) == None )
		{
			PlaySpinDown();
			GotoState('');
		}
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else if ( Pawn(Owner).bAltFire != 0 )
			Global.ClientAltFire(0);
		else
		{
			PlaySpinDown();
			GotoState('');
		}
	}
}

///////////////////////////////////////////////////////////////
state ClientAltFiring
{
	simulated function AnimEnd()
	{
		if ( AmmoType.AmmoAmount <= 0 )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner) == None )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( Pawn(Owner).bAltFire != 0 )
			PlayAnim('BoltLoop');
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else
		{
			PlayIdleAnim();
			GotoState('');
		}
	}
}

state AltFiring
{
	ignores AnimEnd;

	function Tick(float DeltaTime)
	{
		local Pawn P;

		P = Pawn(Owner);
		if ( P == None )
		{
			GotoState('Pickup');
			return;
		}
		if ( (P.bAltFire == 0) || (P.IsA('Bot')
					&& ((P.Enemy == None) || (Level.TimeSeconds - Bot(P).LastSeenTime > 5))) )
		{
			P.bAltFire = 0;
			Finish();
			return;
		}

		Count += Deltatime;
		if ( Count > 0.24 )
		{
			if ( Owner.IsA('PlayerPawn') )
				PlayerPawn(Owner).ClientInstantFlash( InstFlash,InstFog);
			if ( Affector != None )
				Affector.FireEffect();
			Count -= 0.24;
			if ( !AmmoType.UseAmmo(1) )
				Finish();
		}
	}
	
	function EndState()
	{
		AmbientGlow = 0;
		AmbientSound = None;
		if ( PlasmaBeam != None )
		{
			PlasmaBeam.Destroy();
			PlasmaBeam = None;
		}
		Super.EndState();
	}

Begin:
	AmbientGlow = 200;
	FinishAnim();	
	PlayAnim( 'boltloop');
}

state Idle
{
Begin:
	bPointing=False;
	if ( (AmmoType != None) && (AmmoType.AmmoAmount<=0) ) 
		Pawn(Owner).SwitchToBestWeapon();  //Goto Weapon that has Ammo
	if ( Pawn(Owner).bFire!=0 ) Fire(0.0);
	if ( Pawn(Owner).bAltFire!=0 ) AltFire(0.0);	

	Disable('AnimEnd');
	PlayIdleAnim();
}

///////////////////////////////////////////////////////////
simulated function PlayIdleAnim()
{
	if ( Mesh == PickupViewMesh )
		return;

	if ( (AnimSequence == 'BoltLoop') || (AnimSequence == 'BoltStart') )
		PlayAnim('BoltEnd');		
	else if ( AnimSequence != 'SpinDown' )
		TweenAnim('Idle', 0.1);
}

simulated function TweenDown()
{
	if ( IsAnimating() && (AnimSequence != '') && (GetAnimGroup(AnimSequence) == 'Select') )
		TweenAnim( AnimSequence, AnimFrame * 0.4 );
	else
		TweenAnim('Down', 0.26);
}

defaultproperties
{
     DownSound=Sound'Botpack.PulseDown'
     WeaponDescription="Classification: Plasma Rifle\n\nPrimary Fire: Medium sized, fast moving plasma balls are fired at a fast rate of fire.\n\nSecondary Fire: A bolt of green lightning is expelled for 100 meters, which will shock all opponents.\n\nTechniques: Firing and keeping the secondary fire's lightning on an opponent will melt them in seconds."
     InstFlash=-0.150000
     InstFog=(X=139.000000,Y=218.000000,Z=72.000000)
     AmmoName=Class'Botpack.PAmmo'
     PickupAmmoCount=60
     bRapidFire=True
     FireOffset=(X=15.000000,Y=-15.000000,Z=2.000000)
     ProjectileClass=Class'Botpack.PlasmaSphere'
     AltProjectileClass=Class'Botpack.StarterBolt'
     shakemag=135.000000
     shakevert=8.000000
     AIRating=0.700000
     RefireRate=0.950000
     AltRefireRate=0.990000
     FireSound=Sound'Botpack.PulseFire'
     AltFireSound=Sound'Botpack.PulseBolt'
     SelectSound=Sound'Botpack.PulsePickup'
     MessageNoAmmo=" has no Plasma."
     DeathMessage="%o ate %k's burning plasma death."
     NameColor=(R=128,B=128)
     FlashLength=0.020000
     AutoSwitchPriority=5
     InventoryGroup=5
     PickupMessage="You got a Pulse Gun"
     ItemName="Pulse Gun"
     PlayerViewOffset=(X=1.500000,Z=-2.000000)
     PlayerViewMesh=LodMesh'Botpack.PulseGunR'
     PickupViewMesh=LodMesh'Botpack.PulsePickup'
     ThirdPersonMesh=LodMesh'Botpack.PulseGun3rd'
     ThirdPersonScale=0.400000
     StatusIcon=Texture'Botpack.UsePulse'
     bMuzzleFlashParticles=True
     MuzzleFlashStyle=STY_Translucent
     MuzzleFlashMesh=LodMesh'Botpack.muzzPF3'
     MuzzleFlashScale=0.400000
     MuzzleFlashTexture=Texture'Botpack.MuzzyPulse'
     PickupSound=Sound'UnrealShare.WeaponPickup'
     Icon=Texture'Botpack.UsePulse'
     Mesh=LodMesh'Botpack.PulsePickup'
     bNoSmooth=False
     SoundRadius=64
     SoundVolume=255
     CollisionRadius=32.000000
}
