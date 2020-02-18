class ST_sgInstaGibLoader expands ST_WeaponClassLoader;

var class<TournamentWeapon> TW;

replication
{
	reliable if ( Role==ROLE_Authority )
		TW;
}


simulated event PostNetBeginPlay()
{
	local ST_sgInstaGibRifle SIGR;

	if ( TW != none )
	{
		Class'ST_sgInstaGibRifle'.default.OrgClass = TW;
		ForEach AllActors (class'ST_sgInstaGibRifle', SIGR)
		{
			SIGR.OrgClass = TW;
			SIGR.InitGraphics();
		}
	}
}
