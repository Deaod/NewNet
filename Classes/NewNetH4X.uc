class NewNetH4X expands NewNetArena;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	class'UTPure'.default.zzbH4x = true;
}

defaultproperties
{
	 DefaultWeapon=class'h4x_Rifle'
     WeaponNames(0)=h4x_Xloc
     AmmoNames(0)=h4x_Bullets
}