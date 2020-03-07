class BMF extends Effects;

simulated function Tick(float DeltaTime)
{
	local vector v, X, Y, Z;

	GetAxes(Owner.Rotation,X,Y,Z);
	v = Owner.Location;
	v -= 60*X;
	SetLocation(v);
}

defaultproperties
{
     Sprite=Texture'Botpack.JRFlare'
     Texture=Texture'Botpack.JRFlare'
     Skin=Texture'Botpack.JRFlare'
     DrawScale=0.500000
     bUnlit=True
     Mass=8.000000
}
