class h4x_Bullets extends TournamentAmmo;

#exec TEXTURE IMPORT NAME=CustomBullets FILE=Images\CustomBullets.pcx GROUP=Rifle

defaultproperties
{
    AmmoAmount=50
    MaxAmmo=500
    UsedInWeaponSlot(9)=1
    PickupMessage="You got a box of h4x,v2 rifle rounds."
    ItemName="Box of h4x Rifle Rounds"
    PickupViewMesh=LodMesh'Botpack.BulletBoxM'
    MaxDesireability=0.24
    Icon=Texture'UnrealI.Icons.I_RIFLEAmmo'
    Skin=Texture'Botpack.Skins.BulletBoxT'
    Mesh=LodMesh'Botpack.BulletBoxM'
	MultiSkins(0)=Texture'Rifle.CustomBullets'
    MultiSkins(1)=Texture'Rifle.CustomBullets'
    MultiSkins(2)=Texture'Rifle.CustomBullets'
    MultiSkins(3)=Texture'Rifle.CustomBullets'
    MultiSkins(4)=Texture'Rifle.CustomBullets'
    MultiSkins(5)=Texture'Rifle.CustomBullets'
    MultiSkins(6)=Texture'Rifle.CustomBullets'
    MultiSkins(7)=Texture'Rifle.CustomBullets'
    CollisionRadius=15.00
    CollisionHeight=10.00
    bCollideActors=True
}
