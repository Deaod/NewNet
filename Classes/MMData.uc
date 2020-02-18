class MMData extends Mutator;

function bool AlwaysKeep(Actor Other)
{
	local bbPlayer bbP;

	ForEach AllActors(class'bbPlayer', bbP)
	{
		bbP.MMSupport = True;
	}
	return Super.AlwaysKeep(Other);
}