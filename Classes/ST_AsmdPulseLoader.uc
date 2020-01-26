class ST_AsmdPulseLoader expands ST_WeaponClassLoader;

var class<TournamentWeapon> TW;

replication
{
	reliable if ( Role==ROLE_Authority )
		TW;
}


simulated event PostNetBeginPlay()
{
	local ST_AsmdPulseRifle APR;

	if ( TW != none )
	{
		Class'ST_AsmdPulseRifle'.default.OrgClass = TW;
		ForEach AllActors (class'ST_AsmdPulseRifle', APR)
		{
			APR.OrgClass = TW;
			APR.InitGraphics();
		}
	}
}
