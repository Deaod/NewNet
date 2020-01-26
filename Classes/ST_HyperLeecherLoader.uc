class ST_HyperLeecherLoader expands ST_WeaponClassLoader;

var class<TournamentWeapon> TW;

replication
{
	reliable if ( Role==ROLE_Authority )
		TW;
}


simulated event PostNetBeginPlay()
{
	local ST_HyperLeecher HL;

	if ( TW != none )
	{
		Class'ST_HyperLeecher'.default.OrgClass = TW;
		ForEach AllActors (class'ST_HyperLeecher', HL)
		{
			HL.OrgClass = TW;
			HL.InitGraphics();
		}
	}
}
