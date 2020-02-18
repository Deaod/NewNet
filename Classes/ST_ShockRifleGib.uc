class ST_ShockRifleGib extends ST_ShockRifle;

var bool EnableNoSpam;
var byte AntiSpamMethod;
var float FireRateScale;
var float MinSecBetweenBalls;
var int MaxShockBalls;
var float LastBallTime;

replication
{
	reliable if( Role==ROLE_Authority )
		EnableNoSpam, AntiSpamMethod, FireRateScale, MinSecBetweenBalls, MaxShockBalls;
}

function PostBeginPlay() 
{
	Super.PostBeginPlay();
	EnableNoSpam = class'NewNetCG'.Default.EnableNoSpam;
	AntiSpamMethod = class'NewNetCG'.Default.AntiSpamMethod;
	FireRateScale = class'NewNetCG'.Default.FireRateScale;
	MinSecBetweenBalls = class'NewNetCG'.Default.MinSecBetweenBalls;
	MaxShockBalls = class'NewNetCG'.Default.MaxShockBalls;
}

simulated function PlayFiring()
{
	if(EnableNoSpam)
		PlayAnim('Fire1',FireRateScale * FireAdjust,0.05);
	else
		PlayAnim('Fire1', 0.30 + 0.30 * FireAdjust,0.05);
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*4.0);
}

simulated function PlayAltFiring()
{
	PlayAnim('Fire2',0.4 + 0.4 * FireAdjust,0.05);
	PlayOwnedSound(AltFireSound, SLOT_None,Pawn(Owner).SoundDampening*4.0);
}

simulated function bool ClientAltFire (float Value)
{
	if ( (Role < ROLE_Authority) &&  !CanClientAltFire() )
		return False;
	return Super.ClientAltFire(Value);
}

simulated function bool CanClientAltFire ()
{
	local int Count;
	local ShockProj First, Proj;
	
	if (AntiSpamMethod == 1)
	{
		if ( !EnableNoSpam || (MaxShockBalls <= 0) )
			return True;
		
		foreach AllActors(Class'ShockProj',Proj)
		{
			if ( (Proj.Instigator == Pawn(Owner)) &&  !Proj.bOwnerNoSee )
				Count++;
		}
		return Count < MaxShockBalls;
	}
	else if (AntiSpamMethod == 2)
	{
		if ( !EnableNoSpam || (MaxShockBalls <= 0) )
			return True;

		foreach AllActors(Class'ShockProj',Proj)
		{
			if ( (Proj.Instigator == Pawn(Owner)) && !Proj.bOwnerNoSee )
			{
				Count++;
				if ( First == None )
					First = Proj;
			}
		}
		if ( Count >= MaxShockBalls )
			First.Destroy();
		return True;
	}
	else if (AntiSpamMethod == 3)
	{
		if ( !EnableNoSpam || (MinSecBetweenBalls <= 0.0) )
			return True;

		if ( Level.TimeSeconds - LastBallTime > MinSecBetweenBalls )
		{
			LastBallTime = Level.TimeSeconds;
				return True;
		}
		return False;
	}
}

function Projectile ProjectileFire (Class<Projectile> ProjClass, float projSpeed, bool bWarn)
{
	local int Count;
	local ShockProj Proj;
	local ShockProj first;
	
	if (AntiSpamMethod == 1)
	{
		if ( !EnableNoSpam || (MaxShockBalls <= 0) );

		foreach AllActors(Class'ShockProj',Proj)
		{
			if ( (Proj.Instigator == Pawn(Owner)) && Proj.bOwnerNoSee )
				Count++;
		}
		if ( Count >= MaxShockBalls )
			return None;
		return Super.ProjectileFire(ProjClass,projSpeed,bWarn);
	}
	else if (AntiSpamMethod == 2)
	{
		if ( !EnableNoSpam || (MaxShockBalls <= 0) );

		foreach AllActors(Class'ShockProj',Proj)
		{
			if ( (Proj.Instigator == Pawn(Owner)) && Proj.bOwnerNoSee )
			{
				Count++;
				if ( first == None )
					First = Proj;
			}
		}
		if ( Count >= MaxShockBalls )
			first.Destroy();
		return Super.ProjectileFire(ProjClass,projSpeed,bWarn);
	}
	else if (AntiSpamMethod == 3)
	{
		if (  !EnableNoSpam || (MinSecBetweenBalls <= 0.0) );

		if ( Level.TimeSeconds - LastBallTime > MinSecBetweenBalls )
		{
			LastBallTime = Level.TimeSeconds;
			return Super.ProjectileFire(ProjClass,projSpeed,bWarn);
		}
		return None;
	}
}

defaultproperties
{
     DeathMessage="%k gibbed %o with the %w."
     PickupMessage="You got the ComboGib Rifle."
     ItemName="ComboGib Rifle"
}