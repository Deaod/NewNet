class ST_ApeCannon extends ST_WildcardsWeapons;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	WetTexture'APE_Flak'.Palette = Texture'APE_FlakPal'.Palette;
}

simulated event PostNetBeginPlay()
{
	super.PostNetBeginPlay();
	WetTexture'APE_Flak'.Palette = Texture'APE_FlakPal'.Palette;
}

simulated function RenderOverlays(Canvas Canvas)
{
	local bbPlayer bbP;
	
	if ( !bInitSkin )
	{
		MultiSkins[1] = WetTexture'APE_Flak2';
		WetTexture'APE_Flak1'.Palette = Texture'APE_FlakPal1'.Palette;
		WetTexture'APE_Flak2'.Palette = Texture'APE_FlakPal2'.Palette;
		bInitSkin = True;
	}

	Texture'FlakAmmoled'.NotifyActor = Self;
	Super.RenderOverlays(Canvas);
	Texture'FlakAmmoled'.NotifyActor = None;
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

function float SuggestAttackStyle()
{
	local bot B;

	B = Bot(Owner);
	if ( (B != None) && B.bNovice )
		return 0.2;
	return 0.4;
}

function float SuggestDefenseStyle()
{
	return -0.3;
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	local Color C;
	local string Temp;
	
	if ( AmmoType != None )
		Temp = String(AmmoType.AmmoAmount);

	while(Len(Temp) < 3) Temp = "0"$Temp;

	C.R = 255;
	C.G = 0;
	C.B = 0;

	Tex.DrawColoredText( 30, 10, Temp, Font'LEDFont2', C );	
}


function float RateSelf( out int bUseAltMode )
{
	local float EnemyDist, rating;
	local vector EnemyDir;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;
	if ( Pawn(Owner).Enemy == None )
	{
		bUseAltMode = 0;
		return AIRating;
	}
	EnemyDir = Pawn(Owner).Enemy.Location - Owner.Location;
	EnemyDist = VSize(EnemyDir);
	rating = FClamp(AIRating - (EnemyDist - 450) * 0.001, 0.2, AIRating);
	if ( Pawn(Owner).Enemy.IsA('StationaryPawn') )
	{
		bUseAltMode = 0;
		return AIRating + 0.3;
	}
	if ( EnemyDist > 900 )
	{
		bUseAltMode = 0;
		if ( EnemyDist > 2000 )
		{
			if ( EnemyDist > 3500 )
				return 0.2;
			return (AIRating - 0.3);
		}			
		if ( EnemyDir.Z < -0.5 * EnemyDist )
		{
			bUseAltMode = 1;
			return (AIRating - 0.3);
		}
	}
	else if ( (EnemyDist < 750) && (Pawn(Owner).Enemy.Weapon != None) && Pawn(Owner).Enemy.Weapon.bMeleeWeapon )
	{
		bUseAltMode = 0;
		return (AIRating + 0.3);
	}
	else if ( (EnemyDist < 340) || (EnemyDir.Z > 30) )
	{
		bUseAltMode = 0;
		return (AIRating + 0.2);
	}
	else
		bUseAltMode = int( FRand() < 0.65 );
	return rating;
}

simulated function bool ClientFire( float Value )
{
	local Vector Start, X,Y,Z;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local ST_UTApeChunk Proj;
	local int ProjIndex;

	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Value < 1)
			return false;
		
		yModInit();
		PawnOwner = Pawn(Owner);

		if ( AmmoType == None )
		{
			GiveAmmo(PawnOwner);
		}
		if (AmmoType.AmmoAmount > 0)
		{
			bbP.xxNN_Fire(bbP.zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, None, vect(0,0,0), vect(0,0,0), false, bbP.zzFRVI);
			
			Instigator = Pawn(Owner);
			bCanClientFire = true;
			bPointing=True;
			PawnOwner.PlayRecoil(FiringSpeed);

			GetAxes(GV,X,Y,Z);
			Start = Owner.Location + CDO;
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));	
			Start = Start + FireOffset.X * X + yMod * Y + FireOffset.Z * Z;	
			
			Proj = Spawn( class 'ST_UTApeChunk1',Owner, '', Start, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk2',Owner, '', Start - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk3',Owner, '', Start + 2 * Y + Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y + Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk4',Owner, '', Start - Y, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start - Y, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk1',Owner, '', Start + 2 * Y - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk2',Owner, '', Start, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk3',Owner, '', Start + Y - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + Y - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk4',Owner, '', Start + 2 * Y + Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y + Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk1',Owner, '', Start, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk2',Owner, '', Start - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk3',Owner, '', Start + 2 * Y + Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y + Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk4',Owner, '', Start - Y, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start - Y, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk1',Owner, '', Start + 2 * Y - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk2',Owner, '', Start, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk3',Owner, '', Start + Y - Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + Y - Z, Proj.Velocity, Proj.Acceleration, GV);
			
			Proj = Spawn( class 'ST_UTApeChunk4',Owner, '', Start + 2 * Y + Z, GV);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'UTChunk', Start + 2 * Y + Z, Proj.Velocity, Proj.Acceleration, GV);
			
			GoToState('NormalFire');
		}
	}
	
	return Super.ClientFire(Value);
}

