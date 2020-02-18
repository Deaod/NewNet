//=============================================================================
// ST_BigBioGel.
//=============================================================================
class ST_BigBioGel extends ST_BioGel;

function DropDrip()
{
	local BioGel Gel;

	PlaySound(SpawnSound);
	Gel = Spawn(class'BioDrop', Pawn(Owner),,Location-Vect(0,0,1)*10);
	Gel.DrawScale = DrawScale * 0.5;	
}

function vector GetVRV()
{
	local bbPlayer bbP;
	bbP = bbPlayer(Owner);
	if (bbP == None)
		return vect(0,0,0);
	
	bbP.zzVRVI++;
	if (bbP.zzVRVI == bbP.VRVI_length)
		bbP.zzVRVI = 0;
	return bbP.GetVRV(bbP.zzVRVI)/10000;
}

simulated function PreBeginPlay()
{
	if (bbPlayer(Owner) != None)
		bbPlayer(Owner).zzNN_VRVI = bbPlayer(Owner).zzVRVI;
	
	Super.PreBeginPlay();
}

auto state Flying
{
	simulated function HitWall( vector HitNormal, actor Wall )
	{
		SetPhysics(PHYS_None);		
		MakeNoise(0.6);	
		bOnGround = True;
		PlaySound(ImpactSound);	
		SetWall(HitNormal, Wall);
		DrawScale=DrawScale*1.4;
		GoToState('OnSurface');
	}

	function BeginState()
	{	
		local Vector viewDir;
		
		viewDir = vector(Rotation);	
		Velocity = (Speed + (viewDir dot Instigator.Velocity)) * viewDir;
		Velocity.z += 120;
		RandSpin(100000);
		LoopAnim('Flying',0.4);
		bOnGround=False;
		PlaySound(SpawnSound);
		if( Region.zone.bWaterZone )
			Velocity=Velocity*0.7;
	}
}

state OnSurface
{
	function BeginState()
	{
		wallTime = DrawScale*5+2;
		
		if ( Mover(Base) != None )
		{
			BaseOffset = VSize(Location - Base.Location);
			SetTimer(0.2, true);
		}
		else 
			SetTimer(wallTime, false);
	}
}

defaultproperties
{
    speed=700.00
    Damage=75.00
    MomentumTransfer=30000
    RemoteRole=1
    LifeSpan=25.00
    CollisionRadius=3.00
    CollisionHeight=4.00
}