class NN_ShockProjBlueOwnerHidden extends ST_ShockProjBlue;

var bool bAlreadyHidden;
var float NN_OwnerPing, NN_EndAccelTime;

replication
{
	reliable if ( Role == ROLE_Authority )
		NN_OwnerPing;
}

simulated function Tick(float DeltaTime)
{
	local bbPlayer bbP;

	Texture = Texture'B_a00';
	LightBrightness=255;
	LightHue=170;
	LightSaturation=0;
	LightRadius=6;
	LightEffect=LE_Cylinder;

	if (Level.NetMode == NM_Client) {
	
		if (!bAlreadyHidden && Owner.IsA('bbPlayer') && bbPlayer(Owner).Player != None) {
			LightType = LT_None;
			SetCollisionSize(0, 0);
			bAlreadyHidden = True;
			//Texture = None;
			Destroy();
			return;
		}
		
		if (NN_OwnerPing > 0)
		{
			if (NN_EndAccelTime == 0)
			{
				Velocity *= 2;
				NN_EndAccelTime = Level.TimeSeconds + NN_OwnerPing * Level.TimeDilation / 2500;
				//for (P = Level.PawnList; P != None; P = P.NextPawn)
				ForEach AllActors(class'bbPlayer', bbP)
				{
					if ( Viewport(bbP.Player) != None )
					///if (PlayerPawn(P) != None && Viewport(PlayerPawn(P).Player) != None)
						NN_EndAccelTime += bbP.PlayerReplicationInfo.Ping * Level.TimeDilation / 2500;
				}
			}
			else if (Level.TimeSeconds > NN_EndAccelTime)
			{
				Velocity = Velocity / 2;
				NN_OwnerPing = 0;
			}
		}
		
	}
	
}

simulated function Explode(vector HitLocation,vector HitNormal)
{
	local bbPlayer bbP;

	bbP = bbPlayer(Instigator);
	
	if (bDeleteMe)
		return;
	if (STM != None)
		STM.PlayerHit(Instigator, 6, False);	// 6 = Shock Ball
	//Log(Class.Name$" (Explode) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
	if (bbPlayer(Owner) != None && !bbPlayer(Owner).bNewNet)
		HurtRadius(Damage, 70, MyDamageType, MomentumTransfer, Location );
	if (STM != None)
		STM.PlayerClear();
	
	DoExplode(Damage, HitLocation, HitNormal);
	PlayOwnedSound(ImpactSound, SLOT_Misc, 0.5,,, 0.5+FRand());
	
	if (bbP != None && Level.NetMode != NM_Client)
	{
		bbP.xxNN_ClientProjExplode(zzNN_ProjIndex, HitLocation, HitNormal);
	}
	
	Destroy();
}

simulated function DoExplode(int Dmg, vector HitLocation,vector HitNormal)
{
	local PlayerPawn P;
	local Actor CR;

	if (RemoteRole < ROLE_Authority) {
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
		{
			if (P != Instigator) {
				if (Dmg > 60)
					CR = P.Spawn(class'UT_BlueRingExplosion2',P,, HitLocation+HitNormal*8,rotator(HitNormal));
				else
					CR = P.Spawn(class'UT_BlueRingExplosion2',P,, HitLocation+HitNormal*8,rotator(Velocity));
				CR.bOnlyOwnerSee = True;
			}
		}
	}
}

function SuperExplosion()	// aka, combo.
{	
	if (STM != None)
	{
		STM.PlayerUnfire(Instigator, 6);			// 6 = Shock Ball -> remove this
		STM.PlayerFire(Instigator, 7);				// 7 = Shock Combo -> Instigator gets +1 Combo
		STM.PlayerHit(Instigator, 7, Instigator.Location == StartLocation);	// 7 = Shock Combo, bSpecial if Standstill.
	}
	//Log(Class.Name$" (SuperExplosion) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
	if (bbPlayer(Owner) != None && !bbPlayer(Owner).bNewNet)
		HurtRadius(Damage*3, 250, MyDamageType, MomentumTransfer*2, Location );
	if (STM != None)
		STM.PlayerClear();
	
	DoSuperExplosion();
	PlayOwnedSound(ExploSound,,20.0,,2000,0.6);
	//Spawn(Class'ut_ComboRing',,'',Location, Instigator.ViewRotation);
	//PlaySound(ExploSound,,20.0,,2000,0.6);
	if (bbPlayer(Instigator) != None)
		bbPlayer(Instigator).xxNN_ClientProjExplode(-1*(zzNN_ProjIndex + 1));
	
	Destroy(); 
}

simulated function DoSuperExplosion()
{
	local PlayerPawn P;
	local Actor CR;

	if (RemoteRole < ROLE_Authority)
	{
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
		{
			if (P != Owner)
			{
				CR = P.Spawn(Class'Blue_ComboRing',P,'',Location, Pawn(Owner).ViewRotation);
				CR.bOnlyOwnerSee = True;
			}
		}
	}
}

function SuperDuperExplosion()	// aka, combo.
{	
	if (STM != None)
	{
		STM.PlayerUnfire(Instigator, 6);			// 6 = Shock Ball -> remove this
		STM.PlayerFire(Instigator, 7);				// 7 = Shock Combo -> Instigator gets +1 Combo
		STM.PlayerHit(Instigator, 7, Instigator.Location == StartLocation);	// 7 = Shock Combo, bSpecial if Standstill.
	}
	//Log(Class.Name$" (SuperExplosion) called by"@bbPlayer(Owner).PlayerReplicationInfo.PlayerName);
	if (bbPlayer(Owner) != None && !bbPlayer(Owner).bNewNet)
		HurtRadius(Damage*9, 750, MyDamageType, MomentumTransfer*6, Location );
	if (STM != None)
		STM.PlayerClear();
	
	DoSuperDuperExplosion();
	PlayOwnedSound(ExploSound,,20.0,,2000,0.6);
	//Spawn(Class'UT_SuperComboRing',,'',Location, Instigator.ViewRotation);
	//PlaySound(ExploSound,,20.0,,2000,0.6);
	if (bbPlayer(Instigator) != None)
		bbPlayer(Instigator).xxNN_ClientProjExplode(-1*(zzNN_ProjIndex + 1));
	
	Destroy(); 
}

simulated function DoSuperDuperExplosion()
{
	local PlayerPawn P;
	local Actor CR;

	if (RemoteRole < ROLE_Authority) {
		//for (P = Level.PawnList; P != None; P = P.NextPawn)
		ForEach AllActors(class'PlayerPawn', P)
		{
			if (P != Owner)
			{
				CR = P.Spawn(Class'Blue_SuperComboRing',P,'',Location, Pawn(Owner).ViewRotation);
				CR.bOnlyOwnerSee = True;
			}
		}
	}
}

defaultproperties
{
    bOwnerNoSee=True
    Texture=Texture'B_a00'
	LightBrightness=255
   	LightHue=170
    LightSaturation=0
    LightRadius=6
    LightEffect=LE_Cylinder
}
