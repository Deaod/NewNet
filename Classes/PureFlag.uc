// ====================================================================
//  Class:  UTPureRC4d.PureFlag
//  Parent: Botpack.GreenFlag
//
//  <Enter a description here>
// ====================================================================

class PureFlag extends GreenFlag;

event PreBeginPlay()
{
// Dont call PreBP or risk being Destroyed
}

event PostBeginPlay()
{
// No need for flag animation
}

function SendHome()
{
}

function Drop(vector newVel)
{
}

auto state Home
{
ignores Touch, Timer, BeginState, EndState;
}

defaultproperties
{
     Skin=Texture'NewNetUnrealv0_9_17.NewNetLogo'
     bCollideWorld=False
     LightType=LT_None
}
