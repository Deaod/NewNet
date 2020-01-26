class NewNetCG expands NewNetArena;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if ( Other.IsA('TournamentHealth') || Other.IsA('UT_Shieldbelt')
		|| Other.IsA('Armor2') || Other.IsA('ThighPads')
		|| Other.IsA('UT_Invisibility') || Other.IsA('UDamage') )
		return false;

	return Super.CheckReplacement( Other, bSuperRelevant );
	
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	class'UTPure'.default.zzbGrapple = true;
}

defaultproperties
{
	 DefaultWeapon=class'ST_ShockRifleGib'
     WeaponNames(0)=Grappling
     WeaponPackages(0)=NDgrap49c
     AmmoNames(0)=SuperShockCore
}
