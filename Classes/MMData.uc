class MMData extends Mutator;

function bool AlwaysKeep(Actor Other)
{
	local bbPlayer bbP;
	local ST_Mutator STM;

	ForEach AllActors(class'bbPlayer', bbP)
	{
		bbP.MMSupport = True;
	}
	ForEach AllActors(class'ST_Mutator', STM)
	{
		STM.MMSupport = True;
	}
	return Super.AlwaysKeep(Other);
}