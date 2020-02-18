class InstaDeemer extends Mutator;

var ST_Mutator STM;

function bool AlwaysKeep(Actor Other)
{
    if (Other.IsA('ST_SuperShockRifleSingleShot'))
        return true;
    return super.AlwaysKeep(Other);
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if (Other.IsA('WarheadLauncher'))
	{
		ReplaceWith(Other, STM.Prefix$"ST_SuperShockRifleSingleShot");
		return false;
	}
    return true;
}