class ASSpawnNotify expands SpawnNotify;

var ASData Mutator;

auto state InitialDelay
{
Begin:
	Sleep(0.0);
	Mutator.bApplySNReplace = true;
}

event Actor SpawnNotification( actor A)
{
	if ( (Mutator.ReplaceThis == A) && (Mutator.ReplaceWith != none) )
	{
		A.Destroy();
		A = Mutator.ReplaceWith;
		Mutator.SetReplace(none,none);
	}
	return A;
}

defaultproperties
{
	ActorClass=class'ST_DummyWeapon'
	RemoteRole=ROLE_None
}