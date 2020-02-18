//=============================================================================
// RB.
//=============================================================================
class RB extends RazorBlade;

auto state Flying
{
	simulated function HitWall (vector HitNormal, actor Wall)
	{
		Super(Razor2).Hitwall(HitNormal, Wall);
	}
}