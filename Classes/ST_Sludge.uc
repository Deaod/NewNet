//=============================================================================
// ST_Sludge.
//=============================================================================
class ST_Sludge extends ST_Ammos;

auto state Init
{
Begin:
	BecomePickup();
	LoopAnim('Swirl',0.3);
	GoToState('Pickup');
}

defaultproperties
{
	AmmoAmount=25
	MaxAmmo=100
	UsedInWeaponSlot(2)=1
	PickupMessage="You picked up 25 Kilos of Tarydium Sludge"
	PickupViewMesh=LodMesh'UnrealI.sludgemesh'
	MaxDesireability=0.220000
	Icon=Texture'UnrealI.I_SludgeAmmo'
	Mesh=LodMesh'UnrealI.sludgemesh'
	CollisionRadius=22.000000
	CollisionHeight=15.000000
}