simulated function bool ClientAltFire( float Value )
{
	local Vector Start, X,Y,Z;
	local Pawn PawnOwner;
	local ST_APE_FlakSlug Proj;
	local int ProjIndex;
	local bbPlayer bbP;

	bbP = bbPlayer(Owner);
	if (Role < ROLE_Authority && bbP != None && bNewNet)
	{
		if (bbP.ClientCannotShoot() || bbP.Weapon != Self || Value < 1)
			return false;
		
		yModInit();
		PawnOwner = Pawn(Owner);

		if ( AmmoType == None )
		{
			GiveAmmo(PawnOwner);
		}
		if (AmmoType.AmmoAmount > 0)
		{
			bbP.xxNN_AltFire(bbP.zzNN_ProjIndex, bbP.Location, bbP.Velocity, bbP.zzViewRotation, None, vect(0,0,0), vect(0,0,0), false, bbP.zzFRVI);
			
			Instigator = Pawn(Owner);
			PawnOwner.PlayRecoil(FiringSpeed);
			bPointing=True;
			bCanClientFire = true;
			
			PawnOwner = Pawn(Owner);
			GetAxes(GV,X,Y,Z);
			Start = PawnOwner.Location + CDO;
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));	
			Start = Start + FireOffset.X * X + yMod * Y + FireOffset.Z * Z; 
			AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, Start, AimError, True, bAltWarnTarget);
				
			Proj = Spawn(class'ST_APE_FlakSlug',Owner,, Start,AdjustedAim);
			ProjIndex = bbP.xxNN_AddProj(Proj);
			Proj.zzNN_ProjIndex = ProjIndex;
            bbP.xxClientDemoFix(Proj, Class'APE_FlakSlug', Start, Proj.Velocity, Proj.Acceleration, AdjustedAim);
		}
	}
	
	return Super.ClientAltFire(Value);
}

