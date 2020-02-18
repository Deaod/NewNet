//=============================================================================
// ST_FlakBox.
//=============================================================================
class ST_FlakBox extends ST_Ammos;

defaultproperties
{
	AmmoAmount=10
	MaxAmmo=50
	UsedInWeaponSlot(7)=1
	PickupMessage="You picked up 10 Flak Shells"
	PickupViewMesh=LodMesh'UnrealI.flakboxMesh'
	MaxDesireability=0.320000
	Icon=Texture'UnrealI.Icons.I_FlakAmmo'
	Mesh=LodMesh'UnrealI.flakboxMesh'
	CollisionRadius=16.000000
	CollisionHeight=11.000000
}