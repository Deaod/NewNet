// ===============================================================
// UTPureStats7A.ST_StarterBolt: put your comment here

// Created by UClasses - (C) 2000-2001 by meltdown@thirdtower.com
// ===============================================================

class ST_StarterBolt extends ST_PBolt;

var float OldError, NewError, StartError, AimError; //used for bot aiming
var rotator AimRotation;
var float AnimTime;

// Count "shots" using this.
var float ShootAccum;

replication
{
	// Things the server should send to the client.
	unreliable if( Role==ROLE_Authority )
		AimError, NewError, AimRotation;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Owner != None)
		Instigator = Pawn(Owner);
	if ( Instigator == None )
		return;
	if ( Instigator.IsA('Bot') && Bot(Instigator).bNovice )
		aimerror = 2200 + (3 - instigator.skill) * 300;
	else
		aimerror = 1000 + (3 - instigator.skill) * 400;

	if ( FRand() < 0.5 )
		aimerror *= -1;

	if (ROLE == ROLE_Authority)
	{
		ForEach AllActors(Class'ST_Mutator', STM) // Find masta mutato
			if (STM != None)
				break;
	}
}

simulated function Tick(float DeltaTime)
{
	local vector X,Y,Z, AimSpot, DrawOffset, AimStart;
	local int YawErr;
	local float dAdjust;
	local Bot MyBot;
	local bbPlayer bbP;

	if (ROLE == ROLE_Authority)
	{
		ShootAccum -= DeltaTime;
		while (ShootAccum <= 0.0)
		{	// Handle stats this way.
			ShootAccum += 0.05;		// TR 20 = 0.05s
			if (STM != None)
				STM.PlayerFire(Instigator, 10);
		}
	}

	AnimTime += DeltaTime;
	if ( AnimTime > 0.05 )
	{
		AnimTime -= 0.05;
		SpriteFrame++;
		if ( SpriteFrame == ArrayCount(SpriteAnim) )
			SpriteFrame = 0;
		Skin = SpriteAnim[SpriteFrame];
	}
	
	// orient with respect to instigator
	if ( Instigator != None )
	{
		if (Instigator.Weapon == None)
			return;
		if ( (Level.NetMode == NM_Client) && (!Instigator.IsA('PlayerPawn') || (PlayerPawn(Instigator).Player == None)) )
		{
			SetRotation(AimRotation); 
			Instigator.ViewRotation = AimRotation;
			DrawOffset = ((0.01 * class'PulseGun'.Default.PlayerViewOffset) >> Rotation);
			DrawOffset += (Instigator.EyeHeight * vect(0,0,1));
		}
		else 
		{
			MyBot = Bot(instigator);
			if ( MyBot != None  )
			{
				if ( Instigator.Target == None )
					Instigator.Target = Instigator.Enemy;
				if ( Instigator.Target == Instigator.Enemy )
				{
					if (MyBot.bNovice )
						dAdjust = DeltaTime * (4 + instigator.Skill) * 0.075;
					else
						dAdjust = DeltaTime * (4 + instigator.Skill) * 0.12;
					if ( OldError > NewError )
						OldError = FMax(OldError - dAdjust, NewError);
					else
						OldError = FMin(OldError + dAdjust, NewError);

					if ( OldError == NewError )
						NewError = FRand() - 0.5;
					if ( StartError > 0 )
						StartError -= DeltaTime;
					else if ( MyBot.bNovice && (Level.TimeSeconds - MyBot.LastPainTime < 0.2) )
						StartError = MyBot.LastPainTime;
					else
						StartError = 0;
					AimSpot = 1.25 * Instigator.Target.Velocity + 0.75 * Instigator.Velocity;
					if ( Abs(AimSpot.Z) < 120 )
						AimSpot.Z *= 0.25;
					else
						AimSpot.Z *= 0.5;
					if ( Instigator.Target.Physics == PHYS_Falling )
						AimSpot = Instigator.Target.Location - 0.0007 * AimError * OldError * AimSpot;
					else
						AimSpot = Instigator.Target.Location - 0.0005 * AimError * OldError * AimSpot;
					if ( (Instigator.Physics == PHYS_Falling) && (Instigator.Velocity.Z > 0) )
						AimSpot = AimSpot - 0.0003 * AimError * OldError * AimSpot;

					AimStart = Instigator.Location + FireOffset.X * X + FireOffset.Y * Y + (1.2 * FireOffset.Z - 2) * Z; 
					if ( FastTrace(AimSpot - vect(0,0,10), AimStart) )
						AimSpot	= AimSpot - vect(0,0,10);
					GetAxes(Instigator.Rotation,X,Y,Z);
					AimRotation = Rotator(AimSpot - AimStart);
					AimRotation.Yaw = AimRotation.Yaw + (OldError + StartError) * 0.75 * aimerror;
					YawErr = (AimRotation.Yaw - (Instigator.Rotation.Yaw & 65535)) & 65535;
					if ( (YawErr > 3000) && (YawErr < 62535) )
					{
						if ( YawErr < 32768 )
							AimRotation.Yaw = Instigator.Rotation.Yaw + 3000;
						else
							AimRotation.Yaw = Instigator.Rotation.Yaw - 3000;
					}
				}
				else if ( Instigator.Target != None )
					AimRotation = Rotator(Instigator.Target.Location - Instigator.Location);
				else
					AimRotation = Instigator.ViewRotation;
				Instigator.ViewRotation = AimRotation;
				SetRotation(AimRotation);
			}
			else
			{
				AimRotation = Instigator.ViewRotation;
				SetRotation(AimRotation);
			}
			Drawoffset = Instigator.Weapon.CalcDrawOffset();
		}
		GetAxes(Instigator.ViewRotation,X,Y,Z);

		if ( bCenter )
		{
			FireOffset.Z = Default.FireOffset.Z * 1.5;
			FireOffset.Y = 0;
		}
		else 
		{
			FireOffset.Z = Default.FireOffset.Z;
			if ( bRight )
				FireOffset.Y = Default.FireOffset.Y;
			else
				FireOffset.Y = -1 * Default.FireOffset.Y;
		}
		bbP = bbPlayer(Instigator);
        SetLocation(Instigator.Location + DrawOffset + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z);
		if (bbP != none)
			bbP.xxClientDemoBolt(self, Location, Rotation, X, DeltaTime);
	}
	else
		GetAxes(Rotation,X,Y,Z);

	CheckBeam(X, DeltaTime);
}

defaultproperties
{
     StartError=0.500000
     SpriteAnim(0)=Texture'Botpack.sbolt0'
     SpriteAnim(1)=Texture'Botpack.sbolt1'
     SpriteAnim(2)=Texture'Botpack.sbolt2'
     SpriteAnim(3)=Texture'Botpack.sbolt3'
     SpriteAnim(4)=Texture'Botpack.sbolt4'
     RemoteRole=ROLE_SimulatedProxy
     LightType=LT_Steady
     LightEffect=LE_NonIncidence
     LightBrightness=255
     LightHue=83
     LightSaturation=50
     LightRadius=5
}
