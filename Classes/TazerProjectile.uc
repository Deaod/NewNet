//=============================================================================
// TazerProjectile.
//=============================================================================
class TazerProjectile extends ShockProj;

function SuperExplosion()
{
	HurtRadius(Damage*3, 250, MyDamageType, MomentumTransfer*2, Location );
	
	Spawn(Class'RingExplosion2',,'',Location, Instigator.ViewRotation);
	PlaySound(ExploSound,,20.0,,2000,0.6);	
	
	Destroy(); 
}

function Explode(vector HitLocation,vector HitNormal)
{
	PlaySound(ImpactSound, SLOT_Misc, 0.5,,, 0.5+FRand());
	HurtRadius(Damage, 70, MyDamageType, MomentumTransfer, Location );
	if (Damage > 60)
		Spawn(class'RingExplosion3',,, HitLocation+HitNormal*8,rotator(HitNormal));
	else
		Spawn(class'RingExplosion5',,, HitLocation+HitNormal*8,rotator(Velocity));		

	Destroy();
}

defaultproperties
{
	Mesh=LodMesh'UnrealShare.TazerProja'
	LightBrightness=101
	DrawType=DT_Mesh
	DrawScale=1.0
}