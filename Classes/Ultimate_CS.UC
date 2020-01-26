Class Ultimate_CS extends Mutator;

var bool bInitialized;

simulated function PreBeginPlay()
{
	if(bInitialized)
		return;
	bInitialized = True;

	Super.PreBeginPlay();
}

function Mutate (string MutateString, PlayerPawn Sender)
{
	if ( Left(Caps(MutateString),10) == "ULTIMATENN" )
	{
		if ( Mid(Caps(MutateString),11,6) == "CLIENT" )
		{
			OpenSettingsWindow(Sender);
			Sender.ClientMessage("Opening Client Settings!");
		}
	}

	Super.Mutate(MutateString,Sender);

	if(NextMutator != None)
		NextMutator.Mutate(MutateString,Sender);
}

function OpenSettingsWindow(PlayerPawn Sender)
{
	local IndiaSettingsWRI MVMRI;
	local IndiaSettingsWRI MVMRA;

	foreach AllActors(Class'IndiaSettingsWRI',MVMRA)
	{
		if ( Sender == MVMRA.Owner )
		{
			MVMRA.CloseWindow();
			MVMRA.Destroy();
		}
	}

	MVMRI=Spawn(Class'IndiaSettingsWRI',Sender);
	if(MVMRI == None)
	{
		MVMRI.CloseWindow();
		MVMRI.Destroy();
	}
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=True
    bNetTemporary=False
}