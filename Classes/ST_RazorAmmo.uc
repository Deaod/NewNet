//=============================================================================
// ST_RazorAmmo.
//=============================================================================
class ST_RazorAmmo extends ST_Ammos;

var bool bOpened;

auto state Pickup
{
	function Touch( Actor Other )
	{
		local Vector Dist2D;

		if ( bOpened )
		 Super.Touch(Other);
		if ( (Pawn(Other) == None) || !Pawn(Other).bIsPlayer )
			return;
		Dist2D = Other.Location - Location;
		Dist2D.Z = 0;
		if ( VSize(Dist2D) <= 40.0 )
			Super.Touch(Other);
		else 
		{
			SetCollisionSize(20.0, CollisionHeight);
			SetLocation(Location);
			bOpened = true;
			PlayAnim('Open', 0.05);
		}
	}

	function Landed(vector HitNormal)
	{
		Super.Landed(HitNormal);
		if ( !bOpened )
		{
			bCollideWorld = false;
			SetCollisionSize(170,CollisionHeight);
		}
	}
}

defaultproperties
{
	AmmoAmount=25
	MaxAmmo=75
	UsedInWeaponSlot(5)=1
	PickupMessage="You picked up Razor Blades"
	PickupViewMesh=LodMesh'UnrealI.RazorAmmoMesh'
	MaxDesireability=0.220000
	Icon=Texture'UnrealI.Icons.I_RazorAmmo'
	Physics=PHYS_Falling
	Mesh=LodMesh'UnrealI.RazorAmmoMesh'
	CollisionRadius=20.000000
	CollisionHeight=10.000000
}