function Fire( float Value )
{
	local Vector Start, X,Y,Z;
	local Bot B;
	local ST_UTApeChunkInfo CI;
	local NN_UTApeChunkOwnerHidden COH;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local float OwnerPing;

	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;

	PawnOwner = Pawn(Owner);

	if ( AmmoType == None )
	{
		GiveAmmo(PawnOwner);
	}
	if (AmmoType.UseAmmo(1))
	{
		bCanClientFire = true;
		bPointing=True;
		
			
		B = Bot(PawnOwner);
		PawnOwner.MakeNoise(2.0 * PawnOwner.SoundDampening);
		if (bbP == None || !bNewNet)
		{
			Start = PawnOwner.Location + CalcDrawOffset();
			AdjustedAim = PawnOwner.AdjustAim(AltProjectileSpeed, Start, AimError, True, bWarnTarget);
			GetAxes(AdjustedAim,X,Y,Z);
			Start = Start + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z;	
		}
		else
		{
			AdjustedAim = bbP.zzNN_ViewRot;
			GetAxes(AdjustedAim,X,Y,Z);
			if (Mover(bbP.Base) == None)
				Start = bbP.zzNN_ClientLoc + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
			else
				Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 
		}
		if (bNewNet)
			Spawn(class'NN_WeaponLightOwnerHidden',Owner,'',Start+X*20,rot(0,0,0));		
		else
		{
			PawnOwner.PlayRecoil(FiringSpeed);
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));		
		}
		CI = Spawn(class'ST_UTApeChunkInfo', PawnOwner);
		OwnerPing = float(Owner.ConsoleCommand("GETPING"));

		if (bNewNet)
		{
			COH = Spawn( class 'NN_UTApeChunk1OwnerHidden',Owner, '', Start, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk2OwnerHidden',Owner, '', Start - Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk3OwnerHidden',Owner, '', Start + 2 * Y + Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk4OwnerHidden',Owner, '', Start - Y, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk1OwnerHidden',Owner, '', Start + 2 * Y - Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk2OwnerHidden',Owner, '', Start, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk3OwnerHidden',Owner, '', Start + Y - Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk4OwnerHidden',Owner, '', Start + 2 * Y + Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk1OwnerHidden',Owner, '', Start, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk2OwnerHidden',Owner, '', Start - Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk3OwnerHidden',Owner, '', Start + 2 * Y + Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk4OwnerHidden',Owner, '', Start - Y, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			if (bbP != None)
				COH.zzNN_ProjIndex = bbP.xxNN_AddProj(COH);
			CI.AddChunk(COH);
		}
		else
		{
			CI.AddChunk(Spawn( class 'ST_UTApeChunk1',Owner, '', Start, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk2',Owner, '', Start - Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk3',Owner, '', Start + 2 * Y + Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk4',Owner, '', Start - Y, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk1',Owner, '', Start + 2 * Y - Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk2',Owner, '', Start, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk3',Owner, '', Start + Y - Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk4',Owner, '', Start + 2 * Y + Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk1',Owner, '', Start, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk2',Owner, '', Start - Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk3',Owner, '', Start + 2 * Y + Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk4',Owner, '', Start - Y, AdjustedAim));
		}
		if ( (B == None) || !B.bNovice || ((B.Enemy != None) && (B.Enemy.Weapon != None) && B.Enemy.Weapon.bMeleeWeapon) )
		{
			if (bNewNet)
			{
			
			COH = Spawn( class 'NN_UTApeChunk1OwnerHidden',Owner, '', Start + 2 * Y - Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk2OwnerHidden',Owner, '', Start, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk3OwnerHidden',Owner, '', Start + Y - Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			CI.AddChunk(COH);
			
			COH = Spawn( class 'NN_UTApeChunk4OwnerHidden',Owner, '', Start + 2 * Y + Z, AdjustedAim);
			COH.NN_OwnerPing = OwnerPing;
			CI.AddChunk(COH);
			}
			else
			{
			CI.AddChunk(Spawn( class 'ST_UTApeChunk1',Owner, '', Start + 2 * Y - Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk2',Owner, '', Start, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk3',Owner, '', Start + Y - Z, AdjustedAim));
			CI.AddChunk(Spawn( class 'ST_UTApeChunk4',Owner, '', Start + 2 * Y + Z, AdjustedAim));
			}
		}
		ClientFire(Value);
		
		GoToState('NormalFire');
	}
}

function AltFire( float Value )
{
	local Vector Start, X,Y,Z;
	local ST_APE_FlakSlug Slug;
	local Pawn PawnOwner;
	local bbPlayer bbP;
	local NN_APE_FlakSlugOwnerHidden NNFS;
	
	bbP = bbPlayer(Owner);
	if (bbP != None && bNewNet && Value < 1)
		return;

	PawnOwner = Pawn(Owner);

	if ( AmmoType == None )
	{
		GiveAmmo(PawnOwner);
	}
	if (AmmoType.UseAmmo(1))
	{
		bPointing=True;
		bCanClientFire = true;
		PawnOwner.MakeNoise(PawnOwner.SoundDampening);

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
		AdjustedAim = PawnOwner.AdjustToss(AltProjectileSpeed, Start, AimError, True, bAltWarnTarget);	
		ClientAltFire(Value);
		if (bNewNet) {
			Spawn(class'NN_WeaponLightOwnerHidden',Owner,'',Start+X*20,rot(0,0,0));
			NNFS = Spawn(class'NN_APE_FlakSlugOwnerHidden',Owner,, Start,AdjustedAim);
			if (bbP != None)
				NNFS.zzNN_ProjIndex = bbP.xxNN_AddProj(NNFS);
		} else {
			PawnOwner.PlayRecoil(FiringSpeed);
			Spawn(class'WeaponLight',,'',Start+X*20,rot(0,0,0));
			Slug = Spawn(class'ST_APE_FlakSlug',,, Start,AdjustedAim);
		}
		GoToState('AltFiring');
	}
}

simulated function PlayFiring()
{
	PlayAnim( 'Fire', 0.9, 0.05);
	PlayOwnedSound(FireSound, SLOT_Misc,Pawn(Owner).SoundDampening*4.0);	
	bMuzzleFlash++;
}

simulated function PlayAltFiring()
{
	PlayOwnedSound(AltFireSound, SLOT_Misc,Pawn(Owner).SoundDampening*4.0);
	PlayAnim('AltFire', 1.3, 0.05);
	bMuzzleFlash++;
}

simulated function PlayReloading()
{
	PlayAnim('Loading',0.7, 0.05);
	Owner.PlayOwnedSound(CockingSound, SLOT_None,0.5*Pawn(Owner).SoundDampening);		
}

simulated function PlayFastReloading()
{
	PlayAnim('Loading',1.4, 0.05);
	Owner.PlayOwnedSound(CockingSound, SLOT_None,0.5*Pawn(Owner).SoundDampening);		
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
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (Ammotype.AmmoAmount <= 0) )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else
		{
			PlayFastReloading();
			GotoState('ClientReload');
		}
	}
}

