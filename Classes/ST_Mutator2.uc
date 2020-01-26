class ST_Mutator2 expands Mutator;

var string PreFix;
var zp_Manager Manager;

function GiveWeapon (Pawn PlayerPawn, string aClassName, bool SwitchTo)
{
	local Class<Weapon> WeaponClass;
	local Weapon NewWeapon;

//	Log("GiveWeapon1"@PlayerPawn.PlayerReplicationInfo.PlayerName@aClassName);

	WeaponClass=Class<Weapon>(DynamicLoadObject(aClassName,Class'Class'));
	if ( PlayerPawn.FindInventoryType(WeaponClass) != None )
	{
		return;
	}
	NewWeapon=Spawn(WeaponClass,PlayerPawn,,PlayerPawn.Location);
//	Log("GiveWeapon2"@NewWeapon.ItemName@WeaponClass);
	if ( NewWeapon != None )
	{
		NewWeapon.RespawnTime=0.00;
		NewWeapon.GiveTo(PlayerPawn);
		NewWeapon.bHeldItem=True;
		NewWeapon.GiveAmmo(PlayerPawn);
		NewWeapon.SetSwitchPriority(PlayerPawn);
		NewWeapon.AmbientGlow=0;
		if ( PlayerPawn.IsA('PlayerPawn') )
		{
			NewWeapon.SetHand(PlayerPawn(PlayerPawn).Handedness);
		}
		else
		{
			NewWeapon.GotoState('Idle');
		}
		if ( PlayerPawn.Weapon != None )
		{
			PlayerPawn.Weapon.GotoState('DownWeapon');
		}
		PlayerPawn.PendingWeapon=None;
		if ( SwitchTo )
		{
			NewWeapon.WeaponSet(PlayerPawn);
			PlayerPawn.Weapon=NewWeapon;
		}
	}
}

simulated function ModifyPlayer (Pawn Other)
{
	local int Id;

	Id=Other.PlayerReplicationInfo.PlayerID;
	if ( Manager.SettingsList[Id] != None )
	{
		Manager.SettingsList[Id].Destroy();
	}
	Manager.SettingsList[Id]=Spawn(Class'zp_Settings',Other);
	Manager.SettingsList[Id].PlayerID=Id;
	Super.ModifyPlayer(Other);
	if ( NextMutator != None )
	{
		NextMutator.ModifyPlayer(Other);
	}
}

event PreBeginPlay ()
{
	if ( Manager == None )
	{
		Manager=Spawn(Class'zp_Manager');
	}
	Class'zp_Server'.StaticSaveConfig();
	Super.PreBeginPlay();
}

function bool CheckReplacement (Actor Other, out byte bSuperRelevant)
{
	local zp_Server NewServer;

	if ( Other.IsA('ST_SniperRifle') )
	{
		if ( ST_SniperRifle(Other).zzS == None )
		{
			NewServer=Spawn(Class'zp_Server');
			NewServer.GotoState('zp_Gun');
			NewServer.OriginalName='SniperRifle';
			NewServer.zzW=TournamentWeapon(Other);
			ST_SniperRifle(Other).zzS=NewServer;
		}
	}
	if ( Other.IsA('SniperRifle') && !Other.IsA('ST_SniperRifle') )
	{
		ReplaceWith(Other,PreFix $ Class'UTPure'.Default.ThisVer $ ".ST_SniperRifle");
		return False;
	}
	return True;
}

defaultproperties
{
    PreFix="UltimateNewNet"
}
