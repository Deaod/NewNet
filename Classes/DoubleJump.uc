class DoubleJump extends Mutator Config (UN);

var localized config int maxJumps;
var localized config float jumpHeight;

function Tick( float Delta )
{
	local UTPure zzUTP;
	ForEach AllActors(class'UTPure', zzUTP)
	{
		Log("*** NEWNET DOUBLEJUMP ACTIVATED ***");
		zzUTP.bDoubleJump = true;
		zzUTP.maxJumps = maxJumps;
		zzUTP.jumpHeight = jumpHeight;
		zzUTP.default.bDoubleJump = true;
		zzUTP.default.maxJumps = maxJumps;
		zzUTP.default.jumpHeight = jumpHeight;
		Disable('Tick');
	}
	SaveConfig();
}

defaultproperties
{
	maxJumps=2
	jumpHeight=1.2
}
