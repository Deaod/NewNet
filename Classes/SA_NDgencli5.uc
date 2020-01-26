/************************************************************
 * SA_NDgencli                        Server Actor
 ************************************************************/
class SA_NDgencli5 expands Info;

function BeginPlay()
{
	local ND_Mut xMAIN;
	local Mutator Last_Mutator;
	local int i;

	super.PostBeginPlay();


	foreach AllActors(class 'ND_Mut',xMAIN)
	{
		return;
	}
	xMAIN = Level.Spawn(class'ND_Mut');
	Last_Mutator = Level.Game.BaseMutator;
	while( Last_Mutator.NextMutator != none )
	{
		Last_Mutator = Last_Mutator.NextMutator;
	}
	if ( Last_Mutator != none )
	{
		Last_Mutator.NextMutator = xMAIN;
	}
	else
	{
		Level.Game.BaseMutator = xMAIN;
	}
}

defaultproperties
{
}
