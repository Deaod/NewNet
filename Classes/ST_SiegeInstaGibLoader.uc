class ST_SiegeInstaGibLoader expands ST_WeaponClassLoader;

var class<TournamentWeapon> TW;

replication
{
	reliable if ( Role==ROLE_Authority )
		TW;
}


simulated event PostNetBeginPlay()
{
	local ST_SiegeInstaGibRifle SIGR;

	if ( TW != none )
	{
		Class'ST_SiegeInstaGibRifle'.default.OrgClass = TW;
		ForEach AllActors (class'ST_SiegeInstaGibRifle', SIGR)
		{
			SIGR.OrgClass = TW;
			SIGR.InitGraphics();
		}
	}
}