state ClientAltFiring
{
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (Ammotype.AmmoAmount <= 0) )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bCanClientFire )
			GotoState('');
		else
		{
			PlayReloading();
			GotoState('ClientReload');
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
	function EndState()
	{
		Super.EndState();
		OldFlashCount = FlashCount;
	}
	function AnimEnd()
	{
		if ( (AnimSequence != 'Loading') && (AmmoType.AmmoAmount > 0) )
			PlayFastReloading();
		else
			Finish();
	}
		
Begin:
	FlashCount++;
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
	function EndState()
	{
		Super.EndState();
		OldFlashCount = FlashCount;
	}
	function AnimEnd()
	{
		if ( (AnimSequence != 'Loading') && (AmmoType.AmmoAmount > 0) )
			PlayReloading();
		else
			Finish();
	}
		
Begin:
	FlashCount++;
}

function SetSwitchPriority(pawn Other)
{
	Class'NN_WeaponFunctions'.static.SetSwitchPriority( Other, self, 'ApeCannon');
}

simulated function AnimEnd ()
{
	Class'NN_WeaponFunctions'.static.AnimEnd( self);
}

simulated function PlayIdleAnim()
{
}

simulated function PlayPostSelect()
{
	PlayAnim('Loading', 1.5 + float(Pawn(Owner).PlayerReplicationInfo.Ping) / 1000, 0.05);
	Owner.PlayOwnedSound(Misc2Sound, SLOT_None,1.3*Pawn(Owner).SoundDampening);	
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
	PickupMessage="You got the Ape Cannon."
	ItemName="APE Cannon"
	MultiSkins(0)=WetTexture'APE_Flak1'
	MultiSkins(1)=WetTexture'APE_Flak'
	DeathMessage="%o got CHIMP'd by %k."
	WeaponDescription="Classification: Heavy Shrapnel\n\nPrimary Fire: White hot chunks of scrap metal are sprayed forth, shotgun style.\n\nSecondary Fire: A grenade full of shrapnel is lobbed at the enemy.\n\nTechniques: The Flak Cannon is far more useful in close range combat situations."
	InstFlash=-0.400000
	InstFog=(X=650.000000,Y=450.000000,Z=190.000000)
	AmmoName=Class'ST_APEAmmo'
	PickupAmmoCount=65
	bWarnTarget=True
	bAltWarnTarget=True
	bSplashDamage=True
	FiringSpeed=1.000000
	FireOffset=(X=10.000000,Y=-11.000000,Z=-15.000000)
	ProjectileClass=Class'Botpack.UTChunk'
	AltProjectileClass=Class'Botpack.flakslug'
	aimerror=700.000000
	shakemag=350.000000
	shaketime=0.150000
	shakevert=8.500000
	AIRating=0.750000
	FireSound=Sound'UnrealShare.flak.shot1'
	AltFireSound=Sound'UnrealShare.flak.Explode1'
	CockingSound=Sound'UnrealI.flak.load1'
	SelectSound=Sound'UnrealI.flak.pdown'
	Misc2Sound=Sound'UnrealI.flak.Hidraul2'
	DeathMessage="%o was ripped to shreds by %k's %w."
	NameColor=(G=96,B=0)
	bDrawMuzzleFlash=True
	MuzzleScale=2.000000
	FlashY=0.160000
	FlashO=0.015000
	FlashC=0.100000
	FlashLength=0.020000
	FlashS=256
	MFTexture=Texture'Botpack.Skins.Flakmuz'
	AutoSwitchPriority=8
	InventoryGroup=8
	PlayerViewOffset=(X=1.500000,Y=-1.000000,Z=-1.650000)
	PlayerViewMesh=LodMesh'Botpack.flakm'
	PlayerViewScale=1.200000
	BobDamping=0.972000
	PickupViewMesh=LodMesh'Botpack.Flak2Pick'
	ThirdPersonMesh=LodMesh'Botpack.FlakHand'
	StatusIcon=Texture'Botpack.Icons.UseFlak'
	bMuzzleFlashParticles=True
	MuzzleFlashStyle=STY_Translucent
	MuzzleFlashMesh=LodMesh'Botpack.muzzFF3'
	MuzzleFlashScale=0.400000
	MuzzleFlashTexture=Texture'Botpack.Skins.MuzzyFlak'
	PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
	Icon=Texture'Botpack.Icons.UseFlak'
	Mesh=LodMesh'Botpack.Flak2Pick'
	CollisionRadius=32.000000
	CollisionHeight=23.000000
	LightBrightness=228
	LightHue=30
	LightSaturation=71
	LightRadius=14
}